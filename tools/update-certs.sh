#!/bin/sh

set -e

rm -rf cacert.pem && wget https://curl.se/ca/cacert.pem
luvit convert.lua
mv certs.dat ../deps/tls/root_ca.dat
