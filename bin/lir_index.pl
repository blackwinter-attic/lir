#! /usr/bin/perl

###############################################################################
#                                                                             #
# lir_index.pl -- create/update indexes for lir.pl (console version)          #
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

use Encode qw(from_to);

use Getopt::Long;

use MLDBM qw(DB_File Storable);
use Fcntl;
use IO::Handle;

use lib '../lib';

use LIR::GlobalConfig qw(%DB);
use LIR::SVD;

STDOUT->autoflush(1);

# parse command line arguments
my ($gid,  $db_id, $db_file, $rvl_file, $with_svd, $svd_level, $dir, $force)
 = ('lir', 'lir',  '',       '',        0,         100,        '.',  0);
my @sto_files = ();

my $usage = <<HERE_USG;
usage:
    $0 [--id=<db-id>] --db=<source.db> {--sto=<source.sto>,...|<source.sto>,...} [--rvl=<file.rvl>] [--with-svd --svd-level=<svd-level>] [--dir=<target-dir>] [--gid=<group-id>] [--force]
    $0 [-h|--help]
HERE_USG

my $help  = <<HERE_HELP;
create/update indexes for lir.pl

$usage

options:
    -h, --help                display this help and exit

    --id=<db-id>              database id corresponding to db configuration (default: \'$db_id\')
    --db=<source.db>          database source (*.db)
    --sto=<source.sto>,...    index source (*.sto) (comma separated list)
                              (additionally, all non-option arguments will be treated as sto files)
                              NOTE: sto filenames need to be of format "<db-id>_<ranking-id>..."
    --rvl=<file.rvl>          rvl file to calculate "better" term frequencies (*.rvl)
    --with-svd                additionally create svd weights (default: without svd)
                              NOTE: VERY time consuming!!!
    --svd-level=<svd-level>   level of "accuracy" for svd (default: $svd_level)
    --dir=<target-dir>        directory to create indexes in (default: \'$dir\')
    --gid=<group-id>          group to own index files (default: \'$gid\')
    --force                   force overwriting of existing index files (default: don\'t overwrite)

    all non-option arguments will be treated as sto files
HERE_HELP

die "$usage\n" unless @ARGV;
die "$help\n"  if     $ARGV[0] =~ m{\A(?:-h|--help)\z};

GetOptions('id=s'        => \$db_id,
           'db=s'        => \$db_file,
           'sto=s'       => \@sto_files,
           'rvl=s'       => \$rvl_file,
           'with-svd'    => \$with_svd,
           'svd-level=i' => \$svd_level,
           'dir=s'       => sub { ($dir = $_[1]) =~ s{/\z}{}; },
           'gid=s'       => \$gid,
           'force'       => \$force,
           '<>'          => sub { push(@sto_files, @_); })
  or die "$usage\n";

die "no such db: $db_id!\n$usage\n"             unless defined $DB{$db_id};
die "can't write to directory: $dir!\n$usage\n" unless -w $dir;
die "no sto files supplied!\n$usage\n"          unless @sto_files;
die "no db file supplied!\n$usage\n"            unless $db_file;
die "not a db file: $db_file!\n$usage\n"        unless $db_file =~ m{\.db\z};
die "can't read db file: $db_file!\n"           unless -r $db_file;

my $cat_id  = $DB{$db_id}->{'cat_id'};
my $cat_tit = $DB{$db_id}->{'cat_tit'};

# tie index files (overwrite if already existing)
my $index_file   = $dir . '/' . $DB{$db_id}->{'idx_file'};
my $records_file = $dir . '/' . $DB{$db_id}->{'db_file'};

my %index   = ();
my %records = ();

my ($overwrite_index, $overwrite_records) = (0, 0);

if (-r $index_file) {
  die "index file $index_file already exists! not overwriting...\n$usage\n" unless $force;

  warn "index file $index_file already exists! overwriting...\n";
  $overwrite_index = 1;
}

tie(%index, 'MLDBM', $index_file, O_WRONLY|O_EXCL|O_CREAT, 0640)
  or die "can't tie to $index_file: $!\n";
%index = () if $overwrite_index;

if (-r $records_file) {
  die "records file $records_file already exists! not overwriting...\n$usage\n" unless $force;

  warn "records file $records_file already exists! overwriting...\n";
  $overwrite_records = 1;
}

tie(%records, 'MLDBM', $records_file, O_WRONLY|O_EXCL|O_CREAT, 0640)
  or die "can't tie to $records_file: $!\n";
%records = () if $overwrite_records;

my %temp_index   = ();
my %temp_records = ();
my %record       = ();
my %doc_terms    = ();
my %rvl          = ();
my %seen         = ();

# read in rvl
if (-r $rvl_file) {
  print "\nreading rvl file: $rvl_file...\n";
  open(RVL, "< $rvl_file") or die "can't open $rvl_file: $!\n";
  my %temp = ();
  while (my $line = <RVL>) {
    next unless $line =~ m{\A[ *]*\d+ (.*?) -> (.*?) <};
    push(@{$temp{$2}}, $1) unless $seen{"$2:$1"}++;
  }
  close RVL;

  foreach my $t (keys %temp) {
    my @ts = ($t);
    push(@ts, @{$temp{$t}});
    my $s = join('|', map { quotemeta() } @ts);
    my $pat = qr{\b($s)\b};

    $rvl{$t} = $pat;
  }

  print "...done\n";
}
else {
  die "can't read rvl file: $rvl_file!\n" if $rvl_file;
}

# read in db
print "\nprocessing db file: $db_file...\n";

my ($i, $j) = (0, 1);
open(DB, "< $db_file") or die "can't open $db_file: $!\n";

while (my $line = <DB>) {
  $line =~ s{\s*\r?\n}{};
  next unless $line;

  # record separator: &&&
  unless ($line eq '&&&') {
    $j = 0;
    from_to($line, $DB{$db_id}->{'db_enc'}, "utf8");
    $line =~ s{<}{&lt;}g;
    $line =~ s{>}{&gt;}g;
    $line =~ s{&}{&amp;}g;

    #               category:   content
    $line =~ m{\A\s*(.*?)\s*:\s*(.*)\z};
    next unless defined $1 && defined $2;

    $record{$1} = $2;
  }
  else {
    ++$i;
    $j = 1;
    foreach my $key (keys %record) {
      $temp_records{$record{$cat_id}}->{$key} = $record{$key};
    }
    %record = ();
  }

  print "$i " if $j && $i % 100 == 0;
}
print "\n$i records read\n";
close DB;

# read in sto's
my @ranks = qw(x);  # for svd
my @all_sto_files = split(',', join(',', @sto_files));
foreach my $sto (sort @all_sto_files) {
  print "\nprocessing sto file: $sto...\n";
  unless (-r $sto) { warn "can't read sto file! skipping...\n"; next; }

  my ($i, $j) = (0, 1);
  open(STO, "< $sto") or die "can't open $sto: $!\n";

  my ($r) = ($sto =~ m{\A.*/${db_id}_(.)});
  unless ($DB{$db_id}->{$r}) { warn "no such ranking id: $r! skipping sto file...\n"; next; }
  #push(@ranks => $r);

  while (my $line = <STO>) {
    $line =~ s{\s*\r?\n}{};
    next unless $line;

    ++$i;
    from_to($line, $DB{$db_id}->{'idx_enc'}, "utf8");

    #                                   id   */;    terms
    my ($id, $terms) = ($line =~ m{\A\s*(.*?)[*;]\s*(.*)\z});
    next unless defined $id && $terms;

    $id = $DB{$db_id}->{'id2rec'}->($id);

    #                     term       {weight}#/;
    while ($terms =~ m/\s*(.*?)\s*(?:{(.*?)})?[#;]/g) {
      next unless $1;#&& defined $2;

      my $t = $1;

      if (defined $2) {
        my $w = $2;
        $temp_index{$t}->{$id}->{$r} = $w;
        $doc_terms{$id}->{$r}->{$t}  = $w;
      }

      my $f = freq($t, $id);
      $temp_index{$t}->{$id}->{'x'} = $f;
      $doc_terms{$id}->{'x'}->{$t}  = $f;
    }
    print "$i " if $j && $i % 100 == 0;
  }
  print "\n$i records read\n";
  close STO;
}
die "index empty!\n" unless %temp_index;

# svd
if ($with_svd) {
  print "\ncreating svd entries...\n";

  my @terms = sort keys %temp_index;
  my @docs  = sort keys %doc_terms;
  print "[", scalar @terms, ", ", scalar @docs, "]\n";

  foreach my $r (@ranks) {
    #print "$r ";
    my @mat = (); my $i = 0;
    foreach my $t (@terms) {
      my @td = (); my $j = 0;
      foreach my $d (@docs) {
        my $val = exists $temp_index{$t}->{$d} ? $temp_index{$t}->{$d}->{$r} || 0 : 0;

        push(@td => $val);
        last if ++$j > 50;
      }
      push(@mat => \@td);
      last if ++$i > 50;
    }

    my $mat = LIR::SVD->new(@mat);
    my $svd = $mat->do_svd($svd_level);#->to_array;
    print $mat, $svd; die "\n";

    for (my $t = 0; $t <= $#terms; $t++) {
      for (my $d = 0; $d <= $#docs; $d++) {
        $temp_index{$terms[$t]}->{$docs[$d]}->{"s$r"} = $mat[$t]->[$d];
      }
    }
  }
  print "\n";
}

# additional entries for index and records
print "\ninserting additional entries for index and records...\n";
my $cat_string = '__%' . $cat_tit . '%__';
foreach my $doc (keys %doc_terms) {
  $temp_index{$cat_string}->{$doc} = $temp_records{$doc}->{$cat_tit};

  foreach my $r (keys %{$doc_terms{$doc}}) {
    $temp_records{$doc}->{"xx$r"} = \%{$doc_terms{$doc}->{$r}};
  }
}

# create indexes
print "\nwriting index files...\n";

print "-> $index_file\n";
%index = %temp_index;
untie %index;

print "-> $records_file\n";
%records = %temp_records;
untie %records;

print "...done\n";

qx{chgrp $gid $index_file $records_file};

# calculate term frequency
sub freq {
  my ($t, $id) = @_;

  my $pat = $rvl{$t} || qr{\b($t)\b};
  my $f = 0;

  foreach my $value (values %{$temp_records{$id}}) {
    while ($value =~ /$pat/g) { $f++; }
  }

  $f ||= 1;
  # the term "occurs" at least once, otherwise we wouldn't be here, now would we

  return $f;
}
