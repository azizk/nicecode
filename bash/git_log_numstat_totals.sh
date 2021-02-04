#!/bin/bash

# Possible to exclude all .lock files using the ':!' pattern (opposite of '*').
# E.g.: ':!.lock'

function numstats() {
  git log --author="$1" --pretty=%H --no-merges --numstat --after=$2 --before=$3 \
    | grep -vP '(\.lock|-lock.json|\.svg)$' \
    | awk 'NF==3 {plus+=$1; minus+=$2} END {printf("+%d\t-%d\n", plus, minus)}'
}

DATES=(
"31.12.20  01.02.21"
)

for date_range in "${DATES[@]}"; do
  numstats $1 $date_range
done
