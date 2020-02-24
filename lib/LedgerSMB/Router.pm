package LedgerSMB::Router;

=head1 NAME

LedgerSMB::Router - Module to dispatch web requests based on URL

=head1 DESCRIPTION

This module builds a map of URLs to application entry-points. In that sense,
it does the same as L<Path::Map>, L<Path::Router>, L<Router::Simple>,
L<Router::R3> and many others.

This module takes the same approach as L<Path::Map> (and possibly
L<Router::R3>) by building a tree of path segments and traversing the tree
while matching the path. This approach contrasts with e.g. L<Path::Router>
and L<Router::Simple> which build a list of all full paths, matching the
URL to be matched to each route in the list until the first match.

Algorithm complexity of path dispatch depends on the number of segments
in the path, for this module. For the modules which work off a list of
routes, the algorithm complexity depends on the number of routes to be
dispatched on.


Next to the router functionality, this module also provides a few DSL-like
keywords to help define


=head1 SYNOPSIS


   # register a router and import dsl keywords
   use LedgerSMB::Router appname => 'erp';

   get '/route/to/endpoint' => sub {
     my ($env) = @_;

     # return a PSGI tripple
     return [ 200, [], [ 'body']];
   };

   post '/route/to/:parameterized/:endpoint' => sub {
     my ($env, %params) = @_;

     # return a PSGI tripple
     return [ 200, [], [ 'body' ]];
   }

=cut

use strict;
use warnings;
use parent 'Exporter';

use Carp;
use HTTP::Status qw( HTTP_NOT_FOUND );
use JSON::MaybeXS;
use List::Util qw( reduce );

use LedgerSMB::Locale;
use LedgerSMB::Sysconfig;
use LedgerSMB::User;

use constant {
    MAP_NEXT    => 0,
    MAP_HANDLER => 1,
    MAP_NAMED   => 2,
    MAP_WILD    => 3,
    MAP_NAMES   => 4,
};

my $appname;
my $router = {};


our @EXPORT = ## no critic (ProhibitAutomaticExportation)
    qw(
    del get head patch post put
    json locale set user
    );
our @EXPORT_OK = qw(router);
our %EXPORT_TAGS = (
    all => [ qw( any del get head options patch post put
             hook json locale set user )]
    );

=head1 MODULE METHODS

=head2 import

=cut

sub import {
    my $pkg = shift;
    my %args = @_;

    $appname = $args{appname} // caller;
    $router->{$appname} //= __PACKAGE__->new;
    $router->{$appname}->{settings} = {};

    my @keywords = @{$args{keywords} // []};
    __PACKAGE__->export_to_level(1, $pkg, @{$args{keywords}});
}


sub _alloc_entry {
    return [ {}, undef, undef, undef, undef ];
}

=head2 new (constructor)



=cut

sub new {
    my ($class, $self) = @_;
    $self //= {
        _map     => _alloc_entry(),
        handlers => {},
        settings => {},
    };

    return bless $self, $class;
}


=head1 METHODS


=head2 add_mapping( $route => $handler )

Adds a mapping from a route to a handler to the router. Routes are paths;
routes consist of path segments which can be fixed, parameterized or - in
case of the last segment - be the catch-all pseudo-segment; e.g.:

  /fixed/path/segments
  /parameterized/:path/segments
  /route/to/catch/*

The above examples list, from top to bottom, a route with fixed segments,
a route with a parameterized segment (C<:path>, returned as the C<path>
parameter) and a route with a catch-all segment at the end.

The last route will match:

  /route/to/catch/fish
  /route/to/catch/fish/and/chips

The other two examples won't match more segments than the number in the route.

=cut

sub add_mapping {
    my ($self, $path, $handler) = @_;
    croak 'path should be defined' unless defined $path;

    my %names;
    my $segments;
    my $segment = 0;
    my $wild = 0;
    my $map = reduce {
        my ($m, $s) = ($a, $b);
        $segments = $segments ? "$segments/$s" : $s;
        croak "Wildcard before end of path in $path" if $wild;
        if ($s =~ m/^:(.+)$/) {
            $names{$1} = $segment;
            $m->[MAP_NAMED] = 1;
            $s = '/';
        }
        $m->[MAP_WILD] = $wild = 1 if ($s eq '*');
        if (($s ne '*' and $m->[MAP_WILD])
            or ($s eq '*' and %{$m->[MAP_NEXT]})) {
            croak "Unable to add path $path: wildcard collision at $segments";
        }
        $segment++;
        ($m->[MAP_WILD]
         ? $m
         : ($m->[MAP_NEXT]->{$s} //= _alloc_entry() ));
    } $self->{_map}, split( m{/} , $path, -1);
    croak "handler already defined at $path" if $map->[MAP_HANDLER];
    $map->[MAP_HANDLER] = $handler;
    $map->[MAP_NAMES] = \%names;

    return;
}

=head2 lookup($path)

Matches C<$path> against the registered routes, finding the most specific
matching route. E.g. when matching C</menu-nodes/new>, both routes below match:

   /menu-nodes/new
   /menu-nodes/:id

The first entry is the most specific one as C<:id> is a generic match whereas
C<new> is a specific match.

In a list context, this function returns C<($handler, \%values, \@wild)>; in
a scalar context, it returns a hash C<{ handler => $handler, values =>
\%values, wild => \@wild }>.

=cut

sub lookup {
    my ($self, $path) = @_;

    my @wild;
    my $m = $self->{_map};

    my @segments = split m{/}, $path, -1;
    for my $s (@segments) {
        if ($m->[MAP_WILD]) {
            push @wild, $s;
        }
        else {
            my $n = $m->[MAP_NEXT]->{$s};
            $m = (not defined $n and $m->[MAP_NAMED])
                ? $m->[MAP_NEXT]->{'/'} : $n;

            return undef unless defined $m;
        }
    }

    my %values;
    @values{keys %{$m->[MAP_NAMES]}} =
        @segments[values %{$m->[MAP_NAMES]}] if $m->[MAP_NAMES];

    if (wantarray) {
        return ($m->[MAP_HANDLER], \%values, \@wild);
    }
    else {
        return {
            handler => $m->[MAP_HANDLER],
            wild    => \@wild,
            values  => \%values,
        }
    }
}

=head2 dispatch($env)

Dispatches a request in a PSGI environment where routes have been registered
through the DSL keywords listed below. The dispatch parameters (REQUEST_METHOD
and PATH_INFO) are taken from C<$env>.

Returns a PSGI 'response triplet', or, a 404 response when no matching
route was found.

=cut

sub dispatch {
    my ($self, $env) = @_;
    my $url = $env->{PATH_INFO};

    my $method = $env->{REQUEST_METHOD};
    my ($h, $vals, $wild) = $self->lookup($url);
    my $route = $h->{$method} if $h;

    return [ HTTP_NOT_FOUND, [], [] ] unless $route;

    for my $hook ($self->hooks('before')) {
        $hook->($env, $route->{settings}, $self);
    }
    return $route->{handler}->($env, $vals, $wild);
}

=head2 hooks($name [ => @hooks])



=cut

sub hooks {
    my ($self, $name, @hooks) = @_;

    if (@hooks) {
        push @{$self->{hooks}->{$name} //= []}, @hooks;
    }

    return @{$self->{hooks}->{$name}};
}

=head2 setting($name, [$value])

If C<$value> is supplied, sets a configuration value to be used for all
entry points created after the setting has been modified.

Returns the value of the setting (after modification, if applicable).

=cut

sub setting {
    if (scalar @_ > 2) {
        $_[0]->{settings} = {
            ( %{$_[0]->{settings}},
              $_[1] => $_[2] )
        };
    }
    return $_[0]->{settings}->{$_[1]};
}

=head2 settings

Returns the settings as applied for new entry points.

=cut

sub settings {
    return $_[0]->{settings};
}


#####################################
#
#  DSL
#
#####################################

sub _add_mapping {
    my ($methods, $url, $handler) = @_;

    my $h = $router->{$appname}->{handlers}->{$url};
    if (! $h) {
        $h = {};
        $router->{$appname}->add_mapping($url => $h);
        $router->{$appname}->{handlers}->{$url} = $h;
    }
    my $endpoint =
        (ref $handler ne 'CODE') ? { ( %{$router->{$appname}->settings},
                                       %$handler ) }
    : {
        handler  => $handler,
        settings => $router->{$appname}->settings,
    };
    for my $method (map { uc $_ } @$methods) {
        $method = 'DELETE' if $method eq 'DEL';
        if (exists $h->{$method}) {
            croak "$method route for $url already exists";
        }
        $h->{$method} = $endpoint;
    }

    return;
}

=head1 DSL KEYWORDS

=head2 any \@request_types, $path => \&code
=head2 del $path => \&code
=head2 get $path => \&code
=head2 head $path => \&code
=head2 options $path => \&code
=head2 patch $path => \&code
=head2 post $path => \&code
=head2 put $path => \&code

=head2 hook $name => \&hook
=head2 json
=head2 locale $env
=head2 set $setting => 'value'
=head2 user $env

=cut

sub any     { _add_mapping(@_); }
sub del     { _add_mapping(['del'], @_); }
sub get     { _add_mapping(['get', 'head'], @_); }
sub options { _add_mapping(['options'], @_); }
sub patch   { _add_mapping(['patch'], @_); }
sub post    { _add_mapping(['post'], @_); }
sub put     { _add_mapping(['put'], @_); }


sub hook {
    my ($name, $hook) = @_;

    $router->{$appname}->hooks($name => $hook);

    return;
}

my $json = JSON::MaybeXS->new( pretty => 1,
                               utf8 => 1,
                               indent => 1,
                               convert_blessed => 1,
                               allow_bignum => 1);

sub json {
    return $json;
}

sub locale {
    my $env = shift;

    return $env->{'lsmb.locale'} //=
        LedgerSMB::Locale->get_handle(
            user($env)->{language} // LedgerSMB::Sysconfig::language()
        );
}

sub set {
    my ($setting, $value) = @_;

    $router->{$appname}->setting($setting, $value);

    return;
}


sub user {
    my $env = shift;
    $env->{'lsmb.user'} //= LedgerSMB::User->fetch_config(
        {
            dbh => $env->{'lsmb.app'},
        }) // {};
    return $env->{'lsmb.user'};
}

=head2 router $appname

Returns the router with routes registered for C<$appname> as created by
using this module;

  # create an 'erp' router
  use LedgerSMB::Router appname => 'erp';


  # create a 'LedgerSMB::MyPkg' router
  package LedgerSMB::MyPkg;
  use LedgerSMB::Router;


=cut

sub router {
    my ($appname) = @_;
    $appname //= caller;

    return $router->{$appname};
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
