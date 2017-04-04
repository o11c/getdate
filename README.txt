2007-08-10
----------

with the help of the 'modulator' tool found in the python 2.4 tarball I got
this module to work with python 2.4.

this extension no longer uses distutils, since I was not able to come up
with rules and such that would make it build on my current workstation... I
made a Makefile that works with a few minor adjustments regarding paths to
header files.

there is a package called 'dateutils' which I would like to integrate with,
since their parser does not handle expressions like "first monday" or
"tomorrow", which are useful things for tools such as 'projectflow' which
have "next action alarms" for all records.

The URL for this module is now http://projects.zoidtechnologies.com/getdate/

this version has been tested and works with a fedora core 5 system using
python 2.4.

TODO: add handling of "noon" and "midnight"

TODO: use the system level timezone handling. I know that win32 (and most
 likely win64) have had serious "issues" with timezone handling in the past,
 but uhmm.. frock it.

TODO: build a binary rpm

TODO: freshmeat.net announcement

---------------
OLD NOTES
---------------

2004-08-09
----------

Michal Vitecek sent a patch that supports abbreviations for relative
time (y year, M == month, d == day, h == hour, m == minute) and a standard
distutils-like installation. he also grabbed the latest getdate.c from the
CVS source code as it fixes a bug in relative dates computations. Michal
also contributed a dist-utils setup.

2004-05-26
----------

I updated this code to work with python 2.3 by modifying the Makefile
slightly. the code should work fine with older versions of python. if not,
please drop me an email.

NOTE: the 'getdate.y' file was *not* written by me-- I copied it verbatim
from the cvs-1.10.9 source code.

My contribution to this code is hereby released under the terms of the GNU
General Library License (LGPL)

This code works on my Fedora Core 2 system with python 2.3 installed.. it
should work on other platforms without too much fuss.

In order to compile on Mac OSX, change the compiler options thus:

g++ -flat_namespace -bundle -undefined suppress -o getdate.so wrapper.o getdate.o

The URL for this module is now http://zoidtechnologies.com/projects/getdate/

Comments, and _constructive_ criticism are appreciated. Please send email to
<jam@zoidtechnologies.com>

thanks to fuf for submitting a patch to use distutils, upgrading the parser
to use the current version from CVS, and for adding some additional
functionality:
  - h == hours, m == minutes M == months
