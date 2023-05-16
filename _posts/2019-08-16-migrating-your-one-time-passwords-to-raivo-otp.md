---
layout: post
title: Migrating your one-time passwords to Raivo OTP
subtitle: Migrating all of your one-time passwords to Raivo OTP in just a few minutes.
description: Many one-time password (OTP) apps do not allow you to migrate your OTPs to other apps. This blog post contains fancy tricks that enable you to export these OTPs anyway.
keywords: raivo, migrating, export, otp, counter, one, time, password, client, native, app, swift, secure, fast, lightweight, token, two, second, factor
author: Tijme Gommers
include_in_header: false
include_in_footer: false
show_in_post_list: false
robots: index, follow
---

If you're annoyed by the user experience of OTP apps such as Authy or the Google Authenticator (just like me), then you may find this useful! In my spare time, I developed [Raivo OTP](https://apps.apple.com/app/raivo-otp/id1459042137?platform=iphone){:target="_blank"}{:rel="noopener noreferrer"}. Raivo OTP is a non-commercial OTP app for iOS, that contains many must-have features like automagic data synchronization, search capabilities and viewing the current *and* previous token. Most importantly, Raivo OTP is native (developed in Swift 5) and is therefore very fast!

<div class="row">
    <div class="col-md-4 text-center">
        {% 
            include lightbox.html 
            image="/img/migrating-your-one-time-passwords-to-raivo-otp/preview_left.png" 
            title="Raivo OTP home screen (list)"
            album="previews"
            width="261.33"
            height="502"
        %}
    </div>
    <div class="col-md-4 text-center hidden-xs hidden-sm">
        {% 
            include lightbox.html 
            image="/img/migrating-your-one-time-passwords-to-raivo-otp/preview_middle.png" 
            title="Creating an OTP in Raivo OTP"
            album="previews"
            width="261.33"
            height="502"
        %}
    </div>
    <div class="col-md-4 text-center hidden-xs hidden-sm">
        {% 
            include lightbox.html 
            image="/img/migrating-your-one-time-passwords-to-raivo-otp/preview_right.png" 
            title="The settings screen of Raivo OTP"
            album="previews"
            width="261.33"
            height="502"
        %}
    </div>
</div>
<br/>

One of the features that is lacking in most of the OTP apps (except Raivo OTP 👌) is the possibility to export OTPs. Therefore, migrating OTPs isn't easy. That OTP apps are lacking export functionalities is probably due to the fact that vendors don't want you to leave their product or service. However, during the development of Raivo OTP I found various fancy workarounds that enable you to export OTPs from popular OTP apps. I want to share these to improve the experience of migrating to Raivo OTP.

The following blog posts are guides that walk you through the process of exporting your OTPs and importing them into Raivo OTP.

* [Migrating from Authy to Raivo OTP](/blog/migrating-your-one-time-passwords-from-authy-to-raivo-otp/)
* Migrating from Google Authenticator to Raivo OTP (**coming soon**)