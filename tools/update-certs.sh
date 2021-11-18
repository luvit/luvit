#!/bin/sh

set -e

wget https://hg.mozilla.org/mozilla-central/raw-file/tip/security/nss/lib/ckfw/builtins/certdata.txt
go run convert_mozilla_certdata.go > certs.pem
luvit convert.lua
mv certs.dat ../deps/tls/root_ca.dat
