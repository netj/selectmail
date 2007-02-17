#!/usr/bin/perl -wT
# single message tokenizer (works best with Mutt w/ pipe_decode)
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2007-02-14

use 5.8.0;
use strict;

our $URLchar = '[A-z0-9]';
sub tokenize {
    my @tokens;
    # TODO improve tokenizing rule
    for my $s (@_) {
        while ($s =~ m#$URLchar+([-_.:@/?+=&\#]$URLchar*)+|\p{Letter}+#g) {
            my $token = $&;
            push @tokens, $token;
            # sub-tokens in urls
            while ($token =~ m#$URLchar+([-_\.]$URLchar*)+#g) {
                push @tokens, $&;
            }
        }
    }
    @tokens
}


my %token_history;
sub restart {
    %token_history = ();
}
sub emit {
    foreach (@_) {
        utf8::encode($_);
        next if $token_history{$_};
        print "$_\n";
        $token_history{$_}++;
    }
}



while (<>) {
    restart();
    # head
    my $name;
    my $content;
    while (<>) {
        utf8::decode($_);
        last if /^$/;
        if (/^\s+(.*)$/) {
            # continued
            $content .= $1;
        } elsif (/^([^:]+):\s*(.*)$/) {
            # flush previous header if existed
            if (defined $name) {
                emit("$name:$_") foreach eval { tokenize($content) };
            }
            # start a new header
            $name = lc $1;
            $content = $2;
        } else {
            # malformed header line
        }
    }

    # body
    while (<>) {
        last if /^/;
        utf8::decode($_);
        emit($_) foreach eval { tokenize($_) };
    }

    # end of msg marker
    print "#\n";
}
