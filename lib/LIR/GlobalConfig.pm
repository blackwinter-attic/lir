###############################################################################
#                                                                             #
# GlobalConfig.pm -- global configuration file                                #
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

package LIR::GlobalConfig;

use strict;
use warnings;

### variables to export

require Exporter;

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = (
  vars => [qw(
    %CGI_DFLTS %DB $PROGNAME $BASENAME $LIR_PL
    $BASE_DIR $CGI_BIN $CGI_FILE $CSS_FILE
    $HOME_FILE $HELP_FILE $PREF_FILE
    $DATA $LAB $LAB_DATA $WEB $HELP_HTML
    $GID $TEMPLATES $INCLUDES $CONTENT_TYPE
    %DB %RANKING %CAT_DESC
  )],
  cons => [qw(
    DISABLED CHECKED SELECTED
    TT_TERM TT_NUMBER TT_STRING
    TT_WORD TT_DOCUMENT TT_WEIGHT
    TT_FREQ TT_DOCFREQ TT_COLFREQ TT_DOCNUM
    TT_LEN TT_DOCLEN TT_COLLEN TT_FORMLEN
    TT_E
  )]
);
our @EXPORT_OK   = map(@{$_} => values %EXPORT_TAGS);
push(@EXPORT_OK => 'idx2rec');

### /variables to export/

### other modules to _use_

use File::Basename        qw(basename);
use File::Spec::Functions qw(catfile);

use LIR::BaseUtil         qw(FALSE TRUE untaint_var);

### /other modules to _use_/

### global settings

# my lir version ;-)
our $VERSION = '0.3';

# my progname (untainted)
our $PROGNAME = untaint_var($0, '\.?[\w_/]+\.pl');

# my name
our $BASENAME = basename $PROGNAME;

# name "lir.pl" hard-coded into lir_index.pl
our $LIR_PL = 'lir.pl';

# server settings
our $BASE_DIR  = '/lir';
our $CGI_BIN   = catfile($BASE_DIR, 'cgi-bin');
our $CGI_FILE  = catfile($CGI_BIN,  $BASENAME);
our $CSS_FILE  = catfile($BASE_DIR, 'lir.css');

our $HOME_FILE = catfile($BASE_DIR, '');
our $HELP_FILE = $CGI_FILE . '?action=help';
our $PREF_FILE = $CGI_FILE . '?action=preferences';

# file paths (relative to local cgi directory)
our $DATA       = '../data';
our $LAB        = 'lab';
our $LAB_DATA   = catfile($DATA, $LAB);
our $WEB        = '../web';

# group to own files (symbolic name)
our $GID = scalar getgrnam('lirwww') || scalar getgrnam('lir') || -1;

# templates
our $TEMPLATES = catfile($WEB, 'templates');
our $INCLUDES  = catfile($WEB, 'includes');

# http header
$ENV{'HTTP_ACCEPT'} ||= '';
our $CONTENT_TYPE = (! $ENV{'HTTP_ACCEPT'} || $ENV{'HTTP_ACCEPT'} =~ m{application/xhtml\+xml}) ? 'application/xhtml+xml' : 'text/html';

# disabled, checked, selected (xhtml compliant!)
use constant {
  DISABLED => 'disabled="disabled"',
  CHECKED  => 'checked="checked"',
  SELECTED => 'selected="selected"'
};

# tooltips
use constant {
  TT_TERM     => 'query term',
  TT_NUMBER   => 'arbitrary number (integer or real)',
  TT_STRING   => 'arbitrary string',
  TT_WORD     => '&quot;word&quot;',
  TT_DOCUMENT => '&quot;document&quot;',
  TT_WEIGHT   => 'term weight',
  TT_FREQ     => 'term frequency',
  TT_DOCFREQ  => 'document frequency',
  TT_COLFREQ  => 'collection frequency',
  TT_DOCNUM   => 'number of documents in the collection',
  TT_LEN      => 'term length',
  TT_DOCLEN   => 'document length',
  TT_COLLEN   => 'collection length',
  TT_FORMLEN  => 'number of distinct word forms in the document',
  TT_E        => 'euler&apos;s number (e = 2.71828 18284...)'  # &#8776;
};

# my db's (containing all necessary information)
# * status       - 0 = offline / 1 = online
# * name         - short name
# * info         - long name + addt'l info
# * db_file      - db file (under $data)
# * db_enc       - encoding of db file
# * idx_file     - index file
# * idx_enc      - encoding of index file
# * id2rec       - how to convert index id to record id
# * cat_desc_id  - category description id (only necessary if different from db id)
# * cat_id       - category that contains the "id"
# * cat_tit      - category that contains the "title"
# * full_display - categories to display in "full" display
# * ranking_id   - status (see above)
our %DB = (                   # (db id -> \(item -> content)) [hash of hashes]
  'lir'     => {
    'status'       => TRUE,
    'name'         => 'lir',
    'info'         => 'lir test database (331 records)',
    'db_file'      => 'lir_records.dbm',
    'db_enc'       => 'cp850',
    'idx_file'     => 'lir_index.dbm',
    'idx_enc'      => 'iso-8859-1',
    '0'            => TRUE,
    '1'            => TRUE,
    '2'            => TRUE,
    '3'            => TRUE,
    '4'            => TRUE,
    #'s0'           => TRUE,
    #'s1'           => TRUE,
    #'s2'           => TRUE,
    #'s3'           => TRUE,
    #'s4'           => TRUE,
    #'sx'           => TRUE,
    'x'            => TRUE,
    'y'            => TRUE,
    'z'            => TRUE
  },
  'lit'     => {
    'status'       => TRUE,
    'name'         => 'literatur zur inhaltserschließung',
    'info'         => 'literatur zur inhaltserschließung (26.239 records)',
    'db_file'      => 'lit_records.dbm',
    'db_enc'       => 'iso-8859-1',
    'idx_file'     => 'lit_index.dbm',
    'idx_enc'      => 'cp850',
    '0'            => FALSE,
    '1'            => TRUE,
    '2'            => TRUE,
    '3'            => FALSE,
    '4'            => FALSE,
    #'s0'           => FALSE,
    #'s1'           => TRUE,
    #'s2'           => TRUE,
    #'s3'           => FALSE,
    #'s4'           => FALSE,
    #'sx'           => TRUE,
    'x'            => TRUE,
    'y'            => TRUE,
    'z'            => TRUE
  },
  #'lit_svd' => {
  #  'status'       => FALSE,
  #  'name'         => 'literatur zur inhaltserschließung (svd)',
  #  'info'         => 'literatur zur inhaltserschließung (26.239 records)<br />WITH SVD',
  #  'db_file'      => 'lit_svd_records.dbm',
  #  'db_enc'       => 'iso-8859-1',
  #  'idx_file'     => 'lit_svd_index.dbm',
  #  'idx_enc'      => 'cp850',
  #  'id2rec'       => \&idx2rec,
  #  'cat_desc_id'  => 'lit',
  #  'cat_id'       => '001',
  #  'cat_tit'      => '020',
  #  'full_display' => [qw(001 005 010 015 017 020 025 027 030 035 045 050 051 052 053 055 056 057 058 059 060 065 070 100 101 102 103 104 105 106 107 108 109 110 115 120 122 125 130 131 135 136 137 138 140)],
  #  '0'            => FALSE,
  #  '1'            => TRUE,
  #  '2'            => TRUE,
  #  '3'            => FALSE,
  #  '4'            => FALSE,
  #  's0'           => FALSE,
  #  's1'           => TRUE,
  #  's2'           => TRUE,
  #  's3'           => FALSE,
  #  's4'           => FALSE,
  #  's5'           => TRUE,
  #  'x'            => TRUE,
  #  'y'            => TRUE,
  #  'z'            => TRUE
  #},
  'rdk07'   => {
    'status'       => TRUE,
    'name'         => 'rdk-web 07',
    'info'         => 'rdk-web, volume 07 (762 records)<br /><small><em>based on DES.DBM</em></small>',
    'db_file'      => 'rdk07_records.dbm',
    'db_enc'       => 'iso-8859-1',
    'idx_file'     => 'rdk07_index.dbm',
    'idx_enc'      => 'iso-8859-1',
    'id2rec'       => sub { $_[0]; },
    'cat_id'       => 'SPA',
    'cat_tit'      => 'ART',
    'full_display' => [qw(SPA ART TUE)],
    '0'            => FALSE,
    '1'            => FALSE,
    '2'            => FALSE,
    '3'            => FALSE,
    '4'            => FALSE,
    #'s0'           => FALSE,
    #'s1'           => FALSE,
    #'s2'           => FALSE,
    #'s3'           => FALSE,
    #'s4'           => FALSE,
    #'sx'           => TRUE,
    'x'            => TRUE,
    'y'            => TRUE,
    'z'            => TRUE
  }
);

# ranking algorithms (0-4 corresponding to Rvl2DB.ini)
our %RANKING = (    # (ranking id -> name)
  '0'  => 'salton',
  '1'  => 'kascade einfach',
  '2'  => 'kascade komplex',
  '3'  => 'robertson',
  '4'  => 'idf',
  #'s0' => 'svd (salton)',
  #'s1' => 'svd (kascade einfach)',
  #'s2' => 'svd (kascade komplex)',
  #'s3' => 'svd (robertson)',
  #'s4' => 'svd (idf)',
  #'sx' => 'svd (term frequency)',
  'x'  => 'term frequency',
  'y'  => 'custom',
  'z'  => 'no ranking'
);

# category descriptions
our %CAT_DESC = (             # (category -> description)
  'lit' => {
    '001' => 'Document No.',
    '005' => '1. Verfasser',
    '010' => '2. Verfasser',
    '015' => '3. Verfasser',
    '017' => 'Herausgeber',
    '020' => 'Hauptsachtitel',
    '025' => 'Zusatz HST',
    '027' => 'Ausgabevermerk',
    '030' => 'Quelle',
    '035' => 'Serientitel',
    '045' => 'Verlagsort',
    '050' => 'Verlag',
    '051' => 'Umfang',
    '052' => 'ISBN',
    '053' => 'Doktyp',
    '055' => 'Erscheinungsjahr',
    '056' => 'Abstract',
    '057' => 'Inhalt',
    '058' => 'Fu&#223;note',
    '059' => 'Sprache',
    '060' => 'Themenbereich',
    '065' => 'Themenbereich',
    '070' => 'Themenbereich',
    '100' => 'Objekt',
    '101' => 'Objekt',
    '102' => 'Objekt',
    '103' => 'Objekt',
    '104' => 'Objekt',
    '105' => 'Objekt',
    '106' => 'Objekt',
    '107' => 'Objekt',
    '108' => 'Objekt',
    '109' => 'Objekt',
    '110' => 'Hilfsmittel',
    '115' => 'Fachgebiet',
    '120' => 'Land/Ort',
    '122' => 'Sparte',
    '125' => 'Signatur',
    '130' => 'DDC',
    '131' => 'LCC',
    '135' => 'RSWK',
    '136' => 'LCSH',
    '137' => 'PRECIS',
    '138' => 'COMPASS',
    '140' => 'Biographierte',
    '145' => 'Bild',
    '146' => 'Abbildung',
    '148' => 'Einstufung',
    '150' => 'Datum1',
    '152' => 'Datum2'
  },
  'rdk07' => {
    'SPA' => 'Spalte',
    'ART' => 'Artikel',
    'TUE' => 'Teil&#252;berschrift',
    'DES' => 'Deskriptoren',
    'ORT' => 'Orte',
    'PER' => 'Personen'
  }
);

### /global settings/

### utilities

# <sub idx2rec>
# convert record id created by idx to original bismas id
sub idx2rec {
  my $idx = shift;
  my $rec = $idx;

  # idx id has (at least) seven digits
  $rec =~ s{\A00(.....)}{$1};

  return $rec;
}
# </sub idx2rec>

### /utilities/

1;
