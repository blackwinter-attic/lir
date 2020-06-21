###############################################################################
#                                                                             #
# GlobalConfig.pm -- Global configuration file.                               #
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

### other modules

use File::Basename        qw(basename);
use File::Spec::Functions qw(catfile);

use LIR::BaseUtil         qw(FALSE TRUE untaint_var);

### /other modules/

### global settings

# My LIR version
our $VERSION = '0.3';

# My progname (untainted)
our $PROGNAME = untaint_var($0, '[\w_/-]+\.pl');

# My name
our $BASENAME = basename $PROGNAME;

# Name "lir.pl" hard-coded into lir_index.pl
our $LIR_PL = 'lir.pl';

# Server settings
our $BASE_DIR  = '/lir';
our $CGI_BIN   = catfile($BASE_DIR, 'cgi-bin');
our $CGI_FILE  = catfile($CGI_BIN,  $BASENAME);
our $CSS_FILE  = catfile($BASE_DIR, 'lir.css');

our $HOME_FILE = catfile($BASE_DIR, '');
our $HELP_FILE = $CGI_FILE . '?action=help';
our $PREF_FILE = $CGI_FILE . '?action=preferences';

# File paths (relative to local CGI directory)
our $DATA       = '../data';
our $LAB        = 'lab';
our $LAB_DATA   = catfile($DATA, $LAB);
our $WEB        = '../web';

# Group to own files (symbolic name)
our $GID = scalar getgrnam('lirwww') || scalar getgrnam('lir') || -1;

# Templates
our $TEMPLATES = catfile($WEB, 'templates');
our $INCLUDES  = catfile($WEB, 'includes');

# HTTP header
$ENV{'HTTP_ACCEPT'} ||= '';
our $CONTENT_TYPE = (! $ENV{'HTTP_ACCEPT'} || $ENV{'HTTP_ACCEPT'} =~ m{application/xhtml\+xml}) ? 'application/xhtml+xml' : 'text/html';

# Disabled, checked, selected (XHTML compliant!)
use constant {
  DISABLED => 'disabled="disabled"',
  CHECKED  => 'checked="checked"',
  SELECTED => 'selected="selected"'
};

# Tooltips
use constant {
  TT_TERM     => 'Query term',
  TT_NUMBER   => 'Arbitrary number (integer or real)',
  TT_STRING   => 'Arbitrary string',
  TT_WORD     => '&quot;Word&quot;',
  TT_DOCUMENT => '&quot;Document&quot;',
  TT_WEIGHT   => 'Term weight',
  TT_FREQ     => 'Term frequency',
  TT_DOCFREQ  => 'Document frequency',
  TT_COLFREQ  => 'Collection frequency',
  TT_DOCNUM   => 'Number of documents in the collection',
  TT_LEN      => 'Term length',
  TT_DOCLEN   => 'Document length',
  TT_COLLEN   => 'Collection length',
  TT_FORMLEN  => 'Number of distinct word forms in the document',
  TT_E        => 'Euler&apos;s number (e = 2.71828 18284...)'  # &#8776;
};

# My DBs (containing all necessary information)
# * status       - 0 = offline / 1 = online
# * name         - short name
# * info         - long name + addt'l info
# * db_file      - DB file (under $data)
# * db_enc       - encoding of DB file
# * idx_file     - index file
# * idx_enc      - encoding of index file
# * id2rec       - how to convert index ID to record ID
# * cat_desc_id  - category description ID (only necessary if different from DB ID)
# * cat_id       - category that contains the "ID"
# * cat_tit      - category that contains the "title"
# * full_display - categories to display in "full" display
# * ranking_id   - status (see above)
our %DB = (                   # (DB ID -> \(item -> content)) [hash of hashes]
  'lir'     => {
    'status'       => TRUE,
    'name'         => 'LIR',
    'info'         => 'LIR test database (331 records)',
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
    'status'       => FALSE,
    'name'         => 'Literatur zur Inhaltserschließung',
    'info'         => 'Literatur zur Inhaltserschließung (26.239 records)',
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
  'litac'   => {
    'status'       => TRUE,
    'name'         => 'Literatur zur Informationserschließung',
    'info'         => 'Literatur zur Informationserschließung (42.740 records)',
    'db_file'      => 'litac_records.dbm',
    'idx_file'     => 'litac_index.dbm',
    'cat_id'       => '000',
    'cat_tit'      => '100',
    '0'            => TRUE,
    '1'            => TRUE,
    '2'            => TRUE,
    '3'            => TRUE,
    '4'            => TRUE,
    'x'            => TRUE,
    'y'            => TRUE,
    'z'            => TRUE
  },
  #'lit_svd' => {
  #  'status'       => FALSE,
  #  'name'         => 'Literatur zur Inhaltserschließung (SVD)',
  #  'info'         => 'Literatur zur Inhaltserschließung (26.239 records)<br />WITH SVD',
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
    'name'         => 'RDK-Web 07',
    'info'         => 'RDK-Web, Volume 07 (762 records)<br /><small><em>Based on DES.DBM</em></small>',
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

# Ranking algorithms (0-4 corresponding to Rvl2DB.ini)
our %RANKING = (    # (ranking ID -> name)
  '0'  => 'Salton',
  '1'  => 'Kascade einfach',
  '2'  => 'Kascade komplex',
  '3'  => 'Robertson',
  '4'  => 'IDF',
  #'s0' => 'SVD (Salton)',
  #'s1' => 'SVD (Kascade einfach)',
  #'s2' => 'SVD (Kascade komplex)',
  #'s3' => 'SVD (Robertson)',
  #'s4' => 'SVD (IDF)',
  #'sx' => 'SVD (Term frequency)',
  'x'  => 'Term frequency',
  'y'  => 'Custom',
  'z'  => 'No ranking'
);

# Category descriptions
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
  # http://ixtrieve.fh-koeln.de/lehre/kategorienschema-litac.pdf
  'litac' => {
    '000' => 'Identnummer',
    '030' => 'Dokumenttyp',
    '040' => 'Erscheinungsjahr',
    '050' => 'Sprache',
    '08I' => 'ISBN',
    '100' => 'Sachtitel : Zusatz',
    '200' => 'Verfasser',
    '21E' => 'Herausgeber',
    '270' => 'Biografierte',
    '411' => 'Serientitel ; Zählung',
    '510' => 'Themenfeld',
    '520' => 'Wissenschaftsfach',
    '530' => 'Behandelte Form',
    '540' => 'Objekt',
    '550' => 'Land/Ort',
    '590' => 'Sparte',
    '700' => 'Quelle',
    '810' => 'Umfang',
    '855' => 'Ausgabevermerk',
    '860' => 'Impressum', # Eort : Verlag, EJahr
    '875' => 'Inhalt',
    '870' => 'Abstract',
    '880' => 'Fußnote',
    '50C' => 'Compass',
    '50L' => 'LCSH',
    '50P' => 'Precis',
    '50R' => 'RSWK',
    '53A' => 'Hilfsmittel', # Missbrauch: Kunstgenre
    '60B' => 'BK',
    '60A' => 'ASB',
    '60D' => 'DDC',
    '60E' => 'Eppelsheimer',
    '60F' => 'SFB',
    '60G' => 'GHBS',
    '60K' => 'KAB',
    '60L' => 'LCC',
    '60S' => 'SSD',
    '60R' => 'RVK',
    '890' => 'Bildlink',
    '892' => 'Abbildung',
    '900' => 'Signatur',
    '9ZC' => 'Zugangsdatum',
    '9ZE' => 'Änderungsdatum'
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
# Convert record ID created by IDX to original Bismas ID
sub idx2rec {
  my $idx = shift;
  my $rec = $idx;

  # IDX ID has (at least) seven digits
  $rec =~ s{\A00(.....)}{$1};

  return $rec;
}
# </sub idx2rec>

### /utilities/

1;
