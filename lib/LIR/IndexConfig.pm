###############################################################################
#                                                                             #
# IndexConfig.pm -- lir_index.pl configuration file                           #
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

### other modules to _use_

use File::Spec::Functions qw(catfile);

use LIR::GlobalConfig     qw($TEMPLATES);

### /other modules to _use_/

### global settings

# my lir_index.pl version ;-)
our $VERSION = '0.19';

# default cgi arguments
our %CGI_DFLTS = (            # (cgi argument -> argument value)
  'action' => 'default'
);

our %TMPL      = (
  'default' => catfile($TEMPLATES, 'lir_index.tmpl'),
  'help'    => catfile($TEMPLATES, 'index_help.tmpl')
);

our $HEADING = 'lir index - create indexes for lir.pl';

### /global settings/

1;
