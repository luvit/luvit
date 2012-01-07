#!/usr/bin/env python

import sys

infile = sys.argv[1]
outfile = sys.argv[2]
params = sys.argv[3:]

fi = open(infile, 'r')
fo = open(outfile, 'w')

while fi:
  line = fi.readline()
  if not line:
    break
  for param in params:
    terms = param.split(':')
    # horribel hack
    if terms[0].startswith('{') and terms[0].endswith('}'):
      terms[0] = '$' + terms[0]
    if line.find(terms[0]) >= 0:
      line = line.replace(terms[0], terms[1])
  fo.write(line)

fi.close()
fo.close()

