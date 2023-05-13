---
layout: post
title: A web application crawler for bug bounty hunting
subtitle: A Python-based web crawler that enables you to execute your payload against all requests in scope.
description: Not Your Average Web Crawler (NYAWC) is a Python package that enables you to crawl web applications for requests instead of URL's. With NYAWC you can execute your malicious payload on all in-scope requests of a web application.
keywords: nyawc, web, application, crawler, spider, crawling, bot, hacking, bug, bounty, open, source, python
include_in_header: false
include_in_footer: false
show_in_post_list: true
robots: index, follow
---

Not Your Average Web Crawler ([N.Y.A.W.C](https://github.com/tijme/not-your-average-web-crawler){:target="_blank"}{:rel="noopener noreferrer"}) is a web application crawler for vulnerability scanning. It crawls every request in a specified scope and keeps track of the request/response data. I developed N.Y.A.W.C because I needed a good open-source Python crawler that enabled me to modify requests on the go for my [AngularJS CSTI scanner](https://github.com/tijme/angularjs-csti-scanner){:target="_blank"}{:rel="noopener noreferrer"}.

### Crawling flow

The crawler is multi-threaded but you don't have to worry about any of the multi threading yourself. To give you a better idea of the crawling flow I added the diagram below.

1. You can define your startpoint (a request) and the crawling scope and then start the crawler.
2. The crawler repeatedly starts the first request in the queue until `max threads` is reached.
3. The crawler adds all requests found in the response to the end of the queue (except duplicates).
4. The crawler goes back to step #2 to spawn new requests repeatedly until `max threads` is reached.

Please note that if the queue is empty and all crawler threads are finished, the crawler will stop.

{% 
    include lightbox.html 
    image="/img/a-web-application-crawler-for-bug-bounty-hunting/nyawc-flow.svg"
    title="Crawling flow of NYAWC"
    album="nyawc-flow"
    width="293.33"
    height="538.66"
%}

There are several hooks in the code that you can use to, for example, tamper form data before it is posted. Check the [documentation](https://tijme.github.io/not-your-average-web-crawler/latest/options_callbacks.html){:target="_blank"}{:rel="noopener noreferrer"} for more information about those hooks.

### Installation

First make sure you're on Python 2.7/3.3 or higher. After that install N.Y.A.W.C via PyPi using the command below.

{% highlight bash %}
pip install --upgrade nyawc
{% endhighlight %}

The kitchen sink code sample below can be used to get the crawler up and running within a few minutes. If you like it, check out the [documentation](https://tijme.github.io/not-your-average-web-crawler/){:target="_blank"}{:rel="noopener noreferrer"} to get started on implementing your own exploits.

{% highlight python %}
# -*- coding: utf-8 -*-

# MIT License
#
# Copyright (c) 2017 Tijme Gommers
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from nyawc.Options import Options
from nyawc.QueueItem import QueueItem
from nyawc.Crawler import Crawler
from nyawc.CrawlerActions import CrawlerActions
from nyawc.http.Request import Request
from requests.auth import HTTPBasicAuth

def cb_crawler_before_start():
    print("Crawler started.")

def cb_crawler_after_finish(queue):
    print("Crawler finished.")
    print("Found " + str(len(queue.get_all(QueueItem.STATUS_FINISHED))) + " requests.")

    for queue_item in queue.get_all(QueueItem.STATUS_FINISHED).values():
        print("[" + queue_item.request.method + "] " + queue_item.request.url + " (PostData: " + str(queue_item.request.data) + ")")

def cb_request_before_start(queue, queue_item):
    # return CrawlerActions.DO_SKIP_TO_NEXT
    # return CrawlerActions.DO_STOP_CRAWLING

    return CrawlerActions.DO_CONTINUE_CRAWLING

def cb_request_after_finish(queue, queue_item, new_queue_items):
    percentage = str(int(queue.get_progress()))
    total_requests = str(queue.count_total)

    print("At " + percentage + "% of " + total_requests + " requests ([" + str(queue_item.response.status_code) + "] " + queue_item.request.url + ").")

    # return CrawlerActions.DO_STOP_CRAWLING
    return CrawlerActions.DO_CONTINUE_CRAWLING

def cb_request_in_thread_before_start(queue_item):
    pass

def cb_request_in_thread_after_finish(queue_item):
    pass

def cb_request_on_error(queue_item, message):
    print("[error] " + message)

def cb_form_before_autofill(queue_item, elements, form_data):
    # return CrawlerActions.DO_NOT_AUTOFILL_FORM

    return CrawlerActions.DO_AUTOFILL_FORM

def cb_form_after_autofill(queue_item, elements, form_data):
    pass

# Declare the options
options = Options()

# Callback options (https://tijme.github.io/not-your-average-web-crawler/latest/options_callbacks.html)
options.callbacks.crawler_before_start = cb_crawler_before_start # Called before the crawler starts crawling. Default is a null route.
options.callbacks.crawler_after_finish = cb_crawler_after_finish # Called after the crawler finished crawling. Default is a null route.
options.callbacks.request_before_start = cb_request_before_start # Called before the crawler starts a new request. Default is a null route.
options.callbacks.request_after_finish = cb_request_after_finish # Called after the crawler finishes a request. Default is a null route.
options.callbacks.request_in_thread_before_start = cb_request_in_thread_before_start # Called in the crawling thread (when it started). Default is a null route.
options.callbacks.request_in_thread_after_finish = cb_request_in_thread_after_finish # Called in the crawling thread (when it finished). Default is a null route.
options.callbacks.request_on_error = cb_request_on_error # Called if a request failed. Default is a null route.
options.callbacks.form_before_autofill = cb_form_before_autofill # Called before the crawler autofills a form. Default is a null route.
options.callbacks.form_after_autofill = cb_form_after_autofill # Called after the crawler autofills a form. Default is a null route.

# Scope options (https://tijme.github.io/not-your-average-web-crawler/latest/options_crawling_scope.html)
options.scope.protocol_must_match = False # Only crawl pages with the same protocol as the startpoint (e.g. only https). Default is False.
options.scope.subdomain_must_match = True # Only crawl pages with the same subdomain as the startpoint. If the startpoint is not a subdomain, no subdomains will be crawled. Default is True.
options.scope.hostname_must_match = True # Only crawl pages with the same hostname as the startpoint (e.g. only `finnwea`). Default is True.
options.scope.tld_must_match = True # Only crawl pages with the same tld as the startpoint (e.g. only `.com`). Default is True.
options.scope.max_depth = None # The maximum search depth. 0 only crawls the start request. 1 will also crawl all the requests found on the start request. 2 goes one level deeper, and so on. Default is None (unlimited).
options.scope.request_methods = [
    # The request methods to crawl. Default is all request methods
    Request.METHOD_GET,
    Request.METHOD_POST,
    Request.METHOD_PUT,
    Request.METHOD_DELETE,
    Request.METHOD_OPTIONS,
    Request.METHOD_HEAD
]

# Identity options (https://tijme.github.io/not-your-average-web-crawler/latest/options_crawling_identity.html)
options.identity.auth = HTTPBasicAuth('user', 'pass') # Or any other authentication (http://docs.python-requests.org/en/master/user/authentication/). Default is None.
options.identity.cookies.set(name='tasty_cookie', value='yum', domain='finnwea.com', path='/cookies')
options.identity.cookies.set(name='gross_cookie', value='blech', domain='finnwea.com', path='/elsewhere')
options.identity.proxies = {
    # No authentication
    # 'http': 'http://host:port',
    # 'https': 'http://host:port',

    # Basic authentication
    # 'http': 'http://user:pass@host:port',
    # 'https': 'https://user:pass@host:port',

    # SOCKS
    # 'http': 'socks5://user:pass@host:port',
    # 'https': 'socks5://user:pass@host:port'
}
options.identity.headers.update({
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36"
})

# Performance options (https://tijme.github.io/not-your-average-web-crawler/latest/options_performance.html)
options.performance.max_threads = 20 # The maximum amount of simultaneous threads to use for crawling. Default is 40.
options.performance.request_timeout = 15 # The request timeout in seconds (throws an exception if exceeded). Default is 30.

# Routing options (https://tijme.github.io/not-your-average-web-crawler/latest/options_routing.html)
options.routing.minimum_threshold = 4 # The minimum amount of requests to crawl (matching a certain route) before ignoring the rest. Default is 20.
options.routing.routes = [ 
    # The regular expressions that represent routes that should not be cralwed more times than the minimum treshold. Default is an empty array.
    "^(https?:\/\/)?(www\.)?finnwea\.com\/blog\/[^\n \/]+\/$" # Only crawl /blog/{some-blog-alias} 4 times.
]

# Misc options (https://tijme.github.io/not-your-average-web-crawler/latest/options_misc.html)
options.misc.debug = False # If debug is enabled extra information will be logged to the console. Default is False.
options.misc.verify_ssl_certificates = True # If verification is enabled all SSL certificates will be checked for validity. Default is True.
options.misc.trusted_certificates = None # You can pass the path to a CA_BUNDLE file (.pem) or directory with certificates of trusted CAs. Default is None.

crawler = Crawler(options)
crawler.start_with(Request("https://finnwea.com/"))
{% endhighlight %}