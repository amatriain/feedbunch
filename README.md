# FeedBunch

A simple and elegant feed reader.

[![Build Status](https://gitlab.com/amatriain/feedbunch/badges/master/pipeline.svg)](https://gitlab.com/amatriain/feedbunch/-/commits/master)

## Important
This project is now hosted in [Gitlab](https://gitlab.com/amatriain/feedbunch). If you're reading this somewhere else
(e.g. in Github) be aware that it is a read-only mirror.

This project automatically builds Docker images and pushes them to Docker Hub every time a release is tagged in the 
main branch. You can find these images here: 

- [FeedBunch-background](https://hub.docker.com/repository/docker/amatriain/feedbunch-background)
- [FeedBunch-webapp](https://hub.docker.com/repository/docker/amatriain/feedbunch-webapp)
- [FeedBunch-cron](https://hub.docker.com/repository/docker/amatriain/feedbunch-cron)
- [FeedBunch-redis-sidekiq](https://hub.docker.com/repository/docker/amatriain/feedbunch-redis-sidekiq)
- [FeedBunch-redis-cache](https://hub.docker.com/repository/docker/amatriain/feedbunch-redis-cache)

All of these images are required simultaneously to run FeedBunch. For information about how to deploy to Docker using
docker-compose see the [installation instructions](INSTALLATION.md).

## Overview

FeedBunch is a feed reader, a web application that allows users to subscribe and read Atom and RSS feeds. It can be 
self-hosted, and is fully open source.

FeedBunch aims to be as pleasant to use as possible, with a simple and uncluttered interface. It hides unnecessary
complexity from users as much as possible:

- it adapts responsively to different browser sizes (desktop, tablet or smartphone), presenting an interface suited for
each screen size.
- it has simple guided tours to familiarize new users with the use of the application without having to read any
documentation.
- it supports feed autodiscovery, allowing users in most cases to subscribe to a feed just entering the website URL
without having to look for the sometimes hard to find "subscribe to feed" link on the page.
- all feed entries are sanitized before being displayed to the user, removing potentially malicious scripts and content.
 Users will be protected from malware and vulnerabilities even if the feed's website becomes compromised by hackers.
- it learns and adapts to the periodicity at which new entries appear in each feed, ensuring that new entries are
shown to users as soon as possible after publishing.
- images in an entry are loaded only after the user opens the entry, saving bandwidth for images in entries that the
user never opens (specially nice for people with bandwidth caps!).
- in most cases it can detect when a website has changed its URL domain and switch to the new domain without missing 
entries (e.g. if a blog migrates from Wordpress built-in feeds to  Feedburner), even if the website does not set up a
proper redirect to the new domain.
- it detects when a feed has become permanently unavailable and desists from updating it, saving bandwith for the domain
owner.

## What is a feed reader? What is a feed?

You can find a simple description of what a feed reader is in 
[this wikipedia article](http://en.wikipedia.org/wiki/News_aggregator)
and a good description of the use and technology behind feeds in 
[this Google support article](https://support.google.com/feedburner/answer/79408?hl=en).

Basically it is a way to aggregate content updates from various websites in a single place. Instead of having to
visit each of your favorite websites every day to see if there's new content, anything those websites publish will
appear in FeedBunch. This way you only have to visit FeedBunch to be up to date with all blogs, newspapers, webcomics etc
that you follow. You will save a lot of time.

Another advantage of using a feed reader is that you can subscribe and unsubscribe from feeds as you get interested or 
lose your interest in them, in a way creating your own personalized newspaper. You can also organize feeds in folders 
to help you organize your reading efficiently and cope with information overload. Believe me, using feeds is addictive, 
you may soon find yourself subscribed to so many that anything that helps you organize them sounds like a great idea!

For this to work, each website has to make available a special XML document that gets updated every time new content is
published in the website. This XML document is called the **feed** and every new piece of content that is added to it is
called an **entry**. Entries can be news articles in a newspaper's website, new pages in a webcomic, new comments in a
blog entry... Most websites nowadays have a feed (or several), in fact most blogging and CMS platforms include a feed by
default in any websites they manage, without having to configure anything.

The main standards for feeds are [RSS](http://en.wikipedia.org/wiki/RSS) and 
[Atom](http://en.wikipedia.org/wiki/Atom_%28standard%29)
(wikipedia links). Often people speak about "RSS feeds" indistinctly, which is actually a bit of a misnomer. FeedBunch
users don't have to worry about this, both standards are transparently supported.

## Installation

The supported installation method uses Docker-compose. Follow [these instructions](INSTALLATION.md).

## Getting started

If you follow the [installation instructions](INSTALLATION.md) you will have the credentials (username/password) for 
the first user, who will have administration permissions.

If you want to create users for other people in your installation, open the drop-down menu at the top right, and go 
to ```Administration / Users / New User``` (click on ```New User``` button).

The first time you sign in take some time to follow the interactive tours, they will show you what you can do with the 
application. Import your subscriptions in OPML format from another feed aggregator or just start subscribing to feeds. 
Pretty soon you will have a personalized set of feeds that interest you.

## Project structure

There are two main directories in the project: 

- ```FeedBunch-app```: contains the main Ruby on Rails application. It can be tested and deployed like any other 
Rails app, but the supported deployment method uses docker-compose.
- ```FeedBunch-docker```: contains the Dockerfiles and other files necessary to build Docker images for the app, 
as well as a sample docker-compose.yml that can be customized and used to deploy FeedBunch as explained in the
[installation instructions](INSTALLATION.md).

Inside the ```FeedBunch-docker``` directory there are several directories, each one with a Dockerfile and files
necessary to build a different Docker image:
- ```FeedBunch-background```:  image that runs a Sidekiq job queue and runs asynchronous jobs, most importantly 
refreshing feeds periodically.
- ```FeedBunch-cron```: image that runs periodically a script to clean up old files from the cache that
accelerates refreshing feeds, so that disk usage does not grow too much.
- ```FeedBunch-redis-cache```: image that runs a Redis database that serves as backend for the Rails HTML fragment
cache, accelerating the generation of dynamic pages for users.
- ```FeedBunch-redis-sidekiq```: image that runs a Redis database that serves as a backend for the Sidekiq job
queue (see ```FeedBunch-background```).
- ```FeedBunch-webapp```: main Rails app that serves HTML pages to users.

## Getting help

You can get help, inform me of bugs, suggest new features or just tell me what you think about FeedBunch through:

- email: geralt@gmail.com
- twitter: [@amatriain](http://twitter.com/amatriain)
- gitlab (**main development repo**): [amatriain/feedbunch](https://gitlab.com/amatriain/feedbunch)
- github (**read-only mirror**): [amatriain/feedbunch](https://github.com/amatriain/feedbunch)

You can use any of them, but in general:

- if you need support, want to suggest new features, thins you've found a bug or want to submit merge requests, the
gitlab repo's issue tracker is best. Please use english if possible.
- for matters you do not with to discuss in public, use email.

## Credits and acknowledgements

For a good long while the most popular feed reader was Google Reader. In fact it was probably the only feed reader that
mattered for most of the Internet. However Google closed down GReader on July 1 2013, forcing users to migrate to
alternative services. The development of FeedBunch was started to attempt to replace GReader and it is no coincidence 
that
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

Code is hosted in the [amatriain/feedbunch gitlab repo](https://gitlab.com/amatriain/feedbunch).

You can create issues in the issue tracker to discuss any bugs you find.

To contribute code:

- fork the repo
- create a branch with a name relevant to the change (e.g. "fix-mcguffin-rendering")
- commit your changes to the branch. Make small commits, avoid huge commits difficult to review. Please take some time 
to
read the surrounding code and imitate the coding style as much as you can. In your commit comments, use the first line
to briefly describe the change and go into detail below.
- create a pull request

### Code documentation

All classes, modules and methods are commented with [Rdoc](https://github.com/rdoc/rdoc).

If you add new methods, classes etc please add comments comparable to the existing ones. If you change existing methods
please update the method and class comment if they no longer accurately describe the method behavior.

You can add Ruby comments wherever you think the intent is not clear from reading the code. Just don't overdo it,
the best code is self-explanatory.

### Tests

The project uses Rspec for its tests. The ```spec``` folder is organized a bit different from the default Rspec layout:

- the ```unit_tests``` folder has unit tests for individual classes (models, controllers, etc).
- the ```acceptance_tests``` folder contains what Rspec calls feature tests. They simulate a user operating the 
application with a headless webkit browser, using the selenium-webdriver gem.

Tests use FactoryBot object factories, instead of test fixtures. Factory definitions are in the 
```spec/factories``` folder.

Please add new tests or update existing ones when adding or changing features.

Gitlab CI/CD is used for continuous integration/delivery. Any pull requests that have failed tests will probably not 
be accepted.

### Logging

The rails logger (```Rails.logger```) is used to write a log of events. Most methods have log statements to help with
debugging.

If you add features please consider if it's worth it adding log statements. Remember that the default log level in
production is ```warn```, so use lower-priority logging (```debug```, ```info```) for log lines that are not usually
interesting, only when debugging a particular problem. Try not to clutter the logs.
