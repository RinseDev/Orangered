# [Orangered](http://insanj.com/orangered)

Native push notifications for Reddit. Orangered seamlessly connects your device to Reddit, as quickly and flexibly as possible. With an impressive list of supported clients, and simple, configurable options, you'll never feel closer to your inbox. Set up recurring inbox checks, or simply trigger Orangered with built-in Activator support (or even manually in the Settings).

Built with love and care by Julian Weiss and Phillip Tennen. Supports all devices running iOS 7-8. Icon and website design by Kyle Paul.

Currently supports (in order of precedence):

	Alien Blue, Alien Blue HD, beam, narwhal, Feedworthy, Biscuit, Cake, Reddme, Aliens, amrc, Redditor, BaconReader, Reddito, Karma, Redd, Upvote, Flippit, MyReddit, Mars, OJ Free, OJ, Karma Train, iAlien


Commercial, open source tweak. [Available from BigBoss](http://cydia.saurik.com/package/com.insanj.orangered7/) for $0.99.


![iOS 7 Icon](Icon.png)

## Organization

This repository is organized around simplicity and cleanliness of usage and understanding. Since the iOS 7 update, all network communications are handled through [RedditKit](https://github.com/samsymons/RedditKit), the full clone of which exists through a ```submodule``` in the [RedditKit directory](RedditKit/), likewise for secure credential storing and [FDKeychain](https://github.com/reidmain/FDKeychain). To make importing and making these files straightforward, all needed headers and implementations are dumped in the [External directory](External/).

In addition to the core functionality of Reddit communications and notifications, the subprojects [ORListener](ORListener/) and [ORPrefs](ORPrefs/) exist to provide an Activator outlet (action) and Preferences area (pane controller).

##  [License](LICENSE.md)

   	Orangered: Native push notifications for Reddit
   	Copyright (C) 2013-2015  Julian (insanj) Weiss
   	Copyright (C) 2014  Phillip Tennen 

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
