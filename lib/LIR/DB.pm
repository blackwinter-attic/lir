###############################################################################
#                                                                             #
# DB.pm -- lir database object                                                #
#                                                                             #
# A component of lir, the experimental information retrieval environment.     #
#                                                                             #
# Copyright (C) 2004-2011 Jens Wille                                          #
#                                                                             #
# lir is free software: you can redistribute it and/or modify it under the    #
# terms of the GNU Affero General Public License as published by the Free     #
# Software Foundation, either version 3 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# lir is distributed in the hope that it will be useful, but WITHOUT ANY      #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   #
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for     #
# more details.                                                               #
#                                                                             #
# You should have received a copy of the GNU Affero General Public License    #
# along with lir. If not, see <http://www.gnu.org/licenses/>.                 #
#                                                                             #
###############################################################################

package LIR::DB;

use strict;
use warnings;

use LIR::GlobalConfig qw(:vars);
use LIR::BaseUtil     qw(TRUE tie_index);

# this module's version
our $VERSION = '0.2';

# <constructor>
# create LIR::CGI object
sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;

  my $id   = shift;
  my $self = {};

  if ($id =~ m{\A$LAB/(.*)}) {
    my $lab_db = {};
    tie_index($lab_db, "$LAB_DATA/${1}_config.dbm");
    %{$self} = %{$lab_db};
    tie_index($lab_db);
  }
  else {
    %{$self} = %{$DB{$id}};
  }

  return unless $self && $self->{'status'} eq TRUE;
  bless $self => $class;

  $self->_init($id, @_);

  return $self;
}
# </constructor>

# <initialization>
# initialize object
sub _init {
  my $self = shift;

  $self->{'id'} = shift;

  if    (exists $CAT_DESC{$self->{'id'}}) {
    $self->{'cat_desc'} = $CAT_DESC{$self->{'id'}};
  }
  elsif (defined $self->{'cat_desc_id'} && exists $CAT_DESC{$self->{'cat_desc_id'}}) {
    $self->{'cat_desc'} = $CAT_DESC{$self->{'cat_desc_id'}};
  }
  elsif (exists $CAT_DESC{'lit'}) {
    $self->{'cat_desc'} = $CAT_DESC{'lit'};
  }
  else {
    die "can't find any category description!\n";
  }

  $self->{'id2rec'}       ||= \&idx2rec;
  $self->{'cat_id'}       ||= '001';
  $self->{'cat_tit'}      ||= '020';
  $self->{'full_display'} ||= [qw(001 005 010 015 017 020 025 027 030 035 045 050 051 052 053 055 056 057 058 059 060 065 070 100 101 102 103 104 105 106 107 108 109 110 115 120 122 125 130 131 135 136 137 138 140)];

  if (@_) {
    my %extra = @_;
    @{$self}{keys %extra} = values %extra;
  }

}
# </initialization>

### object methods

# shorthands
sub id           { shift->{'id'};           }
sub status       { shift->{'status'};       }
sub name         { shift->{'name'};         }
sub info         { shift->{'info'};         }
sub db_file      { shift->{'db_file'};      }
sub idx_file     { shift->{'idx_file'};     }
sub cat_desc     { shift->{'cat_desc'};     }
sub cat_id       { shift->{'cat_id'};       }
sub cat_tit      { shift->{'cat_tit'};      }
sub full_display { shift->{'full_display'}; }

### /object methods/

1;
