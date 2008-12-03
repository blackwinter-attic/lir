#! /usr/bin/perl

###############################################################################
#                                                                             #
# lir.pl -- query lir indexes (console version)                               #
#                                                                             #
# A component of lir, the experimental information retrieval environment.     #
#                                                                             #
# Copyright (C) 2004-2008 Jens Wille                                          #
#                                                                             #
# lir is free software: you can redistribute it and/or modify it under the    #
# terms of the GNU General Public License as published by the Free Software   #
# Foundation, either version 3 of the License, or (at your option) any later  #
# version.                                                                    #
#                                                                             #
# lir is distributed in the hope that it will be useful, but WITHOUT ANY      #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   #
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more       #
# details.                                                                    #
#                                                                             #
# You should have received a copy of the GNU General Public License along     #
# with lir. If not, see <http://www.gnu.org/licenses/>.                       #
#                                                                             #
###############################################################################

use strict;
use warnings;

use MLDBM qw(DB_File Storable);
use Fcntl;
use File::Basename;

use lib '../lib';
use LIR::GlobalConfig qw(%DB);

my $usage = "usage: $0 [-h|--help] { -q <query> | -d <docnum> } <index.dbm>";
my $help  = "test access on lir indexes";
die "$help\n$usage\n" if $ARGV[0] && $ARGV[0] =~ m{\A(?:-h|--help)\z};
die "$usage\n" unless @ARGV == 3;
die "only querying and display supported!\n$usage\n" unless $ARGV[0] =~ m{\A(?:-q|-d)\z};

my $idxdbm = $ARGV[2];
die "not a dbm file $idxdbm!\n$usage\n" unless $idxdbm =~ m{\.dbm\z};
die "can't read $idxdbm!\n$usage\n" unless -r $idxdbm;

my ($id) = (basename $idxdbm =~ m{\A(.*?)_});
my $cat_tit = '__%' . ($DB{$id}->{'cat_tit'} || '020') . '%__';

my %index = ();
tie(%index, 'MLDBM', $idxdbm, O_RDONLY) or die "can't tie to $idxdbm: $!";

if    ($ARGV[0] eq '-q') {
  my $query = $ARGV[1];

  my @terms = sort keys %index; #die "@terms[-100..0]\n";
  my @matching_terms = grep { $_ =~ m{\b$query\b} } @terms;

  foreach my $term (sort @matching_terms) {
    my $termref = $index{$term};
    next unless $termref;

    my @docs = sort keys %{$termref};
    if    (@docs < 3) {
      my $d_string = '';
      foreach my $doc (@docs) {
        $d_string .= " $doc (\"$index{$cat_tit}->{$doc}\")";
      }
      print "$term:$d_string\n";
    }
    elsif (@docs < 10) {
      my $d_string = '';
      foreach my $doc (@docs) {
        my $w_string = '';
        foreach my $w (sort keys %{$termref->{$doc}}) {
          $w_string .= " $w: $termref->{$doc}->{$w};";
        }
        $d_string .= " $doc \{$w_string\}";
      }
      print "$term:$d_string\n"
    }
    else {
      print "$term: #", scalar @docs, "\n";
    }
  }
}
elsif ($ARGV[0] eq '-d') {
  my $record = $ARGV[1];

  my $recordref = $index{$record};
  foreach my $cat (sort keys %{$recordref}) {
    if (ref $recordref->{$cat} eq 'HASH') {
      my @keys = ();
      foreach my $key (sort keys %{$recordref->{$cat}}) {
        push(@keys, "$key \{$recordref->{$cat}->{$key}\}");
      }
      print "$cat: ", join('; ', @keys), "\n";
    }
    else {
      print "$cat: $recordref->{$cat}\n";
    }
  }
}

untie %index;
