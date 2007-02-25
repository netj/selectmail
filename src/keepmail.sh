#!/usr/bin/env bash
Id="SelectMail $VERSION" # (http://netj.org/selectmail)
# KeepMail -- remove and extract messages from mailboxes
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2007-02-24

. "`dirname "$0"`/$EXEDIR"/common

keepmail() {
    local mode=keep output=
    # process options
    local o=
    while getopts "ho:" o; do
        case "$o" in
            h) mode=help ;;
            o) output=$OPTARG ;;
            # TODO: spread yearly/monthly option
            *) see_usage ;;
        esac
    done
    shift $(($OPTIND - 1))

    case "$mode" in
        help) # show usage
        cat <<-EOF
	$Id
	$Name -- remove and extract messages from mailboxes
	
	Usage: $Name [-o <archive>] <pattern> <mailbox>...
	  pattern:
	    all pattern that Mutt recognizes is allowed, see muttrc(5)
	  mailbox:
	    one or more mailboxes you want to work on
	  archive:
	    mailbox you want to store unmatched messages if specified
	
	Examples:
	  $Name "~r <3m" =.Inbox -o ~/Mail/INBOX.gz
	    to keep mails received within 3 months in =.Inbox and archive others
	  $Name "~r <2w" =.Trash
	    to delete mails in =Trash older than 2 weeks
	  $Name "~r \`date -r timestamp +%d/%m/%Y\`-" =.News
	    to keep mails received after the timestamp file was touched in =.News
	
	EOF
        ;;
        keep) # keep messages
        local patt=$1; shift
        # validate arguments
        [ -n "$patt" ] || { see_usage "no pattern specified"; }
        [ $# -gt 0 ] || { see_usage "no mailbox specified"; }
        # decide whether to extract or delete
        if [ -n "$output" ]; then
            keep() { mvmsgs "! ($patt)" "$1" "$output"; }
        else
            keep() { rmmsgs "! ($patt)" "$1"; }
        fi
        # work on each mailbox
        local mbox=
        for mbox in "$@"; do
            keep "$mbox"
        done
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
    local patt=$1 from=$2
    Mutt "$from" "<delete-pattern>$patt<Enter><quit>"
}
mvmsgs() {
    local patt=$1 from=$2 to=$3
    local tmp=`mktemp "$to.XXXXXX"`
    Mutt "$from" "<tag-pattern>$patt<Enter><tag-prefix><copy-message>$tmp<Enter><delete-pattern>$patt<Enter><quit>"
    Mutt "$tmp" "<delete-pattern>.<Enter><undelete-pattern>$patt<Enter><tag-pattern>.<Enter><tag-prefix><save-message>$to<Enter><quit>"
    rm -f "$tmp"
}

"$Name" "$@"
