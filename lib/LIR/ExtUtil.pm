###############################################################################
#                                                                             #
# ExtUtil.pm -- some more needful things ;-)                                  #
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

package LIR::ExtUtil;

use strict;
use warnings;

use Carp qw(croak);

### variables + subroutines to export

require Exporter;

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = (
  subs => [qw(
    view_source
  )]
);
our @EXPORT_OK   = map(@{$_} => values %EXPORT_TAGS);

### /variables + subroutines to export/

### other modules to _use_

use File::Basename        qw(basename dirname);
use File::Spec::Functions qw(catfile);

use LIR::BaseUtil         qw(:subs :cons);
use LIR::GlobalConfig     qw(:vars);

### /other modules to _use_/

### subroutines

# <sub view_source>
# view script source code
sub view_source {
  my $base = shift || $BASENAME;

  # untaint $base
  $base = untaint_var($base, "\Q$BASENAME\E|LIR/($MY_MODULES)\.pm");

  (my $html = $base) =~ s{\.p[lm]\z}{.html};
  $html              =~ s{/}{_}g;
  $html              = catfile($SOURCES, $html);

  my $path = ($base =~ m{\.pl\z}) ? dirname($PROGNAME) : '../lib';
  my $file = catfile($path, $base);
  die "can't read file: $file!\n" unless -r $file;

  my $css_base = basename $SOURCE_CSS;

  my $menu = '<div class="menu">';
  $menu   .= "<span><a href=\"$CGI_FILE\">$BASENAME</a></span>";
  $menu   .= ' | ';
  $menu   .= "<span><a href=\"$HOME_FILE\">lir home</a></span>";
  $menu   .= '</div>';

  my $html_mtime = (stat($html))[9] || 0;
  my $file_mtime = (stat($file))[9] || 0;

  # source.html out of date?
  if ($html_mtime < $file_mtime) {
    # then update!
    qx{
        perltidy -html -nnn -css=$SOURCE_CSS -st $file |
        sed      's,$SOURCE_CSS,$BASE_DIR/$css_base,g;
                  s,$file,$base,g;
                  s,<title>.*$base.*</title>,<title>$base - source code</title>,;
                  s,<h1>.*$base.*</h1>,<h1>$base - source code</h1>$menu,' - |
        perl -pe 's{(<span.*?>use</span> <span.*?>)LIR::($MY_MODULES)</span>}
                   {\$1<a href="$CGI_FILE?action=view_source&amp;file=LIR/\$2.pm">LIR::\$2</a></span>}g' - > $html
      }
  }

  my $url = catfile($SRC_DIR, basename($html));
  # redirect to $url:
  return "Location: $url\n\n";
}
# </sub view_source>

### /subroutines/

1;
