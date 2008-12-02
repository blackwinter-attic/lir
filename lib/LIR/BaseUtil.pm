###############################################################################
#                                                                             #
# BaseUtil.pm -- _basic_ utilities                                            #
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

package LIR::BaseUtil;

use strict;
use warnings;

use Carp qw(croak);

### variables + subroutines to export

require Exporter;

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = (
  subs => [qw(
    mtime tie_index untaint_var
  )],
  cons => [qw(
    FALSE TRUE $MY_MODULES
  )]
);
our @EXPORT_OK   = map(@{$_} => values %EXPORT_TAGS);

### /variables + subroutines to export/

### other modules to _use_

use DateTime;

use MLDBM qw(DB_File Storable);
use Fcntl;

### /other modules to _use_/

### constants

use constant FALSE => 0;
use constant TRUE  => !FALSE;

# my modules
our $MY_MODULES = 'GlobalConfig|LirConfig|IndexConfig|BaseUtil|ExtUtil|CGI|DB';

### /constants/

### subroutines

# <sub mtime>
# get time and date of last modification
sub mtime {
  my @files = @_ ? @_ : ($0, map { $_ = 'LIR/' . $_ . '.pm' } split('\|', $MY_MODULES));
                             # maybe we should exclude Config.pm!?
                             # => grep { $_ !~ m{^(Config)$} }

  # relying on EPOCH (practically) always being 10-digit
  # and thus being able to simply use string comparison:
  my $newest = (sort map((stat)[9] => @files))[-1];

  my $dt = DateTime->from_epoch('epoch' => $newest);
  $dt->set_time_zone('local');

  my $mtime = $dt->ymd('/') . ' ' . $dt->hms . ' ' . $dt->time_zone_short_name;
  return lc($mtime);
}
# </sub mtime>

# <sub tie_index>
# tie index file to hash
sub tie_index {
  my ($indexref, $file, $create) = @_;

  if (defined $file) {
    return if tied %{$indexref};

    if (defined $create) {
      tie(%{$indexref}, 'MLDBM', $file, O_WRONLY|O_EXCL|O_CREAT, 0640)
        or croak "can't tie to $file: $!\n";
    }
    else {
      return unless -r $file;

      tie(%{$indexref}, 'MLDBM', $file, O_RDONLY)
        or croak "can't tie to $file: $!\n";
    }

    tied(%{$indexref})->DumpMeth('portable');
  }
  else {
    return unless tied %{$indexref};
    untie %{$indexref};
  }
}
# </sub tie_index>

# <sub untaint_var>
# untaint variable
sub untaint_var {
  my ($var, $pat) = @_;

  return $1 if $var =~ m{\A($pat)\z};

  croak "bad data: $var";
}
# </sub untaint_var>

### /subroutines/

1;
