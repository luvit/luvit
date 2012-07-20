#!/bin/sh

send0() {
  cat << _EOF
GET /$1 HTTP/1.1

GET /$2 HTTP/1.1

GET /$3 HTTP/1.1

GET /$4 HTTP/1.1

_EOF
  sleep 1
}

send() {
  send0 $* | nc 127.0.0.1 8080 | sed -nr 's/^.*\[([0-9][0-9][0-9])\].*$/\1/p'
}

send 1 2 3 4 >log
send 3 2 1 4 >>log
send 2 4 3 1 >>log
send 1 2 4 3 >>log
send 2 4 1 3 >>log

cmp pipeline.ok log && rm log || echo "PIPELINE TEST FAILED. Compare pipeline.ok and log files"
