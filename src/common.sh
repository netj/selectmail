#!/usr/bin/env bash
# vocabularies

Name=`basename "$0"`
Base="`dirname "$0"`/$EXEDIR"
Base=`cd "$Base" && pwd || echo "$Base"`
PATH="$Base:$PATH"

env_provides() {
    local what=
    for what in "$@"; do
        case "$what" in
            mutt)
            # mutt version
            local mutt_version=$(set `mutt -v | head -1` ""; echo $2)
            case "$mutt_version" in
                1.5*) true ;;
                *)    err "no supported mutt found"; return 1 ;;
            esac
            ;;
            compressed_folders)
            # compressed folders
            if mutt -v | grep -q '\+COMPRESSED'; then
                true
            else
                err "mutt must be able to handle compressed folders"
                return 2
            fi
            ;;
            *) return 1 ;;
        esac
    done
    true
}

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
