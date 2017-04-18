# Feedbunch

A simple and elegant feed reader.

[![Build Status](https://semaphoreci.com/api/v1/projects/fb7ea494-699a-4733-a494-b806ae6fb249/396842/badge.svg)](https://semaphoreci.com/amatriain/feedbunch)
[![Coverage Status](https://coveralls.io/repos/github/amatriain/feedbunch/badge.svg?branch=master)](https://coveralls.io/github/amatriain/feedbunch?branch=master)
[![Code Climate](https://codeclimate.com/github/amatriain/feedbunch.png)](https://codeclimate.com/github/amatriain/feedbunch)
[![Inline docs](http://inch-ci.org/github/amatriain/feedbunch.png)](http://inch-ci.org/github/amatriain/feedbunch)

## Overview

Feedbunch is a feed reader, a web application that allows users to subscribe and read Atom and RSS feeds. It is offered
as a SaaS (software-as-a-service) at [feedbunch.com](http://feedbunch.com), and is fully open source.

Feedbunch aims to be as pleasant to use as possible, with a simple and uncluttered interface. It hides unnecessary
complexity from users as much as possible:

- it adapts automatically to different browser sizes (desktop, tablet or smartphone), presenting an interface suited for
each screen size
- it has simple guided tours to familiarize new users with the use of the application without having to read any
documentation
- it supports feed autodiscovery, allowing users in most cases to subscribe to a feed just entering the website URL,
without having to look for the sometimes hard to find "subscribe to feed" link on the page
- all feed entries are sanitized before being displayed to the user, removing potentially malicious scripts and content.
 Users will be protected from malware and vulnerabilities even if the feed's website becomes compromised by hackers
- it learns and adapts to the periodicity at which new entries appear in each feed, ensuring that new entries are
shown to users as soon as possible after publishing
- images in an entry are loaded only after the user opens the entry, saving bandwidth for images in entries that the
user never opens (specially nice for people with bandwidth caps!)
- in most cases it can detect when a website has changed its feed URL and switch to the new URL without missing entries
(e.g. if a blog migrates from Wordpress built-in feeds to  Feedburner), even if the website does not set up a proper
redirect to the new URL
- it detects when a feed has become permanently unavailable and desists from updating it, saving bandwith for the domain
owner

## What is a feed reader? What is a feed?

You can find a simple description of what a feed reader is in [this wikipedia article](http://en.wikipedia.org/wiki/News_aggregator)
and a good description of the use and technology behind feeds in [this Google support article](https://support.google.com/feedburner/answer/79408?hl=en).

Basically, it is a way to aggregate content updates from various websites in a single place. Instead of having to
visit each of your favorite websites every day to see if there's new content, anything those websites publish will
appear in Feedbunch. This way you only have to visit Feedbunch to be up to date with all blogs, newspapers, webcomics etc
that you follow. You will save a lot of time.

Another advantage of using a feed reader is that you can subscribe and unsubscribe from feeds as you get interested or lose
your interest in them, in a way creating your own personalized newspaper. You can also organize feeds in folders to help
you organize your reading efficiently and cope with information overload. Believe me, using feeds is addictive, you may
soon find yourself subscribed to so many that anything that helps you organize them sounds like a great idea!

For this to work, each website has to make available a special XML document that gets updated every time new content is
published in the website. This XML document is called the **feed** and every new piece of content that is added to it is
called an **entry**. Entries can be news articles in a newspaper's website, new pages in a webcomic, new comments in a
blog entry... Most websites nowadays have a feed (or several), in fact most blogging and CMS platforms include a feed by
default in any websites they manage, without having to configure anything.

The main standards for feeds are [RSS](http://en.wikipedia.org/wiki/RSS) and [Atom](http://en.wikipedia.org/wiki/Atom_%28standard%29)
(wikipedia links). Often people speak about "RSS feeds" indistinctly, which is actually a bit of a misnomer. Feedbunch
users don't have to worry about this, both standards are transparently supported.

## Getting started

Just visit [feedbunch.com](http://feedbunch.com) and sign up for a new account. You will need a valid email address.

Once signed in, take some time to follow the interactive tours, they will show you what you can do with the application.
Import your subscriptions in OPML format from another feed aggregator or just start subscribing to feeds. Pretty soon
you will have a personalized set of feeds that interest you.

## Getting help

You can get help, inform us of bugs, suggest new features or just tell us what you think about Feedbunch through:

- email: admin@feedbunch.com
- twitter: [@feedbunch](http://twitter.com/feedbunch)
- github: [amatriain/feedbunch](https://github.com/amatriain/feedbunch)

You can use any of them, but in general:

- if you're reporting an error and have some experience reporting software bugs, the github repo's issue tracker is best.
Please use english if possible.
- if you're asking a general question that can also be interesting for other users, twitter is best.
- for matters you do not with to discuss in public, use the email

## Credits and acknowledgements

For a good long while the most popular feed reader was Google Reader. In fact it was probably the only feed reader that
mattered for most of the Internet. However Google closed down GReader on July 1 2013, forcing users to migrate to
alternative services. The development of Feedbunch was started to attempt to replace GReader and it is no coincidence that
some ideas in the user interface are inspired in GReader.

The server API is written using Ruby on Rails, along with many ruby gems generously shared by the community. Sidekiq is
used to process jobs asynchronously.

The client is an Ajax webpage. Bootstrap is used for the visual layout, along with FontAwesome for the icons. AngularJS
is used to communicate with the server-side API and keep the page dinamically updated with feeds, entries etc. Several
javascript libraries are also used like velocity.js for animations, hopscotch.js for the guided tours, favico.js to
display the number of unread entries in the favicon, and others.

PostgreSQL is used for the database layer, and Redis for more transient data (Rails cache and Sidekiq data).

## License

Licensed under the MIT license (see LICENSE.txt file in the root directory for details).

## How to contribute

Code is hosted in the [amatriain/feedbunch github repo](https://github.com/amatriain/feedbunch).

You can create issues in the issue tracker to discuss any bugs you find.

To contribute code:

- fork the repo
- create a branch with a name relevant to the change (e.g. "fix-mcguffin-rendering")
- commit your changes to the branch. Make small commits, avoid huge commits difficult to review. Please take some time to
read the surrounding code and imitate the coding style as much as you can. In your commit comments, use the first line
to briefly describe the change and go into detail below.
- create a pull request

### Code documentation

All classes, modules and methods are commented with [Rdoc](https://github.com/rdoc/rdoc). HTML documentation is
available online [at rubydoc](http://www.rubydoc.info/github/amatriain/feedbunch/).

If you add new methods, classes etc please add comments comparable to the existing ones. If you change existing methods
please update the method and class comment if they no longer accurately describe the method behavior.

Also you can add Ruby comments wherever you think the intent is not clear from reading the code. Just don't overdo it,
the best code is self-explanatory.

### Tests

The project uses Rspec for its tests. The ```spec``` folder is organized a bit different from the default Rspec layout:

- the ```unit_tests``` folder has unit tests for individual classes (models, controllers, etc).
- the ```acceptance_tests``` folder contains what Rspec calls feature tests. They simulate a user operating the application
with a headless webkit browser, using the selenium-webdriver gem.

The tests use FactoryGirl object factories, instead of test fixtures. Factory definitions are in the ```spec/factories```
folder.

Please add new tests or update existing ones when adding or changing features.

Semaphore CI is used for continuous integration. Any pull requests that have failed tests will probably not be accepted.

### Logging

The rails logger (```Rails.logger```) is used to write a log of events. Most methods have log statements to help with
debugging.

If you add features please consider if it's worth it adding log statements. Remember that the default log level in
production is ```warn```, so use lower-priority logging (```debug```, ```info```) for log lines that are not usually
interesting, only when debugging a particular problem. Try not to clutter the logs.
