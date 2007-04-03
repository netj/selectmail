#!/usr/bin/env bash
# vocabularies

Name=`basename "$0"`
Base="`dirname "$0"`/$EXEDIR"
Base=`cd "$Base" && pwd || echo "$Base"`
PATH="$Base:$PATH"

err() {
    local c=$?
    echo "$Name: $@" >&2
    return $c
}

see_usage() {
    {
        [ $# -eq 0 ] || err "$@"
        echo "Try \`$Name -h\` for more help."
    } >&2
    exit 2
}

need_tmp() {
    trap 'c=$?; rm -f $tmp; exit $c' EXIT ERR HUP INT TERM
    tmp=`mktemp /tmp/selectmail.XXXXXX`
}
