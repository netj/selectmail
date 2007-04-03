#!/usr/bin/env bash
Id="SelectMail $VERSION" # (http://netj.org/selectmail)
# ClassMail -- study and guess the class of given message
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2007-02-14

set -e
. "`dirname "$0"`/$EXEDIR"/common

# default values
ConfigDir=${SELECTMAILDIR:-~/.selectmail}

classmail() {
    # parse options
    local mode=list class=
    while getopts "hilmt:" o; do
        case $o in
            h) mode=help                ;;
            i) mode=stats               ;;
            l) mode=tokens              ;;
            t) mode=test class=$OPTARG  ;;
            m) mode=mark                ;;
            *) see_usage                ;;
        esac
    done
    shift $(($OPTIND - 1))
    case $mode in
        help) # show usage
        cat <<-EOF
	$Id
	$Name -- guess the class of given message
	
	usage:
	  $Name <some.msg
	    guess the message's probability for each class
	  $Name -m <some.msg
	    add X-Category header to the message
	    (might be useful for procmail's :0f)
	  $Name -t spam <some.msg
	    test whether the given class is the most probable one
	  $Name -l <some.msg
	    list tokens that are being considered (not implemented)
	  $Name -i
	    show number of messages and tokens for each class
	  $Name -h
	    show this help message
	
	EOF
        ;;
        stats) # show statistics
        hr() { echo "-------------------------------"; }
        local fmt=" %-10s|%7d |%9d \n"
        hr
        printf    " %-10s|%7s |%9s \n" category nrmsg nrtok
        hr
        local c=
        for c in $Categories; do
            printf "$fmt" $c \
                `echo -e "#\n\$" | eval counts lookup $(db_path $c)`
        done
        hr
        ;;
        tokens)
        # TODO enumerate tokens
        echo "Not implemented yet :(" >&2
        exit 65
        ;;
        list) # each category's probability
        cat "$@" | guess |
        while read c p; do
            printf "%-10s %.10e\n" $c $p
        done
        ;;
        test) # whether belongs to some category
        [ "`cat "$@" | guess | head -1 | cut -f 1`" = "$class" ]
        ;;
        mark) # add X-Category: header
        need_tmp
        cat "$@" | tee $tmp | guess | {
            local hdr=
            while read c p; do
                hdr="${hdr:+$hdr; }$c=$p"
            done
            formail -i "X-Category: $hdr" <$tmp
        }
        ;;
    esac
}

guess() {
    tokenize | grep -v '^#$' | eval counts lookup `db_path $Categories` |
    class-$ClassMethod `eval counts lookup $(db_path $Categories) <<<'#'` |
    label $Categories | sort -rgk2
}

label() {
    local labels=
    labels=("$@")
    set `cat` ""
    local l=
    for l in "${labels[@]}"; do
        echo -e "$l\t$1"
        shift
    done
}


studymail() {
    local c=
    # TODO: usage
    for c in $Categories; do
        echo -n "$c: studying..."
        local memory="$ConfigDir/$c.memory/"
        # TODO: extract new ones since timestamp from $mailboxes
        #keepmail -o $tmp -r $timestamp `cat "$ConfigDir/$c.mailboxes"`
        # TODO: learn them
        #learnmail $c $memory
        learnmail $c `cat "$ConfigDir/$c.mailboxes"`
        # TODO: extract old ones from memory
        # TODO: forget them
        #forgetmail $c $memory
        echo "done"
    done
}


memorize() {
    local mode=$1; shift
    local c=$1; shift
    if [ -n "$c" ] && grep -q "\<$c\>" <<<"$Categories"; then
        need_tmp
        tokenize "$@" | tee $tmp | eval counts $mode `db_path $c` &&
        eval counts $mode -`wc -l $tmp` \
            `db_path $c` <<<'$' # change in number of tokens
    else
        cat <<-EOF
	$Id
        $Name -- remember given messages as an example of some class
	usage: $Name ham <good.msg
	       $Name spam <bad.msg
	EOF
        exit 1
    fi
}
learnmail()  { memorize more "$@"; }
forgetmail() { memorize less "$@"; }


load_config() {
    # create default config if not exists
    [ -d "$ConfigDir" ] || mkdir -p "$ConfigDir" ||
        { err "$ConfigDir: cannot prepare config directory"; exit 4; }
    [ -f "$ConfigDir/config" ] || cp -f "$Base/config" "$ConfigDir/" ||
        { err "$ConfigDir: cannot prepare default config"; exit 4; }
    [ -n "`categories`" ] || touch "$ConfigDir"/{ham,spam}.mailboxes ||
        { err "$ConfigDir: cannot prepare default categories"; }

    # read config
    . "$ConfigDir/config"
    Categories=`categories`

    # sanitize config
    if ! [ -x "$Base/class-$ClassMethod" ]; then
        err "$ClassMethod: No such method available"
        exit 2
    fi
}

categories() {
    (cd "$ConfigDir" && ls *.mailboxes 2>/dev/null | sed -e 's/.mailboxes$//')
}
db_path() {
    local c=
    for c in "$@"; do
        echo "'${ConfigDir//"'"/"'\\''"}/$c.db'"
    done
}

env_provides mutt
load_config
"$Name" "$@"
