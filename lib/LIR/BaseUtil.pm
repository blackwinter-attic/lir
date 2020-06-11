###############################################################################
#                                                                             #
# BaseUtil.pm -- Basic utilities.                                             #
#                                                                             #
# A component of LIR, the experimental information retrieval environment.     #
#                                                                             #
# Copyright (C) 2004-2020 Jens Wille                                          #
#                                                                             #
# LIR is free software: you can redistribute it and/or modify it under the    #
# terms of the GNU Affero General Public License as published by the Free     #
# Software Foundation, either version 3 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# LIR is distributed in the hope that it will be useful, but WITHOUT ANY      #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   #
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for     #
# more details.                                                               #
#                                                                             #
# You should have received a copy of the GNU Affero General Public License    #
# along with LIR. If not, see <http://www.gnu.org/licenses/>.                 #
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
    tie_index untaint_var
  )],
  cons => [qw(
    FALSE TRUE
  )]
);
our @EXPORT_OK   = map(@{$_} => values %EXPORT_TAGS);

### /variables + subroutines to export/

### other modules

use DateTime;

use MLDBM qw(DB_File Storable);
use Fcntl;

### /other modules/

### constants

use constant FALSE => 0;
use constant TRUE  => !FALSE;

### /constants/

### subroutines

# <sub tie_index>
# Tie index file to hash
sub tie_index {
  my ($indexref, $file, $create) = @_;

  if (defined $file) {
    return if tied %{$indexref};

    if (defined $create) {
      tie(%{$indexref}, 'MLDBM', $file, O_WRONLY|O_EXCL|O_CREAT, 0640)
        or croak "Can't tie to $file: $!\n";
    }
    else {
      return unless -r $file;

      tie(%{$indexref}, 'MLDBM', $file, O_RDONLY)
        or croak "Can't tie to $file: $!\n";
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
# Untaint variable
sub untaint_var {
  my ($var, $pat) = @_;

  return $1 if $var =~ m{\A($pat)\z};

  croak "Bad data: $var";
}
# </sub untaint_var>

### /subroutines/

1;
