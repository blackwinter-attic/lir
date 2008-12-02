###############################################################################
#                                                                             #
# SVD.pm -- singular value decomposition for lir                              #
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

package LIR::SVD;

use strict;
use warnings;

use PDL;
use PDL::Matrix;
use PDL::NiceSlice;

# inherit from PDL::Matrix
our @ISA         = qw(PDL::Matrix);
our %EXPORT_TAGS = ('Func' => []);

# this module's version
our $VERSION = '0.1';

# <constructor>
# create LIR::SVD object
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
# perform svd of given "accuracy"
#
# usage:
#   $svd = $mat->do_svd($dim);
#
sub do_svd {
  my $pdl = shift;
  my $k   = shift || 0;
  my $n   = $pdl->getdim(0);

  return $pdl unless $k > 0 && $k < $n;

  my ($t0, $s0, $d0) = svd($pdl);

  my ($t, $s, $d)    = ($t0, mzeroes($n, $n), transpose $d0);
                             # create "empty" (i.e. zero-filled) matrix

  $s->diagonal(0,1) .= $s0;  # fill diagonal with values from $s0

  # retain $k most significant dimensions
  $s->set($n,$n,0) while --$n > $k - 1;

  # from SenseClusters-v0.65/Toolkit/svd/pdlsvd.pl
  #$t = $t(0:$k-1,:;|);
  #$s = $s(0:$k-1;|);
  #$d = $d(0:$k-1,:;|);

  return $t * $s x $d;
}
# </sub do_svd>

# <sub to_array>
# return piddle as array of array refs
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
