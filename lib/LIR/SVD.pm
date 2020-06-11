###############################################################################
#                                                                             #
# SVD.pm -- Singular value decomposition for LIR.                             #
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

package LIR::SVD;

use strict;
use warnings;

use PDL;
use PDL::Matrix;
use PDL::NiceSlice;

# Inherit from PDL::Matrix
our @ISA         = qw(PDL::Matrix);
our %EXPORT_TAGS = ('Func' => []);

# This module's version
our $VERSION = '0.1';

# <constructor>
# Create LIR::SVD object
sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;

  my $self  = mpdl(@_);
  bless $self => $class;

  return $self;
}
# </constructor>

### object methods

# <sub do_svd>
# Perform SVD of given "accuracy"
#
# Usage:
#   $svd = $mat->do_svd($dim);
#
sub do_svd {
  my $pdl = shift;
  my $k   = shift || 0;
  my $n   = $pdl->getdim(0);

  return $pdl unless $k > 0 && $k < $n;

  my ($t0, $s0, $d0) = svd($pdl);

  my ($t, $s, $d)    = ($t0, mzeroes($n, $n), transpose $d0);
                             # Create "empty" (i.e. zero-filled) matrix

  $s->diagonal(0,1) .= $s0;  # Fill diagonal with values from $s0

  # Retain $k most significant dimensions
  $s->set($n,$n,0) while --$n > $k - 1;

  # From SenseClusters-v0.65/Toolkit/svd/pdlsvd.pl
  #$t = $t(0:$k-1,:;|);
  #$s = $s(0:$k-1;|);
  #$d = $d(0:$k-1,:;|);

  return $t * $s x $d;
}
# </sub do_svd>

# <sub to_array>
# Return piddle as array of array refs
sub to_array {
  my $self = shift;

  my @array = ();
  my ($n, $i) = ($self->getdim(0), -1);

  push(@array => [$self($i)->list]) while ++$i < $n;

  return @array;
}
# </sub to_array>

### /object methods/

1;
