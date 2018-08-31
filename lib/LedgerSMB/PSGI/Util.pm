
package LedgerSMB::PSGI::Util;

=head1 NAME

LedgerSMB::PSGI::Util - LedgerSMB PSGI Utility functions

=head1 SYNOPSIS

  return
     LedgerSMB::PSGI::Util::internal_server_error('error','Title',
                                 'company', $request->{dbversion});

=head1 DESCRIPTION

LedgerSMB::Middleware::DynamicLoadWorkflow makes sure the new-style
workflow scripts have successfully been loaded before being dispatched to.

This module implements the C<Plack::Middleware> protocol.

=cut

use strict;
use warnings;

use parent qw(Exporter);

use Carp;
use HTTP::Status qw( HTTP_OK HTTP_INTERNAL_SERVER_ERROR HTTP_SEE_OTHER
    HTTP_UNAUTHORIZED );

our @EXPORT = ## no critic
    qw( input_map );

=head1 METHODS

This module declares no methods.

=head1 FUNCTIONS

=head2 internal_server_error($msg, $title, $company, $dbversion)

Returns a standard error representation for HTTP status 500

=cut


sub internal_server_error {
    my ($msg, $title, $company, $dbversion) = @_;

    $title //= 'Error!';
    $msg =~ s/\n/<br>/g;
    my @body_lines = ( '<html><body>',
                       q{<h2 class="error">Error!</h2>},
                       "<p><b>$msg</b></p>" );
    push @body_lines, '<p>dbversion: ' . ($dbversion // '') .
         ', company: ' . ($company // '') . '</p>'
        if $company || $dbversion;

    push @body_lines, '</body></html>';

    return [ HTTP_INTERNAL_SERVER_ERROR,
             [ 'Content-Type' => 'text/html; charset=UTF-8' ],
             \@body_lines ];
}


=head2 unauthorized()

Returns a standard error representation for HTTP status 401

=cut

sub unauthorized {
    return [ HTTP_UNAUTHORIZED,
             [ 'Content-Type' => 'text/plain; charset=utf-8',
               'WWW-Authenticate' => 'Basic realm=LedgerSMB' ],
             [ 'Please enter your credentials' ]
        ];
}

=head2 session_timed_out()

Returns a standard error representation for 'LedgerSMB session timed out'

=cut

sub session_timed_out {
    return [ HTTP_SEE_OTHER,
             [ 'Location' => 'login.pl?action=logout&reason=timeout' ],
             [] ];
}


=head2 incompatible_database($expected, $actual)

Returns a standard error representation for 'LedgerSMB database version
incompatible'

=cut

sub incompatible_database {
    my ($expected, $actual) = @_;

    return
        [ 521, ## no critic
          [ 'Content-Type' => 'text/html; charset=utf-8' ],
          [ 'Database is not the expected version.  ' .
            "Was $actual, expected $expected.  " .
            'Please re-run <a href="setup.pl">setup.pl</a> to correct.' ] ];
}


=head2 template_to_psgi($template, %args)

Returns a PSGI return value triplet (status, headers and body).

Note that the only guarantee here is that the triplet can
be used as a PSGI return value which means that the body
is *not* restricted to being an array of strings.

When C<extra_headers> is specified in the C<%args> hash, these are
included in the headers part of returned triplet.

=cut


sub template_to_psgi {
    my $self = shift @_;
    my %args = ( @_ );

    my $charset = '';
    $charset = '; charset=utf-8'
        if $self->{mimetype} =~ m!^text/!;

    # $self->{mimetype} set by format
    my $headers = [
        'Content-Type' => "$self->{mimetype}$charset",
        (@{$args{extra_headers} // []})
        ];

    # Use the same Content-Disposition criteria as _http_output()
    my $name = $self->{output_options}{filename};
    if ($name) {
        $name =~ s#^.*/##;
        push @$headers,
            ( 'Content-Disposition' =>
              qq{attachment; filename="$name"} );
    }

    my $body = $self->{output};
    utf8::encode($body) if utf8::is_utf8($body); ## no critic

    return [ HTTP_OK, $headers, [ $body ] ];
}

=head2 input_map([ qr/regex1/ => $spec1], [ qr/regex2/ => $spec2], ...)

Returns a function reference of a single argument which maps a the values
of a "flat" hash structure into a hierarchical data representation as
specified by C<$spec1>, C<$spec2>, ... .

   my $map = input_map( [....], [...], ...);
   my $mapped_input = $map->({ dummy => $val1, key => $val2 });

The values C<$specN> specify the path to traverse in the hierarchical
dataset to reach the point where the value associated with the key
matching C<regexN> is to be stored.
The steps in the path are separated by colons (':'). Steps can take
one of four forms:

=over

=item ignored value (!)

If the C<$spec> exactly equals '!', the value isn't mapped into
the target structure, but the key/value pair is ignored.

=item static hash key (%key)

Takes the form of a percent sign ('%') followed by the static
hash key.

=item dynamic hash key (%<key>)

Takes the form of a percent sign followed by a parameter name
in angle brackets. The value of the hash key is taken from the
equally named match in the regex. E.g.

  [ qr/(?<foo>bar)/ => '%<foo>' ]

binds 'bar' (the match) to the match-variable 'foo', which is then
used in the expansion of '%<foo>' which then becomes equivalent to
'%bar'.

=item array element (@baz<foo>)

Takes the form of an 'at' sign followed by a hash key name
followed by a parameter name in angle brackets. The parameter
name in angle brackets specifies which match value from the
regex is to be used to look up the row by.
The hash key after the '@'-sign serves to indicate which of the
values at hash in the path traversal contains the array to look
up from.

=back


Consider the following mapping:

  [ qr/^(?<key>(date)?paid.*)_(?<row>\d+)$/ => '%payments:@rows<row>:%<key>' ]

The regex contains 2 named matches (C<key> and C<row>) which are available
for use in the expansion of the path in the traversal specification.

The traversal specification specifies the following nesting:

  {
     payments => {
        rows => [ {
            __row_id => C<row>,
            C<key> => $value
           },
        ],
     }
  }

where C<$value> is the value associated with the key being matched in the
map's flat input hash.

=cut

sub _find_row {
    my ($ref, $arr, $row_id) = @_;

    if (! defined $ref->{$arr}) {
        $ref->{$arr} = [];
    }

    my $row_ref;
    for my $row (@{$ref->{$arr}}) {
        $row_ref = $row
            if $row->{__row_id} eq $row_id;
    }
    if (! defined $row_ref) {
        $row_ref = {
            __row_id => $row_id
        };
        push @{$ref->{$arr}}, $row_ref;
    }

    return $row_ref;
}

sub _compile_spec {
    my ($target_spec) = @_;

    return '' if $target_spec eq '!'; # ignore
    my $code = '';

    my @lookup_steps = split(/:/, $target_spec);
    for my $stepnum (0 ..  $#lookup_steps) {
        my $step = $lookup_steps[$stepnum];

        my $deref = substr($step, 0, 1);
        if (substr($step, 0, 2) eq '%<') {
            my $var = substr($step, 2, length($step) - 3);
            if ($stepnum != $#lookup_steps) {
                $code .= qq{
      \$deref = (\$deref->{\$matches->{"$var"}} //= {});};
            }
            else {
                $code .= qq{
      \$deref->{\$matches->{"$var"}} = \$r->{\$key};}
            }
        }
        elsif ($deref eq '%') {
            my $var = substr($step, 1, length($step) - 1);
            if ($stepnum != $#lookup_steps) {
                $code .= qq{
      \$deref = (\$deref->{"$var"} //= {});};
            }
            else {
                $code .= qq{
      \$deref->{"$var"} = \$r->{\$key};};
            }
        }
        elsif ($deref eq '@') {
            $step =~ /\@(?<arr>[^<]+)\<(?<matchvar>.+)\>/;
            my $var = $+{matchvar};
            my $arr = $+{arr};
            if ($stepnum != $#lookup_steps) {
                $code .= qq{
      \$deref = _find_row(\$deref, "$arr", \$matches->{"$var"});};
            }
            else {
                die q{Can't assign directly to the array};
            }
        }
        else {
            croak 'Unsupported targetspec definition';
        }
    }

    return $code;
}

sub _compile_match {
    my ($matcher) = @_;
    my ($match_re, $tgt_spec) = @$matcher;

    return qq,
    # $tgt_spec
    if (\$key =~ /$match_re/) {
      my \$matches = \\\%+;
, . _compile_spec($tgt_spec) . q,

      delete $r->{"$key"};
      next;
    }
,;

}

sub input_map {
    my @rules = @_;
    my $code = eval
q,
sub {
 my ($r) = @_; # flat input 'request' record

 my $rv = {};
 for my $key (keys %$r) {
    my $deref = $rv;
, .
    join('', map { _compile_match($_) } @rules)
. q,
 }
 return $rv;
}
,;

    if (not defined $code and defined $@) {
        croak $@;
    }
    return $code;
}



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
