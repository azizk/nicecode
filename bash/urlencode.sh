#!/bin/bash

# One-liner using curl for URL-encoding a string.
# Inspired by: https://stackoverflow.com/a/10797966

urlencode() {
  curl -Gso /dev/null -w '%{url_effective}' --data-urlencode "$1" '' | tail -c+3
}
