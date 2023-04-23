#!/bin/bash

# Author: Aziz Köksal <aziz.koeksal@gmail.com>
# License: MIT

function maybe_exit() { RET=$? && if [[ $RET != 0 ]]; then log_ln "$@"; exit $RET; fi }

function print_args() { printf ' %q' "$@" | tail -c+2; }

function log() { local IFS=' '; printf '%b' "$*" >&2; }
function log_ln() { log "$*"'\n'; }
function log_run() { log_ln "$ $(print_args "$@")"; "$@"; }
function log_run_2() { log_run "$@" >&2; }
