###############################################################################
#                                                                             #
# LirConfig.pm -- lir.pl configuration file.                                  #
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

package LIR::LirConfig;

use strict;
use warnings;

### variables to export

require Exporter;

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = (
  vars => [qw(
    $VERSION
    %CGI_DFLTS %TMPL
    $HEADING $STEP $SIM_N
  )]
);
our @EXPORT_OK   = map(@{$_} => values %EXPORT_TAGS);

### /variables to export/

### other modules

use File::Spec::Functions qw(catfile);

use LIR::GlobalConfig     qw($TEMPLATES);
use LIR::BaseUtil         qw(FALSE TRUE);

### /other modules/

### global settings

# My lir.pl version
our $VERSION = '0.31';

# Default CGI arguments
our %CGI_DFLTS = (            # (CGI argument -> argument value)
  'db'             => 'lir',
  'action'         => 'default',
  'query'          => '',
  'regexp'         => FALSE,
  'ranking'        => '2',
  'case_sensitive' => FALSE,
  'truncated'      => FALSE,
  'threshold'      => '#100',
  'offset'         => 1,
  'record_num'     => '',
  'custom_ranking' => 'tf * log(N / df)'
);

# Templates
our %TMPL = (
  'default'      => catfile($TEMPLATES, 'lir.tmpl'),
  'get_results'  => catfile($TEMPLATES, 'results.tmpl'),
  'show_records' => catfile($TEMPLATES, 'records.tmpl'),
  'help'         => catfile($TEMPLATES, 'help.tmpl'),
  'set_prefs'    => catfile($TEMPLATES, 'preferences.tmpl')
);

# Aliases
$TMPL{'re_rank'}        = $TMPL{'get_results'};
$TMPL{'search_similar'} = $TMPL{'get_results'};
$TMPL{'get_prefs'}      = $TMPL{'default'};

# Heading
our $HEADING = 'LIR – "Lehr- und Lernsystem Information Retrieval"';

# Step for "paged" results display
our $STEP = 100;

# Use top 10 terms for "more like this" and "search similar"
our $SIM_N = 10;

### /global settings/

1;
