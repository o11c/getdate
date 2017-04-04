#!/usr/bin/env python

import time
import getdate

str = "thursday 4am edt"

def test(str):
  try:
    t = getdate.getdate(str)
  except getdate.error:
    print "FAIL with string '%s'" % (str)
    return

  print "%s -> %d -> %s" % (str, t, time.ctime(t))

tests = ( "yesterday", "tomorrow", "thursday 4am edt", "tomorrow 12:00pm edt", "tomorrow noon" )

for t in tests:
  test(t)
