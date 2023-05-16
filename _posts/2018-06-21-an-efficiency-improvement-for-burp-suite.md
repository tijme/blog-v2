---
layout: post
title: An efficiency improvement for Burp Suite
subtitle: An extension that automatically marks similar requests as 'out-of-scope'.
description: Similar Request Excluder is a Burp Suite extension that detects similar code flows (CFG-paths) in requests and automatically moves them 'out-of-scope' so they won't be processed by active scans.
keywords: similar, request, excluder, burp, suite, portswigger, extension, efficiency, speed, fast, slow, remove, duplicate, urls
author: Tijme Gommers
include_in_header: false
include_in_footer: false
show_in_post_list: false
robots: index, follow
---

In a world where desktop applications are shifting more and more towards web applications, web application security is a rising concern. Manually testing these applications for security vulnerabilities, such as cross-site scripting and SQL injection, is infeasible; as security specialists are scarce. Automated Web Application Vulnerability Scanners, hereinafter referred to as scanners, are tools that scan web applications in an automated way, normally from the outside, to look for these security vulnerabilities.

The advantage of scanners is that they can replace parts of the manual security vulnerability scanning. However, a major disadvantage is that they tend to be inefficient depending on the type of web application that is being scanned. Reviews about scanners by Northwave, a security company based in Nieuwegein, the Netherlands, and the online security community confirm that not all scanners are efficient. They state that in some cases scanners may take up to 36 hours to complete. However, it is not clear why they are inefficient or how the efficiency can be improved. It is important to know that efficiency is essentially just the speed of the scanners. Effectiveness is how many vulnerabilities the scanners find.

<hr>

*"During my graduation internship at Northwave I studied how to improve the efficiency of scanners while maintaining effectiveness. This blog post is a small summary of my graudation thesis. You can read the full thesis [here](https://raw.finnwea.com/similar-request-excluder/){:target="_blank"}{:rel="noopener noreferrer"}."*

<hr>

The goal of the study was to create a generic open-source solution that improves the efficiency of scanners while keeping the effectiveness of the scanners at the same level. Three scanners were used to test possible solutions, namely; Burp Suite, Acunetix & NYAWC. These scanners were used to test possible solutions since they all provide functionalities to modify their own behaviour. Testing more than three scanners would simply take too much time.

Research on four key concepts, originated from the intersection of all of the key concepts of the three scanners, indicate that "target scope reduction" can improve the efficiency the most while maintaining effectiveness. Therefore, "target scope reduction" is chosen as the most promising key concept. Although it is easy to manually reduce the target scope, it is more complicated to automate that process since the effectiveness needs to be maintained and automation does not know how to reduce the scope effectively.

Reducing the target scope can be done by ignoring similar HTTP responses. If two HTTP responses have the same HTML structure it is likely that they have the same code flow and therefore the same security vulnerabilities. By measuring the similarity of HTTP responses it is possible to automatically reduce the target scope by removing the similar (and therefore redundant) HTTP responses.

A technology that can be applied to detect similar HTML structures from HTTP responses is graph theory. Graph theory can enable the scanners to detect similar HTTP responses by adding all incoming HTTP responses to the graph except the HTTP responses that have similar aspects as the HTTP responses that are already in the graph. Since scanners do not have access to the code of the web application they are scanning, the effectiveness can never be maintained with a 100% certainty.

The graph theory technology can be integrated into Burp Suite in a user friendly manner as an extension. After all the similar HTTP responses have been detected, the extension enables the user to either start scanning for vulnerabilities on all the unique HTTP requests or to export the unique HTTP requests to a text file and continue scanning for vulnerabilities in a scanner of choice. This makes it a generic open-source solution.

Target scope reduction using graph theory, in the form of a Burp Suite extension, is a user-friendly solution that improves the efficiency of scanners up to 45% while maintaining the effectiveness rate above 87% on average. Maintaining a 100% effectiveness is not always possible since scanners do not have access to the code of web applications they are scanning.

Similar Request Excluder is the name of the final product of this thesis. It used to be 'GraphWave', a mix of the words 'Northwave' and 'graph theory'. However, due to requirements from the Burp Suite App Store it was renamed to Similar Request Excluder. Similar Request Excluder was published on the 14{% raw %}<sup>th</sup>{% endraw %} of May, 2018 and since that day it is being used by security professionals around the globe.

<div class="row mb-2">
    <div class="col-md-6">
        <strong>Similar Request Excluder in the BAppStore.</strong>
        {% 
            include lightbox.html 
            image="/img/an-efficiency-improvement-for-burp-suite/similar-request-excluder-store.jpg"
            title="Similar Request Excluder in the BAppStore"
            album="similar-request-excluder"
            width="1173"
            height="576"
        %}
    </div>
    <div class="col-md-6">
        <strong>A screenshot of Similar Request Excluder.</strong>
        {% 
            include lightbox.html 
            image="/img/an-efficiency-improvement-for-burp-suite/similar-request-excluder-screenshot.jpg"
            title="A screenshot of Similar Request Excluder"
            album="similar-request-excluder"
            width="1173"
            height="576"
        %}
    </div>
</div>
