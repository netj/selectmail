#!/usr/bin/env bash
Id="SelectMail $VERSION" # (http://netj.org/selectmail)
# KeepMail -- remove and extract messages from mailboxes
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2007-02-24

. "`dirname "$0"`/$EXEDIR"/common

keepmail() {
    local mode=keep output= spread=
    # process options
    local o=
    while getopts "ho:ym" o; do
        case "$o" in
            h) mode=help ;;
            o) output=$OPTARG ;;
            y) spread=yearly ;;
            m) spread=monthly ;;
            *) see_usage ;;
        esac
    done
    shift $(($OPTIND - 1))

    set -e
    case "$mode" in
        help) # show usage
        cat <<-EOF
	$Id
	$Name -- remove and extract messages from mailboxes
	
	Usage: $Name [-ym] [-o <archive>] <pattern> <mailbox>...
	  pattern:
	    all pattern that Mutt recognizes is allowed, see muttrc(5)
	  mailbox:
	    one or more mailboxes you want to work on
	  archive:
	    mailbox you want to store unmatched messages if specified
	
	Examples:
	  $Name -o ~/Mail/INBOX.gz "~r <3m" =.Inbox
	    to keep mails received within 3 months in =.Inbox and archive others
	  $Name "~r <2w" =.Trash
	    to delete mails in =Trash older than 2 weeks
	  $Name "~r \`date -r timestamp +%d/%m/%Y\`-" =.News
	    to keep mails received after the timestamp file was touched in =.News
	  $Name -y -o ~/Mail/lists-%Y.gz "~r <30d" =.lists
	    to keep mails received within 30 days in =.lists and archive others
            spread over years, e.g. ~/Mail/lists-2007.gz.
	
	EOF
        ;;
        keep) # keep messages
        # validate arguments
        [ $# -gt 0 ] || see_usage
        local patt=$1; shift
        [ -n "$patt" ] || { see_usage "no pattern specified"; }
        [ $# -gt 0 ] || { see_usage "no mailbox specified"; }
        # decide whether to extract or delete
        if [ -n "$output" ]; then
            if [ -n "$spread" ]; then
                # spread
                case "$spread" in
                    yearly) spread() {
                        local from=$1 y= o=
                        for y in $(seq `date +%Y` -1 1900); do
                            o=`sed <<<"$output" -e "s/%Y/$y/g"`
                            echo -n "spreading '~d 01/01/$y-' to $o"
                            mvmsgs "~d 01/01/$y-" "$o" "$from"
                            echo
                            [ -s "$from" ] || break
                        done
                    } ;;
                    monthly) spread() {
                        local from=$1 y= m= m0=`date +%m` o=
                        for y in $(seq `date +%Y` -1 1900); do
                            for m in $(seq $m0 -1 1); do
                                m=`printf %02d $m`
                                o=`sed <<<"$output" -e "s/%Y/$y/g" -e "s/%m/$m/g"`
                                echo -n "spreading '~d 01/$m/$y-' to $o"
                                mvmsgs "~d 01/$m/$y-" "$o" "$from"
                                echo
                                [ -s "$from" ] || break
                            done
                            [ -s "$from" ] || break
                            m0=12
                        done
                    } ;;
                    *)
                    err "spread $spread not implemented :("
                    return 4
                    ;;
                esac
                keep() {
                    local tmp=`mktemp "$1.keepmail.XXXXXX"`
                    [ -n "$tmp" ] || return 8
                    # extract to $tmp first
                    echo -n "extracting '!($patt)' from $@"
                    mvmsgs "!($patt)" "$tmp" "$@"
                    echo
                    # spread
                    spread "$tmp"
                    # clean up
                    [ -s "$tmp" ] || rm -f "$tmp"
                }
            else
                # move
                keep() {
                    local from=
                    for from in "$@"; do
                        echo -n "moving '!($patt)' from $from to $output"
                        mvmsgs "!($patt)" "$output" "$from"
                        echo
                    done
                }
            fi
        else
            # delete
            keep() {
                local from=
                for from in "$@"; do
                    echo -n "deleting '!($patt)' from $from"
                    rmmsgs "!($patt)" "$from"
                    echo
                done
            }
        fi
        # do the work
        keep "$@"
        ;;
    esac
}

Mutt() {
    local from=$1 cmd=$2
    screen -D -m \
    mutt -z -f "$from" \
         -e 'unset confirmcreate confirmappend mark_old' \
         -e 'set delete quit' \
         -e 'push "'"$cmd"'"'
}
rmmsgs() {
    local patt=$1 from=; shift
    for from in "$@"; do
        Mutt "$from" "<delete-pattern>$patt<Enter><quit>"
    done
}
mvmsgs() {
    local patt=$1 to=$2 from=; shift 2
    # sanitize parameters
    local opt=
    case "$to" in
        *.gz|*.bz2) # compressed folders
        # XXX: compressed folders need mbox_type=mbox (2007-03)
        opt="set mbox_type=mbox"
        ;;
        */) # Maildir
        opt="set mbox_type=Maildir"
        to="`dirname "$to"`/`basename "$to"`"
        ;;
    esac
    opt=${opt:+<enter-command>$opt<Enter>}
    mkdir -p "`dirname "$to"`" || err "cannot create \`$to'"
    # let Mutt handle the rest
    local tmp=`mktemp "$to.XXXXXX"`
    for from in "$@"; do
        Mutt "$from" "<tag-pattern>$patt<Enter><tag-prefix><copy-message>${tmp// / }<Enter><delete-pattern>$patt<Enter><quit>"
    done
    Mutt "$tmp" "<delete-pattern>!($patt)<Enter><quit>"
    Mutt "$tmp" "<tag-pattern>.<Enter>$opt<tag-prefix><save-message>${to// / }<Enter><quit>"
    rm -f "$tmp"
}

"$Name" "$@"
