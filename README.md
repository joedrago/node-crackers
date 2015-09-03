Crackers: Comic Rack Generator
------------------------------

A commandline tool for turning an organized directory of .cbr and .cbz files into a pretty comic book reader.

Released under the Boost Software License (Version 1.0).

Installation:
-------------

    npm install -g crackers

Requirements:
-------------

Uses external commands *unrar*, *unzip*, and (from ImageMagick) *convert* and *composite*. The tool will complain wildly if it cannot find these on your machine, and they should be built-in on Windows (no extra installation necessary).

Commandline Usage:
------------------

    Syntax: crackers [-h] [-v] [-f] directoryName
            -h,--help         This help output
            -v,--verbose      Verbose output
            -c,--cover        Force regeneration of covers
            -u,--unpack       Force reunpack of cbr/cbz files

Hints and Tips
--------------

The basic usage is simply to run crackers with the root of your comic gallery as the only argument. It will make a best effort to not unpack any archives that it doesn't think need to be unpacked, and it will not regenerate any cover art thumbnails as well (both are forceable via the commandline).

If you want to unpack or regenerate any specific subset of your gallery, you can use that subdirectory on the commandline instead, and it'll walk up your file tree to find the actual "root" of the gallery, fixing as minimum of things as possible. Also, you can simply delete whatever subdirs you want and rerun crackers on the root of your gallery, and it will figure it out.
