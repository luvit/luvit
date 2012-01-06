#!/bin/sh

# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Does the equivalent of
#   sed -e A -e B infile > outfile
# in a world where doing it from gyp eats the redirection.

infile="$1"
outfile="$2"
shift 2

sed "$@" "$infile" > "$outfile"
