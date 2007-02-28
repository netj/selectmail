#!/usr/bin/env bash
# Extract tokens from mail messages or mailboxes
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2007-02-14

# Requires: mutt >= 1.4, screen

sep='

'

base=`dirname "$0"`
base=`cd "$base" && pwd || echo "$base"`
tokenize1="'${base//"'"/"'\\''"}/tokenize1'"

tmp=`mktemp -d /tmp/extract-text.XXXXXX`
trap "rm -rf $tmp" EXIT ERR TERM INT QUIT

extract() {
    local mbox=
    for mbox in "$@"; do
        screen -D -m \
        mutt -e 'unignore from: to cc subject mailing-list list-id' \
             -e 'ignore date' \
             -e 'set charset=utf-8' \
             -e 'set pipe_decode; set pipe_sep="'"$sep"'"; unset wait_key' \
             -e 'push "<tag-pattern>!~G<Enter><tag-prefix>|'"$tokenize1"' >>'$tmp/txt'<Enter><exit>"' \
             -R -z -f $mbox
    done
}

if [ $# -gt 0 ]; then
    extract "$@"
else
    formail >$tmp/mbox
    extract $tmp/mbox
fi

[ -f $tmp/txt ] && cat $tmp/txt
