package LedgerSMB::Routes::ERP::API::Templates;

=head1 NAME

LedgerSMB::Routes::ERP::API::Templates - Webservice routes for doc templates

=head1 DESCRIPTION

Webservice routes for document templates

=head1 SYNOPSIS

  use LedgerSMB::Routes::ERP::API::Templates;

=head1 METHODS

This module doesn't export any methods.

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_OK HTTP_NOT_FOUND HTTP_NO_CONTENT HTTP_BAD_REQUEST );
use Plack::Request::WithEncoding;

use LedgerSMB::Part;
use LedgerSMB::Router appname => 'erp/api';
use LedgerSMB::Template::DB;

set logger => 'erp.api.templates';


get '/templates/' => sub {
    my ($env) = @_;
    my $app = $env->{'lsmb.app'};

    my $query = 'select id, template_name, language_code, format from template';
    ###TODO: this breaks when we run in another schema...

    return [
        HTTP_OK,
        [ 'Content-Type' => 'application/json; charset=UTF-8' ],
        [ json()->encode(
              [
               ###TODO: should be $env->{SCRIPT_NAME} ?
               map { $_->{src} = "/erp/api/v0/templates/$_->{id}/content" ;
                     $_
               }
               $app->selectall_array($query, { Slice => {} }) ]
          )
        ]
        ];
};

sub _query_template {
    my $env = shift;
    my $app = $env->{'lsmb.app'};
    my $dbtemplate;
    local $@ = undef;
    eval {
        $dbtemplate = LedgerSMB::Template::DB->get(
            @_,
            dbh => $app
            );
    };

    if (defined $dbtemplate) {
        return [
            HTTP_OK,
            [ 'Content-Type' => 'text/plain; charset=UTF-8' ],
            [ $dbtemplate->template ]
            ];
    }
    else {
        return [
            HTTP_NOT_FOUND,
            [ 'Content-Type' => 'text/plain' ],
            [ 'Template not found' ]
            ];
    }
}


get '/templates/:id/content' => sub {
    my ($env, $match) = @_;
    return [ HTTP_NOT_FOUND, [], [] ]
        unless $match->{id} =~ m/^\d+$/;

    return _query_template($env, id => $match->{id});
};

get '/templates/:name/:format/:language' => sub {
    my ($env, $match) = @_;
    delete $match->{language} if $match->{language} eq '__all__';

    return _query_template($env,
                           template_name => $match->{name},
                           format        => $match->{format},
                           language      => $match->{language});
};

put '/templates/:id/content' => sub {
    my ($env, $match) = @_;
    return [ HTTP_NOT_FOUND, [], [] ]
        unless $match->{id} =~ m/^\d+$/;

    my $app = $env->{'lsmb.app'};
    my $req = Plack::Request::WithEncoding->new($env);
    my $done;
    local $@ = undef;
    eval {
        my $dbtemplate = LedgerSMB::Template::DB->get(
            id       => $match->{id},
            dbh      => $app,
            );
        $dbtemplate->template($req->content);
        $dbtemplate->save;
        $done = 1;
    };

    return [
        $done ? HTTP_NO_CONTENT : HTTP_BAD_REQUEST,
        [ ], [ ] ];
};

put '/templates/:name/:format/:language' => sub {
    my ($env, $match) = @_;
    delete $match->{language} if $match->{language} eq '__all__';

    my $app = $env->{'lsmb.app'};
    my $req = Plack::Request::WithEncoding->new($env);
    my $done;
    local $@ = undef;
    eval {
        my $dbtemplate = LedgerSMB::Template::DB->new(
            template_name => $match->{name},
            format        => $match->{format},
            language      => $match->{language},
            dbh           => $app
            );
        $dbtemplate->template($req->content);
        $dbtemplate->save;
        $done = 1;
    };

    return [
        $done ? HTTP_NO_CONTENT : HTTP_BAD_REQUEST,
        [ ], [ ] ];
};

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
