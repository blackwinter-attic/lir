###############################################################################
#                                                                             #
# IndexConfig.pm -- lir_index.pl configuration file.                          #
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

package LIR::IndexConfig;

use strict;
use warnings;

### variables to export

require Exporter;

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = (
  vars => [qw(
    $VERSION
    %CGI_DFLTS %TMPL
    $HEADING
  )]
);
our @EXPORT_OK   = map(@{$_} => values %EXPORT_TAGS);

### /variables to export/

### other modules

use File::Spec::Functions qw(catfile);

use LIR::GlobalConfig     qw($TEMPLATES);

### /other modules/

### global settings

# My lir_index.pl version
our $VERSION = '0.2';

# Default CGI arguments
our %CGI_DFLTS = (            # (CGI argument -> argument value)
  'action' => 'default'
);

our %TMPL      = (
  'default' => catfile($TEMPLATES, 'lir_index.tmpl'),
  'help'    => catfile($TEMPLATES, 'index_help.tmpl')
);

our $HEADING = 'LIR Index – Create indexes for lir.pl';

### /global settings/

1;
