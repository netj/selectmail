#!/usr/bin/perl -wT
# simple count database managing tool
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2007-02-14

use strict;
use DB_File;

my $action = {
    lookup => sub {
        with_stdin_dbs(
            sub {
                my $t = shift;
                print join " ", map { exists $_->{$t} ? $_->{$t} : 0 } @_;
                print "\n";
            }, @_
        );
    },
    more => sub {
        my $delta = 1; shift, $delta = $1 if $_[0] =~ /^-(\d+)$/;
        with_stdin_dbs(
            sub {
                my $t = shift;
                foreach (@_) {
                    $_->{$t} = 0 unless exists $_->{$t};
                    $_->{$t} += $delta;
                }
            }, @_
        );
    },
    less => sub {
        my $delta = 1; shift, $delta = $1 if $_[0] =~ /^-(\d+)$/;
        with_stdin_dbs(
            sub {
                my $t = shift;
                foreach (@_) {
                    $_->{$t} -= $delta;
                    delete $_->{$t} unless $_->{$t} > 0;
                }
            }, @_
        );
    }
}->{shift @ARGV || ""};

if (defined $action) {
    $action->(@ARGV);
} else {
    my $cmd = $0;
    $cmd =~ s:.*/::;
    print <<USAGE;
Usage: $cmd lookup <db> ...
       $cmd more [-#] <db> ...
       $cmd less [-#] <db> ...
USAGE
    exit 1;
}


sub with_stdin_dbs {
    my $job = shift;
    my @dbs = map { tie my %db, 'DB_File', $_; \%db } @_;
    while (<STDIN>) {
        chomp;
        $job->($_, @dbs);
    }
}
