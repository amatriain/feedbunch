Openreader
==========
[![Build Status](https://travis-ci.org/amatriain/openreader.png)](https://travis-ci.org/amatriain/openreader) [![Coverage Status](https://coveralls.io/repos/amatriain/openreader/badge.png?branch=master)](https://coveralls.io/r/amatriain/openreader) [![Code Climate](https://codeclimate.com/github/amatriain/openreader.png)](https://codeclimate.com/github/amatriain/openreader) [![Dependency Status](https://gemnasium.com/amatriain/openreader.png)](https://gemnasium.com/amatriain/openreader)

[Latest documentation at rdoc.info](http://rubydoc.info/github/amatriain/openreader/frames/file/README.md)

Licensed under the MIT license (see LICENSE.txt file in the root directory for details).

As you probably know, Google has recently announced its decision to [discontinue Google Reader on July 1, 2013](http://googlereader.blogspot.ca/2013/03/powering-down-google-reader.html).

If you didn't know: first of all, where have you been living lately? Second: yes I know, it's a damn shame, what is Google thinking about, curse them and their "do no evil", all that jazz. Third, you should make a backup of your Google Reader data, specially your suscribed feeds. Go to [Google Takeout](https://www.google.com/takeout/?pli=1#custom:reader), make a backup and save it somewhere safe. Preferably make copies in different hard drives, better safe than sorry. Go on, I'll be waiting here.

Understandably there's been a [lot](http://lifehacker.com/5990454/google-is-killing-google-reader?tag=google-reader) of [talk](http://techcrunch.com/2013/03/24/bees/), [headscratching](http://www.slate.com/articles/technology/technology/2013/03/google_reader_why_did_everyone_s_favorite_rss_program_die_what_free_web.html) and [facepalming](http://www.reddit.com/r/technology/comments/1a8ygk/official_google_reader_blog_powering_down_google/) from the internet. I think this is a horrible misstep from Google, but even though some [petitions](https://www.change.org/petitions/google-keep-google-reader-running) have been started to try to convince them to keep Reader running, I think there's zero chance of Google changing their minds about this.

People who feel that Google+ is not at all a replacement to a feed reader, like myself, are now looking for a valid replacement. There are not many: Google Reader was good enough, and it was from Google, and it was free. It's hard to compete against that, and the result is that there were not many who tried. And of those alternatives that do exist, I feel that most are not a good fit to an ex-Reader user: they have glitzy but uncomfortable user interfaces with huge image tiles instead of text content, trying too hard to differentiate from Reader. Or they focus too much on newsreading or social content instead of just being a feed reader and staying out of the way. Or they require installing a browser plugin instead of having a web interface accessible from anywhere. Or they are too closed and don't support open APIs or a standard way of exporting my data, making it hard to migrate from them in the future.

Ideally as far as I'm concerned a feed reader should:

- support all current Google Reader features.
- support the social sharing features that [google removed some time ago](http://googlereader.blogspot.com.es/2011/10/new-in-reader-fresh-design-and-google.html) (yes, this was a sign that Google perhaps didn't care about its users so much). In fact it should also integrate with services Google has decided to ignore: Twitter, Facebook, Evernote, Instapaper, Pocket...
- have a text-centric interface similar to Google Reader, while at the same time not looking dated.
- support the Google Reader API, so that it would be easy for existing Reader clients (like the beautiful [Press for Android](http://twentyfivesquares.com/press/)) to use this service instead of Reader as a backend.
- be open-source, developed in the open with open technologies and standards.
- have an export feature that would allow for easily migrating to other services.
- be reasonably easy for a technically proficient user to install in his own server, so that you're never a victim of vendor lock-in.
- have a distributed architecture in which each deployment of the application knows about other deployments and communicates with them, so that you can engage in social sharing not just with users from your deployment, but with users from other deployments too.

That's a pretty specific wish list. As far as I know there's nothing out there that fullfills these requirements, so in the true spirit of open-source I've decided to scratch this itch and implement it.

I'm using technologies I feel comfortable with: Ruby on Rails, Resque, Postgresql and Bootstrap, mainly. Current deployment target is an EC2 instance with Ubuntu server, Apache and Passenger. During development I may decide to use technologies I'm not yet proficient with like MongoDB, we will see.

This is very much a work in progress and for some time there won't be much to see. If you like the idea and feel like you can contribute, do not hesitate to contact me, my email is in my profile.
