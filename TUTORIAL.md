- [Introduction](#introduction)
- [Installation](#installation)
  - [Installing node.js](#installing-nodejs)
  - [Installing prerequisites](#installing-prerequisites)
  - [Installing crackers](#installing-crackers)
  - [Sigh of relief](#sigh-of-relief)
- [My First Reader](#my-first-reader)
  - [Quick Tour](#quick-tour)
- [To Be Written](#to-be-written)

Introduction
============

So you say you wanted an online comic book reader?

This tutorial will go start from the very basics of what Crackers offers, how to install it (and any requirements), and how to get your first gallery up and running. From there, we'll go over some more advanced features, followed by some additional tools Crackers offers for keeping things nice and tidy.

This tutorial is written with the intent that you'll be following along on your machine as you go. Each step will build on the previous knowledge in this guide, so make sure you know what you're doing if you skip ahead!

**Note:** This tutorial doesn't make any assumptions about your knowledge of any of the tools in here, but it does assume you have a basic understanding of files and directories ("folders"), and a little bit of navigating around in a command prompt.

Installation
============

Installing node.js
------------------

Crackers runs inside of the node.js (V8) Javascript interpreter. If you're already familiar with node.js and have it installed on your machine, **skip this section**.

To install node.js on Windows or OSX, visit https://nodejs.org and grab the latest install. Typically the defaults in the installation are good/harmless.

If you're installing on Linux, consult your distribution on the correct package and command to install the ``node`` and `npm` commands. Sometimes these are broken up into multiple packages. For example, Ubuntu requires that you install `nodejs`, `nodejs-legacy`, and `npm`. While you're at it, install the next sections' requirements while you're at it:

    sudo apt-get install nodejs nodejs-legacy npm webp unrar unzip imagemagick

To verify that your installation is correct, open your favorite command prompt (`cmd` on windows, Terminal on OSX, etc) and type:

    node -v
    npm -v

Both should simply return a version string and quit. If not, you've done something awful and are Bad and should Feel Bad. If not, please move onto the next section.

Installing prerequisites
------------------------

Crackers leverages a few tools in order to unpack the comic book archives and prepare the images for browsing:

* imagemagick: `identify`, `composite`, `convert`
* webp: `dwebp`
* `tar`
* `unrar`
* `unzip`
* `zip`

If you're on Windows, these tools come along with the crackers installation and _no extra work is necessary_. **Surprise!** Please move onto the next section.

If you're on OSX, you most likely have a few of these already (`tar` for sure, and perhaps `unzip`). The rest of these are installed with [Homebrew](http://brew.sh/). Install Homebrew following the instructions from the website, and then use the command `brew install _____` to install the packages listed above. Use `imagemagick` and `webp` for the first two. You can verify you have each of the commands listed above by simply typing `which ____` to see if you have it already. If it doesn't print anything, try to install it with brew.

If you're on Linux, you probably installed everything in the last step already.

Installing crackers
-------------------

At the command prompt from the previous commands, type this:

    npm install -g crackers

If you're on OSX or Linux, you probably need to prepend `sudo` in order to run npm with the right permissions.

Once this command completes, you should be able to type `crackers` and see it return a list of possible actions. It will also complain at this point if you missed one ofe the prerequisites from the previous step here.

Sigh of relief
--------------

Installation is complete! You're now ready to start playing with Crackers.




My First Reader
===============

In order to make yourself a comic book gallery, you need a comic book in digital form first. Comic books are typically stored as compressed archives of regular images. The image format seems to range all over, but tends to be PNG more often than not. The archive format is either rar, zip, or tar files, and can have the extension `.cbr`, `.cbz`, or `.cbt`. I'd have said "respectively" there if they actually matched those extensions strictly, but they don't. Fret not, crackers detects the format from within instead of trusting some random comic book archive creator to use the right extension.

Perhaps you already have a whole pile of them, which is why you're bothering with this tutorial in the first place. Either way, let's all use this silly one here that I've created:

https://github.com/joedrago/node-crackers/raw/master/tutorial/Awesome.cbz

(It should have 3, really bland, programmer-art pages in it. You can see for yourself, if you're curious. Simply make a copy of it, change the extension to .zip and open it up.)

Make yourself a new directory to be the "crackers root directory": the main home for all of your comics. Either do this in your OS's user interface, or switch into your favorite temporary directory and run `mkdir comics`. Then simply copy your new `Awesome.cbz` you just downloaded directly into that new directory.

**Note:** I'm going to assume from now on that any commands I have you type will act on a directory named `comics`. Please adjust your commands accordingly. You may even use `.` instead of `comics` if you are inside of the directory itself.

Now type the following:

    crackers update comics

You should get something similar to the following:

    $ crackers update comics
    5 Apr 21:06:51 - [warning] crackers root not found (root.crackers not detected in parents).
    5 Apr 21:06:51 - [progress] Unpacking /tmp/comics/Awesome.cbz into /tmp/comics/Awesome
    5 Apr 21:06:54 - [progress] Updated comic: Awesome (3 pages)
    5 Apr 21:06:54 - [progress] Updated metadata: Crackers

If you look in the `comics` directory, you should see a handful of files, such as:

* `archives` - Empty dir that will contain comic book archives you generate with `crackers archive`
* `Awesome` - Extracted comic, organized in a way Crackers understands, along with some metadata
* `Awesome.cbz` - Your original archive, untouched
* `client.crackers` - The client manifest that the UI downloads when you open it
* `index.html` - The actual UI
* `root.crackers` - A hint to Crackers that this is the root dir, along with some settings
* `server.crackers` - The server manifest (unused unless you enable 'progress' support)
* `updates.crackers` - Another manifest file, downloaded and used by the Updates UI

_But ... how do I see my gallery?_ In its basic form, Crackers only requires a basic, static web server to work. Unfortunately, simply double clicking on `index.html` is going to work, as modern browsers won't let you read files next to the index when served directly from the disk. If you already have a favorite way to serve up a static directory, fire it up, point it at `comics`, and move onto the next section.

Still here? Alright, since you already have node.js installed, let's use another really simple tool via `npm` to pull this off. Try these commands (Linux and OSX users should prefix all `npm install -g ____` commands with `sudo`):

    npm install -g http-server
    http-server comics

It should say something like:

    $ http-server comics
    Starting up http-server, serving comics
    Available on:
      http://127.0.0.1:8080
    Hit CTRL-C to stop the server

Open up your favorite browser and visit the URL it offers, then (assuming you see cool things), move onto the next section.

Quick Tour
----------

You did it! Bask in the glory of your one-comic reader. You should see a red toolbar at the top of a black screen with a single comic in it. The toolbar has a menu (hamburger) button in the top left, and a basic sorting pulldown in the top right. If you click on the comic, it should let you read it. At the time of this tutorial, I still haven't written the Help page in the UI, but you're really brilliant and handsome, so you'll figure it out.


To Be Written
=============

* Enabling the progress endpoint
* crackers organize
* crackers merge
* crackers rename
* crackers cleanup
