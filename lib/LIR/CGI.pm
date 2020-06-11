###############################################################################
#                                                                             #
# CGI.pm -- LIR CGI query object.                                             #
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

package LIR::CGI;

use strict;
use warnings;

use CGI            qw(Vars);
use Time::HiRes    qw(gettimeofday tv_interval);

use URI::Escape    qw(uri_escape);
use HTML::Entities qw(encode_entities_numeric);

use LIR::BaseUtil  qw(:cons);

# This module's version
our $VERSION = '0.3';

# <constructor>
# Create LIR::CGI object
#
# Usage:
#  my $cgi = LIR::CGI->new(%argument_defaults);
#
sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;

  my $self  = {};
  bless $self => $class;

  $self->_init(@_);

  return $self;
}
# </constructor>

# <initialization>
# Initialize object
sub _init {
  my $self = shift;
  my %args = @_;

  my %dflts = %args;  # Make copy of hash!
  $self->{'dflts'} = \%dflts;
  $self->{'args'}  = \%args;

  $self->{'start'} = [gettimeofday()];  # This seems to give a much more realistic value than
                                        # using [$^T, 0] with tv_interval in LIR::CGI::time()
}
# </initialization>

### object methods

# <sub parse_query>
# Parse CGI query
sub parse_query {
  my $self = shift;

  my %q = Vars;
  foreach my $p (keys %q) {
    $self->arg($p => join(' ', split('\0', $q{$p})));
  }
}
# </sub parse_query>

# <sub dflt>
# Get CGI default arguments
#
# Usage:
#   $foo         = $cgi->dflt('foo');
#   ($foo, $bar) = $cgi->dflt(qw(foo bar));
#   $dflts       = $cgi->dflt;  # HASH ref
#   %dflts       = $cgi->dflt;  # HASH
#
sub dflt {
  my $self = shift;

  if (@_) {
    return wantarray() ? @{$self->{'dflts'}}{@_} : $self->{'dflts'}->{$_[0]};
  }
  else {
    return wantarray() ? %{$self->{'dflts'}}     : $self->{'dflts'};
  }
}
# </sub dflt>

# <sub arg>
# Get/set CGI arguments
sub arg {
  my $self = shift;

  return $self->{'args'} unless @_;

  my ($arg, $val) = @_;

  # NOTE: It's not possible to set a value to 'undef'

  return defined $val ? $self->{'args'}->{$arg} = $val : $self->{'args'}->{$arg};
}
# </sub arg>

# <sub arg_enc>
# Get CGI arguments ("'" encoded!)
sub arg_enc {
  my ($self, $arg) = @_;

  return encode_entities_numeric($self->arg($arg), "'");
}
# </sub arg_enc>

# <sub is_dflt>
# Arg equals default value?
sub is_dflt {
  my ($self, $arg, $val) = @_;

  my $test = defined $val ? $val : $self->arg($arg);
  return $test eq $self->dflt($arg) ? TRUE : FALSE;
}
# </sub is_dflt>

# <sub arg2dflt>
# Set arg to its default value
sub arg2dflt {
  my ($self, $arg) = @_;

  $self->arg($arg => $self->dflt($arg));
}
# </sub arg2dflt>

# <sub current>
# Return hash (ref) of non-default "core args" with their current values
# ("core args" being the ones defined on initialization)
#
# Usage:
#   $current = $cgi->current($escape);          # HASH ref
#   $current = $cgi->current($escape, %extra);  # HASH ref
#   %current = $cgi->current($escape);          # HASH
#   %current = $cgi->current($escape, %extra);  # HASH
#
sub current {
  my $self             = shift;
  my ($escape, %extra) = @_;

  my %args = ();
  foreach my $arg (keys %{$self->dflt}) {
    my $val = exists $extra{$arg} ? delete $extra{$arg} : $self->arg_enc($arg);
    $val = uri_escape($val) if $arg =~ m{\A(?:query|threshold)\z} && $escape;

    next unless defined $val;
    next if $self->is_dflt($arg => $val);

    $args{$arg} = $val;
  }

  # Anything left in %extra?
  @args{keys %extra} = values %extra;

  return wantarray() ? %args : \%args;
}
# </sub current>

# <sub to_string>
# Return args as query string
#
# Usage:
#  $query_string = $cgi->to_string;
#  $query_string = $cgi->to_string(%extra);
#
sub to_string {
  my $self = shift;

  my %args = $self->current(TRUE, @_);
  my @args = ();
  foreach my $arg (sort keys %args) {
    push(@args => $arg . '=' . $args{$arg});
  }

  return join('&amp;' => @args);
}
# </sub to_string>

# <sub to_array>
# Return arg/value pairs as array (ref) of hash refs
#
# Usage:
#  $args = $cgi->to_array;          # ARRAY ref
#  $args = $cgi->to_array(%extra);  # ARRAY ref
#  @args = $cgi->to_array;          # ARRAY
#  @args = $cgi->to_array(%extra);  # ARRAY
#
sub to_array {
  my $self = shift;

  my %args = $self->current(FALSE, @_);
  my @args = ();
  foreach my $arg (sort keys %args) {
    push(@args => { 'arg'   => $arg,
                    'value' => $args{$arg} });
  }

  return wantarray() ? @args : \@args;
}
# </sub to_string>

# Shorthands for frequently used args
sub db             { shift->arg('db'             => @_); }
sub action         { shift->arg('action'         => @_); }
sub query          { shift->arg('query'          => @_); }
sub regexp         { shift->arg('regexp'         => @_); }
sub ranking        { shift->arg('ranking'        => @_); }
sub case_sensitive { shift->arg('case_sensitive' => @_); }
sub truncated      { shift->arg('truncated'      => @_); }
sub threshold      { shift->arg('threshold'      => @_); }
sub offset         { shift->arg('offset'         => @_); }
sub record_num     { shift->arg('record_num'     => @_); }
sub custom_ranking { shift->arg('custom_ranking' => @_); }

# <sub time>
# How long did the processing take?
sub time {
  my $self = shift;

  return sprintf("%0.4f", tv_interval($self->{'start'}))
}
# </sub time>

### /object methods/

1;
