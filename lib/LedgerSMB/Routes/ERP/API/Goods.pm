package LedgerSMB::Routes::ERP::API::Goods;

=head1 NAME

LedgerSMB::Routes::ERP::API::Goods - Webservice routes for goods & services

=head1 DESCRIPTION

Webservice routes for goods & services

=head1 SYNOPSIS

  use LedgerSMB::Routes::ERP::API::Goods;

=head1 METHODS

This module doesn't export any methods.

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_OK );
use Plack::Request::WithEncoding;

use LedgerSMB::Part;
use LedgerSMB::Router appname => 'erp/api';

set logger => 'erp.api.goods';


get '/goods/' => sub {
    my ($env) = @_;
    my $r = Plack::Request::WithEncoding->new($env);
    my $type = ($r->parameters->{type} =~ s/[*]//gr);
    my $partnumber = ($r->parameters->{partnumber} =~ s/[*]//gr);
    my $description = ($r->parameters->{description} =~ s/[*]//gr);

    return [ 200, [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             [ json()->encode(
                   [
                    grep { (! $type) ||
                               ($type eq 'sales' && $_->{income_accno_id}) ||
                               ($type eq 'purchase' && $_->{expense_accno_id}) }
                    grep { ! $_->{obsolete} }
                    map { $_->{label} = $_->{partnumber} . '--' . $_->{description}; $_ }
                    LedgerSMB::Part->new(_dbh => $env->{'lsmb.app'})
                    ->basic_partslist(
                        partnumber => $partnumber,
                        description => $description)
                   ]
               ) ] ];
};


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
