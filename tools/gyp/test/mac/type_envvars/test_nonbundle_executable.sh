#!/bin/bash
# Copyright (c) 2011 Google Inc. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e
# For some reason, Xcode doesn't set MACH_O_TYPE for non-bundle executables.
# Check for "not set", not just "empty":
[[ ! $MACH_O_TYPE && ${MACH_O_TYPE-_} ]]
test $PRODUCT_TYPE = com.apple.product-type.tool
