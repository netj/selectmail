#!/usr/bin/perl -wT
# Perl implementation of naive Bayesian categorization
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2007-02-15

# some parameters
my $d_sig = 0;
my $nrfeats = 15;

use strict;

my @nrmsgs = map { $_ || 1 } @ARGV; @ARGV = ();
my $n = @nrmsgs;

unless ($n > 1) {
    print <<EOF;
Usage: Supply size of each class as arguments, and for stdin,
       supply each feature's counts for every class as a single line.
EOF
    exit 1;
}

my $neutral = 1/$n;
my @cats = 0 .. ($n - 1);
my $d_max = 2*(1 - $neutral);
my @p_unknown = map { 1/($_+1) } @nrmsgs;

my @rates_sig;
my @ds;
while (<>) {
    my @counts = split /\s+/;
    # convert counts to ratios of each feature
    my @rates = map { $counts[$_]/$nrmsgs[$_] || $p_unknown[$_] } @cats;
    # compute distance
    my $d = 0;
    $d += $_ foreach map { abs($_ - $neutral) } @rates;
    $d /= $n;
    # collect significant features
    if ((my $d_ratio = $d / $d_max) >= $d_sig) {
        push @rates_sig, \@rates;
        push @ds, $d_ratio;
    }
}

# limit the number of participating features
@rates_sig = map { $rates_sig[$_] }
            sort { $ds[$b] cmp $ds[$a] } (0 .. $#rates_sig);
splice @rates_sig, $nrfeats if @rates_sig > $nrfeats;

# TODO: verbose output
#print STDERR join("\t", map {sprintf "%6f", $_} @$_) . "\n" foreach @rates_sig;

# compute combined probabilities of features
my @prob = ratios(@nrmsgs);
for my $rates (@rates_sig) {
    $prob[$_] *= $$rates[$_] foreach @cats;
}

# normalize each probability so the sum becomes 1
@prob = ratios(@prob);

# output
print join "\t", @prob;
print "\n";



# vocabularies

sub min { my $m = shift; foreach (@_) { $m = $_ if $_ < $m; } $m }

sub ratios {
    my $total = 0;
    $total += $_ foreach @_;
    $total = 1 if $total == 0;
    map { $_ / $total } @_
}
