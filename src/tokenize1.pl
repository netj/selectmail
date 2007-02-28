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
sub emit_all {
    my $string = shift;
    my $tag = shift || "";
    emit("$tag$_") foreach eval { tokenize($string) };
}


my $line;
do {
    # begin of msg
    restart();
    # head
    my $name;
    my $content;
    while (defined ($line = <>)) {
        chomp $line;
        utf8::decode($line);
        if ($line =~ /^\s+(.*)$/) {
            # continued
            $content .= $1;
        } elsif ($line =~ /^([^:]+):\s*(.*)$/) {
            # flush previous header if existed
            emit_all($content, "$name:") if defined $name;
            # start a new header
            $name = lc $1;
            $content = $2;
        } elsif ($line =~ /^$/) {
            # flush previous header if existed
            emit_all($content, "$name:") if defined $name;
            last;
        } else {
            warn "malformed header line";
        }
    }
    # body
    while (defined ($line = <>)) {
        last if $line =~ /^/;
        utf8::decode($line);
        emit_all($line);
    }
    # end of msg marker
    print "#\n";
} while (defined $line);
