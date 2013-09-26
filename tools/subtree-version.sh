#!/bin/bash

find_latest_squash()
{
  dir="$1"
  sq=
  main=
  sub=
  git log --grep="^git-subtree-dir: $dir/*\$" \
    --pretty=format:'START %H%n%s%n%n%b%nEND%n' HEAD |
  while read a b junk; do
    case "$a" in
      START) sq="$b" ;;
      git-subtree-mainline:) main="$b" ;;
      git-subtree-split:) sub="$b" ;;
      END)
      if [ -n "$sub" ]; then
        if [ -n "$main" ]; then
          # a rejoin commit?
          # Pretend its sub was a squash.
          sq="$sub"
        fi
        echo "${sub:0:7}"
        break
      fi
      sq=
      main=
      sub=
      ;;
    esac
  done
}

find_latest_squash $1
