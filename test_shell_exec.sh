#!/bin/sh

# used on windows to run the tests with a supporting environment

PATH=/bin:$PATH

tools/build.py test
