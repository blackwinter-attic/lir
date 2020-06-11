#! /usr/bin/perl -T

###############################################################################
#                                                                             #
# lir.pl -- LIR – "Lehr- und Lernsystem Information Retrieval".               #
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

### modules + pragmas

use strict;
use warnings;
use diagnostics -verbose;

use CGI::Carp             qw(fatalsToBrowser warningsToBrowser);
use HTML::Template        qw();

use File::Basename        qw(basename dirname);
use File::Spec::Functions qw(catfile);

# My LIR modules
# Relative to CGI directory

use lib '../lib';

use LIR::GlobalConfig     qw(:vars :cons);
use LIR::LirConfig        qw(:vars);
use LIR::BaseUtil         qw(:subs :cons);

use LIR::CGI;
use LIR::DB;

### /modules + pragmas/

### global variables + settings

# Untaint PATH
$ENV{'PATH'} = '/bin:/usr/bin:/usr/local/bin';

# Make %ENV safer
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# My HTML::Template
my $tmpl                   = '';

$ENV{'HTML_TEMPLATE_ROOT'} = $INCLUDES;

my %tmpl_params            = (
  'basename'     => $BASENAME,
  'heading'      => $HEADING,
  'content_type' => $CONTENT_TYPE,
  'cgi_file'     => $CGI_FILE,
  'home_file'    => $HOME_FILE,
  'help_file'    => $HELP_FILE,
  #'pref_file'    => $PREF_FILE,
  'css_file'     => $CSS_FILE,
  'version'      => $VERSION,
  'tt_term'      => TT_TERM,
  'tt_number'    => TT_NUMBER,
  'tt_string'    => TT_STRING,
  'tt_word'      => TT_WORD,
  'tt_document'  => TT_DOCUMENT,
  'tt_weight'    => TT_WEIGHT,
  'tt_freq'      => TT_FREQ,
  'tt_docfreq'   => TT_DOCFREQ,
  'tt_colfreq'   => TT_COLFREQ,
  'tt_docnum'    => TT_DOCNUM,
  'tt_len'       => TT_LEN,
  'tt_doclen'    => TT_DOCLEN,
  'tt_collen'    => TT_COLLEN,
  'tt_formlen'   => TT_FORMLEN,
  'tt_e'         => TT_E
);

# Global vars
my $db = '';                  # My LIR::DB object

my %ranking_list = ();        # Ranked result list for re-ranking

my %ranking_disabled = ();    # (Ranking ID -> disabled?)
my %ranking_selected = ();    # (Ranking ID -> selected?)

my %doc_matches  = ();        # Matching terms per document (doc no. -> \terms) [hash of arrays]
my %doc_weight   = ();        # Cumulated weight of matching terms per document (doc no. -> weight)

# Indexes
my %term_index   = ();        # Terms from STO (term -> \(doc no. -> weight)) [hash of hashes]
my %doc_index    = ();        # Categories per record (ID -> \(catnum -> category content)) [hash of hashes]

### /global variables + settings/

### action

# Create new CGI object...
my $cgi = LIR::CGI->new(%CGI_DFLTS);

# ...and parse CGI query
$cgi->parse_query;

# Get action to perform
my %action = (
  'get_results'    => sub { get_results();    },
  'show_records'   => sub { show_records();   },
  're_rank'        => sub { re_rank();        },
  'search_similar' => sub { search_similar(); },
  'help'           => sub {},
  'default'        => sub {}
);

# "Aliases"
$cgi->action('show_records')   if lc($cgi->action) eq 'view';
$cgi->action('search_similar') if lc($cgi->action) eq 'search similar';

my $my_action = defined $action{$cgi->action} ? $cgi->action : 'default';

$tmpl = HTML::Template->new('filename'                    => $TMPL{$my_action},
                            'vanguard_compatibility_mode' => 1,
                            # NOTE: HTML/Template.pm:1991 (2.95):
                            # $self->{template} =~ s/%(\w+)%/<TMPL_VAR NAME=$1>/g;
                            #                         ^^^^^
                            # in order to prevent HTML::Template from trying to
                            # substitute constructs like:
                            # query=%2Bindexierung+ranking.*%231.5+automatisch%23-1.5+-thesaurus
                            #       ^^^^^^^^^^^^^^^^^^^^^^^^^
                            'loop_context_vars'           => 1,
                            'global_vars'                 => 1)
  or die "Can't get template for action $my_action!\n";

$tmpl_params{$my_action} = 1;

unless ($my_action =~ m{\A(?:help)\z}) {
  # Create new DB object
  $db = LIR::DB->new($cgi->db) || LIR::DB->new($cgi->dflt('db'))
    or die "Can't open DB!\n";

  # To be on the safe side...
  $cgi->db($db->id);

  # Perform action
  &{$action{$my_action}};

  prepare_output();
}
else {
  $tmpl_params{'heading'} = 'LIR – ' . ucfirst($my_action);
}

# Send output to browser
print "Content-type: $CONTENT_TYPE\n\n";

$tmpl->param(%tmpl_params);
print $tmpl->output;

warningsToBrowser(1);

exit 0;

### /action/

### subroutines

# <sub get_results>
# Get query results
sub get_results {
  unless ($cgi->query) {
    $tmpl_params{'no_query'} = TRUE;
    return;
  }

  my $idx_file = catfile($DATA, $db->idx_file);
  tie_index(\%term_index, $idx_file);

  my @query_args = split(' ', $cgi->query);
  my @terms      = ();

  $cgi->regexp(TRUE) if $cgi->truncated || $cgi->case_sensitive;

  # Provide some kind of "case-insensitive" functionality for "fixed strings"
  # i.e. "first-letter/whole-word case-insensitive"
  unless ($cgi->regexp) {
    my @temp_args = ();
    foreach my $arg (@query_args) {
      push(@temp_args => (lcfirst($arg), ucfirst($arg)));
      push(@temp_args => lc($arg)) if lc($arg) ne lcfirst($arg);
      push(@temp_args => uc($arg)) if uc($arg) ne ucfirst($arg);
    }
    @query_args = @temp_args;
  }

  my $titlestr = '__%' . $db->cat_tit . '%__';
  my $titleref = $term_index{$titlestr};  # titles (docnum -> title)

  my $chars = '-+\d.*/()% ';
  my $funcs = 'atan2|cos|exp|int|log|rand|sin|sqrt';
  my $vars  = 'N|df|cf|tf';

  my $custom_ranking = length $cgi->custom_ranking ? $cgi->custom_ranking : $cgi->dflt('custom_ranking');

  $custom_ranking =~ s{;.*}{};                    # Delete everything after ";"
  $custom_ranking =~ s{[^$chars[:alpha:]]}{}g;    # Delete everything except allowed and alphabetic characters

  $cgi->custom_ranking($custom_ranking);          # Provide denoised string (this may be of
                                                  # help to the user if untainting fails)
  $custom_ranking = untaint_var($custom_ranking, "([$chars]|$funcs|$vars)*");
                    # Check if only allowed characters and strings were used

  my $N = scalar keys %{$titleref};  # Number of documents in the collection

  # Substitute special variables
  $custom_ranking =~ s{N}{$N}g;
  $custom_ranking =~ s{df}{\$df}g;  # Escape for eval
  $custom_ranking =~ s{cf}{}g;
  $custom_ranking =~ s{tf}{\$tf}g;  # Escape for eval

  # These contain documents that must (not) occur: (docnum -> count)
  my %docs_must     = ();
  my %docs_must_not = ();

  my $old_query_arg = '';
  my $old_must      = 0;
  my $musts         = 0;
  foreach my $query_arg (@query_args) {
    my $must = 0;
    if    ($query_arg =~ s{\A\+}{}) { $must = 1; }
    elsif ($query_arg =~ s{\A\-}{}) { $must = -1; }

    if    (!$old_query_arg && $query_arg =~ s{\A"(.*)"}{$1}) {
      # Single search term, just proceed...
    }
    elsif (!$old_query_arg && $query_arg =~ s{\A"[-+]?}{}) {
      # Beginning of a phrase
      $old_query_arg = $query_arg;
      $old_must      = $must;
      next;  # next foreach
    }
    elsif ($old_query_arg && $query_arg =~ s{\A(.*)"}{$1}) {
      # End of a phrase
      $query_arg     = $old_query_arg . ' ' . $query_arg;
      $old_query_arg = '';
      $must          = $old_must;
    }
    elsif ($old_query_arg) {
      # Inner part of a phrase
      # Ignore $must, consider "#..." as literal
      $old_query_arg .= ' ' . $query_arg;
      next;  # next foreach
    }

    ($query_arg, my $modifier) = split('#', $query_arg, 2);
    $modifier = 1 unless defined $modifier;

    my @matching_terms = ($query_arg);  # Assume match -- will be ignored if it's not (see below)

    if ($cgi->regexp) {
      @terms = keys %term_index unless @terms;

      $query_arg .= '.*'                if     $cgi->truncated;
      $query_arg  = '(?i)' . $query_arg unless $cgi->case_sensitive;

      my $pat = qr{\A\b$query_arg\b\z};
      @matching_terms = sort grep { $_ =~ $pat } @terms;
    }

    my %seen = ();
    foreach my $match (@matching_terms) {
      #next unless $match;

      my $termref = $term_index{$match};
      next unless $termref;                   # Eliminate non-matching
      next if     $match =~ m{\A__%.*%__\z};  # Reserved for internal use

      my $df = scalar keys %{$termref};       # Document frequency

      foreach my $docnum (keys %{$termref}) {
        my $weight;
        if    ($cgi->ranking eq 'z') {
          $weight = 0;
        }
        elsif ($cgi->ranking eq 'y') {
          next unless defined $custom_ranking;

          # term frequency
          my $tf = $termref->{$docnum}->{'x'};

          $weight = eval $custom_ranking;
          $weight = sprintf("%0.4f", $weight);  # Round to four decimals
        }
        else                                {
          $weight = $termref->{$docnum}->{$cgi->ranking};
        }
        next unless defined $weight;

        push(@{$doc_matches{$docnum}}, $match);
        $doc_weight{$docnum} += $weight * $modifier;

        if    ($must == 1)  {
          $docs_must{$docnum}++ unless $seen{$docnum};
          $seen{$docnum}++;
        }
        elsif ($must == -1) {
          $docs_must_not{$docnum}++;
        }
      }
    }
    $musts++ if $must == 1;
  }

  foreach my $docnum (keys %doc_matches) {
    if    ($docs_must_not{$docnum}) {
          # Document occurs in %docs_must_not
          # i.e. it mustn't occur
      delete $doc_matches{$docnum};
      delete $doc_weight{$docnum};
    }
    elsif (%docs_must && (! $docs_must{$docnum} || $docs_must{$docnum} < $musts)) {
          # %docs_must contains documents and
          # document is not one of these or document has too few "musts"
          # in other words: there are documents that "must",
          # but document is not one of these or it doesn't contain _every_ "must"-term
      delete $doc_matches{$docnum};
      delete $doc_weight{$docnum};
    }
  }

  # No results? Quit early!
  return unless %doc_weight;

  # First, sort by document number...
  my @docs_match = sort keys %doc_weight;
  # ...and then by weight! (Unless ranking is "none")
  @docs_match = sort { $doc_weight{$b} <=> $doc_weight{$a} } @docs_match unless $cgi->ranking eq 'z';

  my $max_result_num = scalar @docs_match;
  my $max_weight     = $doc_weight{$docs_match[0]};

  my $threshold     = '';
  my $threshold_val = 0;
  my $threshold_num = $max_result_num;
  unless ($cgi->threshold eq '' || $cgi->offset > 1) {
    ($threshold = $cgi->threshold) =~ s{[^0-9\-+.%#]}{}g;  # Delete everything except allowed characters
    if ($cgi->ranking ne 'z') {
      if    ($threshold =~ m{\A#.*%\z}) { ($threshold_num = $threshold) =~ tr{%#}{}d;
                                           $threshold_num = $threshold_num / 100 * $max_result_num }
      elsif ($threshold =~ m{\A#})      { ($threshold_num = $threshold) =~ tr{%#}{}d;
                                           $threshold_num =~ s{\..*}{}; }
      elsif ($threshold =~ m{%\z})      { ($threshold_val = $threshold) =~ tr{%#}{}d;
                                           $threshold_val = $threshold_val / 100 * $max_weight }
      else                              { ($threshold_val = $threshold) =~ tr{%#}{}d; }
    }
    else {
      if    ($threshold =~ m{\A#.*%\z}) { ($threshold_num = $threshold) =~ tr{%#}{}d;
                                           $threshold_num = $threshold_num / 100 * $max_result_num }
      elsif ($threshold =~ m{\A#})      { ($threshold_num = $threshold) =~ tr{%#}{}d;
                                           $threshold_num =~ s{\..*}{}; }
    }
  }

  my @result_list = ();
  foreach my $doc (@docs_match) {
    push(@result_list, $doc)
      if $threshold eq ''
         # No threshold
      || $threshold =~ m{\A#}
         # Top of list
      || $cgi->ranking eq 'z'
         # No ranking => no weight to exceed threshold
      || $cgi->offset > 1
         # We are "paging" through results list
      || $doc_weight{$doc} >= $threshold_val;
         # Weight exceeds threshold!
  }

  my $first_result_num = $cgi->offset > 1 ? $cgi->offset : 1;
  my $pdiff            = $first_result_num - $STEP > 1 ? $STEP : $first_result_num - 1;
  my $my_offset        = $first_result_num - $pdiff;
  $my_offset           = $my_offset < 1 ? 1 : $my_offset;

  $tmpl_params{'less'}      = $cgi->offset > 1 ? 1 : 0;
  $tmpl_params{'pdiff'}     = $pdiff;
  $tmpl_params{'prev_args'} = $cgi->to_string('offset' => $my_offset,
                                              'action' => 'get_results');

  my $result_num = 0;
  foreach my $docnum (@result_list) {
    last if $result_num >= $threshold_num
         || ($cgi->offset > 1 && $result_num >= $cgi->offset + $STEP - 1);
    ++$result_num;
    next if $result_num < $cgi->offset;

    my $weight = $cgi->ranking ne 'z' ? '@<strong>' . $doc_weight{$docnum} . '</strong>' : '-';
    my $my_id  = $cgi->ranking ne 'z' ? $docnum : '<strong>' . $docnum . '</strong>';
    my $my_result_num = $result_num . '.';

    if ($ranking_list{$docnum}) {
      my ($former_result_num, $former_weight) = split(':', $ranking_list{$docnum});
      $my_result_num .= ' <em>(' . $former_result_num . '.)</em>';
      $weight        .= ' <em>(' . $former_weight . ')</em>';
    }

    my @matches_temp = ();
    my %seen         = ();
    foreach my $match (@{$doc_matches{$docnum}}) {
      $match = '"' . $match . '"' if $match =~ m{ };
      $match =~ s{ & }{ &amp; }g;

      push(@matches_temp => $match) unless $seen{$match}++;
    }
    my $matches      = join(' ', @matches_temp);

    my $my_query_string = $cgi->to_string('record_num' => $docnum,
                                          'action'     => 'show_records');

    push(@{$tmpl_params{'results'}} => { 'docnum'          => $docnum,
                                         'result_num'      => $my_result_num,
                                         'my_query_string' => $my_query_string,
                                         'my_id'           => $my_id,
                                         'weight'          => $weight,
                                         'title'           => $titleref->{$docnum},
                                         'matches'         => $matches });

    if (defined $cgi->arg('re_ranking') && length $cgi->arg('re_ranking') && $cgi->arg('re_ranking') ne $cgi->ranking) {
      $weight =~ tr{@</strong>}{}d;
      $ranking_list{$docnum} = $result_num . ':' . $weight;
    }
  }

  my $last_result_num = $result_num;
  my $ndiff           = $last_result_num + $STEP > $max_result_num ? $max_result_num - $last_result_num : $STEP;

  $tmpl_params{'more'}      = $last_result_num < $max_result_num ? 1 : 0;
  $tmpl_params{'ndiff'}     = $ndiff;
  $tmpl_params{'next_args'} = $cgi->to_string('offset' => $last_result_num + 1,
                                              'action' => 'get_results');

  map { $_ = '' } @ranking_selected{keys %RANKING};
  $ranking_selected{$cgi->ranking} = SELECTED;

  #map { $_ = $db->{$_} ? '' : DISABLED } @ranking_disabled{keys %RANKING};  # Use of uninitialized value in hash element
  %ranking_disabled      = map { $_ => $db->{$_} ? '' : DISABLED } keys %RANKING;
  $ranking_disabled{'y'} = DISABLED if $ranking_disabled{'x'} || ! $cgi->custom_ranking;

  $result_num = $last_result_num - $first_result_num + 1;

  my $of = $result_num < $max_result_num
    ? "<a href=\"$CGI_FILE?" . $cgi->to_string('threshold' => '',
                                               'offset'    => undef,
                                               'action'    => 'get_results') . "\" title=\"Display all\">$max_result_num</a>"
    : "$max_result_num";

  my $result_s     = $result_num > 1     ? 's' : '';
  my $max_result_s = $max_result_num > 1 ? 's' : '';

  my $from_to = $result_s ? "$first_result_num - $last_result_num" : "$first_result_num";

  $tmpl_params{'view_args'}    = $cgi->to_array('record_num' => undef,
                                                'action'     => undef);
  $tmpl_params{'refine_args'}  = $cgi->to_array('offset'     => undef,
                                                'action'     => undef);
  $tmpl_params{'re_rank_args'} = $cgi->to_array('threshold'  => undef,
                                                'offset'     => undef,
                                                'action'     => undef);

  $tmpl_params{'result_s'}     = $result_s;
  $tmpl_params{'from_to'}      = $from_to;
  $tmpl_params{'result_num'}   = $result_num;
  $tmpl_params{'of'}           = $of;
  $tmpl_params{'max_result_s'} = $max_result_s;
}
# </sub get_results>

# <sub re_rank>
# Perform new ranking on results
sub re_rank {
  if ($cgi->arg('re_ranking') ne $cgi->ranking) {
    my $old_threshold = $cgi->threshold;
    $cgi->threshold('');

    # Aim: Get former ranking and compare to the new one -- how?
    get_results();

    # Clean up
    %doc_weight  = ();
    %doc_matches = ();

    delete $tmpl_params{'results'};
    delete $tmpl_params{'view_args'};
    delete $tmpl_params{'refine_args'};
    delete $tmpl_params{'re_rank_args'};

    # And get new ranking
    $cgi->ranking($cgi->arg('re_ranking'));
    $cgi->threshold($old_threshold);
  }

  get_results();
}
# </sub re_rank>

# <sub search_similar>
# "Relevance feedback"
sub search_similar {
  $tmpl_params{'similar'} = TRUE;

  return unless $cgi->record_num;

  my $db_file = catfile($DATA, $db->db_file);
  tie_index(\%doc_index, $db_file);

  my @terms = ();
  my $r     = $cgi->ranking;
  $r = 'x' if $r =~ m{\A(?:y|z)\z};  # "y" and "z" don't have records

  foreach my $record_num (split(' ', $cgi->record_num)) {
    next unless $record_num;

    my $r_ref = $doc_index{$record_num}->{"xx$r"};
    my @t     = sort { $r_ref->{$b} <=> $r_ref->{$a} } keys %{$r_ref};

    my $num   = scalar @t;
    my $n     = ($num < $SIM_N ? $num : $SIM_N) - 1;

    push(@terms => @t[0 .. $n]);
  }

  $cgi->query(join(' ' => sort @terms));
  $cgi->regexp(FALSE);

  get_results();
}
# </sub search_similar>

# <sub show_records>
# Display records
sub show_records {
  return unless $cgi->record_num;

  my $db_file = catfile($DATA, $db->db_file);
  tie_index(\%doc_index, $db_file);

  foreach my $record_num (split(' ', $cgi->record_num)) {
    next unless $record_num;

    my $recordref = $doc_index{$record_num};

    my $wterms_string  = '';
    my $record_display = '';
    my @my_cats        = ();
    my @my_wterms      = ();

    foreach my $catnum (@{$db->full_display}) {
      next unless defined $recordref->{$catnum};
      push(@my_cats => { 'desc'    => $db->cat_desc->{$catnum},
                         'content' => $recordref->{$catnum} });
    }

    foreach my $key (sort keys %RANKING) {
      next if     $key =~ m{\A(?:y|z)\z};
      next unless $db->{$key};

      my @wterms = sort {
        $recordref->{"xx$key"}->{$b} <=> $recordref->{"xx$key"}->{$a}  # by weight
                                     ||                                # then
                                  $a cmp $b                            # alphabetically
      } keys %{$recordref->{"xx$key"}};
      my $num      = scalar @wterms;
      my $mlt_args = '';

      my $n = ($num < $SIM_N ? $num : $SIM_N) - 1;
      my @wterms_temp = (@wterms)[0 .. $n];
      map { ($_ =~ m{ }) ? '%22' . $_ . '%22' : $_ } @wterms_temp;  # "quote" multiword terms

      $mlt_args = $cgi->to_string('query'          => undef,
                                  'ranking'        => $key,
                                  'regexp'         => FALSE,
                                  'threshold'      => undef,
                                  'offset'         => undef,
                                  'truncated'      => undef,
                                  'case_sensitive' => undef,
                                  'action'         => 'get_results');

      my $i = 0;
      map { $_ = { 'term'   => '<a href="' . $CGI_FILE . '?' . $mlt_args . '&amp;query=' . (($_ =~ m{ }) ? '%22' . $_ . '%22' : $_) . '">' . ($i++ <= $n ? '<strong>' . $_ . '</strong>' : $_) . '</a>',
                   'weight' => $recordref->{"xx$key"}->{$_} } } @wterms;

      $mlt_args .= '&amp;query=' . join('+', @wterms_temp);

      push(@my_wterms => { 'ranking_algorithm' => $RANKING{$key},
                           'num'               => $num,
                           'terms'             => \@wterms,
                           'mlt_args'          => $mlt_args });
    }

    push(@{$tmpl_params{'records'}} => { 'record_num' => $record_num,
                                         'cats'       => \@my_cats,
                                         'wterms'     => \@my_wterms });
  }

  $tmpl_params{'similar_args'} = $cgi->to_array('record_num' => undef,
                                                'action'     => undef);
}
# </sub show_records>

# <sub prepare_output>
# Prepare output
sub prepare_output {
  my $search_disabled = DISABLED;
  foreach my $key (sort keys %RANKING) {
    if ( $db->{$key}
    && ( -r catfile($DATA,     $db->idx_file)
      || -r catfile($LAB_DATA, $db->idx_file) ) ) {
      $ranking_disabled{$key} = '';
    }
    else {
      $ranking_disabled{$key} = DISABLED;
    }
    $search_disabled = '' unless $ranking_disabled{$key};

    $ranking_selected{$key} = '';
  }
  $ranking_disabled{'y'} = DISABLED if $ranking_disabled{'x'};

  # Check/select given ranking...
  if ($db->{$cgi->ranking}) {
    $ranking_selected{$cgi->ranking} = SELECTED;
  }
  # ...or first available otherwise
  else {
    foreach my $key (sort keys %RANKING) {
      if ($db->{$key}) {
        $ranking_selected{$key} = SELECTED;
        last;
      }
    }
  }

  $tmpl_params{'hidden_args'} = $cgi->to_array('db'     => undef,
                                               'action' => undef);

  push(@{$tmpl_params{'select_db'}}      => { 'db'          => $_,
                                              'db_selected' => $_ eq $db->id ? SELECTED : '',
                                              'db_disabled' => $DB{$_}->{'status'}
                                                            && $DB{$_}->{'db_file'}
                                                            && -r catfile($DATA, $DB{$_}->{'db_file'})
                                                            && $DB{$_}->{'idx_file'}
                                                            && -r catfile($DATA, $DB{$_}->{'idx_file'})
                                                            ?  ''
                                                            :  DISABLED,
                                              'db_name'     => $DB{$_}->{'name'} })
    for sort keys %DB;

  if ($db->id =~ m{\A$LAB/}) {
    unshift(@{$tmpl_params{'select_db'}} => { 'db'          => $db->id,
                                              'db_selected' => SELECTED,
                                              'db_disabled' => '',
                                              'db_name'     => $db->name });
  }

  $tmpl_params{'db_info'} = $db->info;

  if ($my_action =~ m{\A(?:default|get_results|show_records|re_rank|search_similar)\z}) {
    $tmpl_params{"my_$_"} = $cgi->arg_enc($_)
      for keys %CGI_DFLTS;

    push(@{$tmpl_params{'select_ranking'}} => { 'id'       => $_,
                                                'name'     => $RANKING{$_},
                                                'selected' => $ranking_selected{$_},
                                                'disabled' => $ranking_disabled{$_} })
      for sort keys %RANKING;

    $tmpl_params{'ranking_algorithm_x'} = $RANKING{'y'};
    $tmpl_params{'ranking_disabled_x'}  = $ranking_disabled{'y'};

    $tmpl_params{'regexp_checked'}         = $cgi->regexp         ? CHECKED : '';
    $tmpl_params{'truncated_checked'}      = $cgi->truncated      ? CHECKED : '';
    $tmpl_params{'case_sensitive_checked'} = $cgi->case_sensitive ? CHECKED : '';

    $tmpl_params{'my_db_name'}             = $db->name;
    $tmpl_params{'search_disabled'}        = $search_disabled;
    $tmpl_params{'seconds'}                = $cgi->time;

    $tmpl_params{'query_string'}   = $cgi->to_string('action' => 'default');

    $tmpl_params{'results_string'} = ($cgi->query      || $cgi->action eq 'get_results')
                                   && ! ($cgi->action eq 'change_db')
                                   ? $cgi->to_string('action' => 'get_results')
                                   : '';

    $tmpl_params{'records_string'} = ($cgi->record_num || $cgi->action eq 'show_records')
                                   && ! ($cgi->action eq 'change_db')
                                   ? $cgi->to_string('action' => 'show_records')
                                   : '';
  }
}
# </sub prepare_output>

### /subroutines/

END {
  # Untie indexes
  tie_index(\%term_index);
  tie_index(\%doc_index);
}
