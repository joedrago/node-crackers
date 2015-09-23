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

    Syntax: crackers [-h]
            crackers [-v] [-c] [-u]   update   PATH           (aliases: create, generate, gen)
            crackers [-v] [-x] [-t T] organize PATH [PATH...] (aliases: rename, mv)
            crackers [-v] [-x]        cleanup  PATH [PATH...] (aliases: remove, rm, del)

    Global options:
            -h,--help         This help output
            -v,--verbose      Verbose output

    Update options:
            -c,--cover        Force regeneration of covers
            -d,--download     Show download links when cbr/cbz files are still present
            -u,--unpack       Force reunpack of cbr/cbz files

    Organize options:
            -t,--template T   Use template T when renaming. Default: {name}/{issue.3}

    Organize / Cleanup options:
            -x,--execute      Perform rename/remove (default is to simply list actions)


Hints and Tips
--------------

The basic usage is simply to run crackers with the root of your comic gallery as the only argument to "crackers update". It will make a best effort to not unpack any archives that it doesn't think need to be unpacked, and it will not regenerate any cover art thumbnails as well (both are forceable via the commandline).

If you want to unpack or regenerate any specific subset of your gallery, you can use that subdirectory on the commandline instead, and it'll walk up your file tree to find the actual "root" of the gallery, fixing as minimum of things as possible. Also, you can simply delete whatever subdirs you want and rerun crackers on the root of your gallery, and it will figure it out.

The organize and cleanup commandlines are simple tools used to organize your directories. Use -x with caution!

Libraries Used
--------------

* Fotorama: http://fotorama.io/
* isMobile: https://github.com/kaimallea/isMobile/
* jQuery: https://jquery.com/
* jquery-cookie: https://github.com/carhartl/jquery-cookie
