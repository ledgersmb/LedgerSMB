#!/usr/bin/perl
=head1 NAMR

LedgerSMB::Database

=head1 SYNOPSIS

This module provides the APIs for database creation and management

=head1 COPYRIGHT

This module is copyright (C) 2007, the LedgerSMB Core Team and subject to 
the GNU General Public License (GPL) version 2, or at your option, any later
version.  See the COPYRIGHT and LICENSE files for more information.

=head1 METHODS

=over

=cut

# Methods are documented inline.  

package LedgerSMB::Database;

our $VERSION = '0';

use LedgerSMB::Sysconfig;
use base('LedgerSMB');

=item LedgerSMB::Database->new({dbname = $dbname, countrycode = $cc, chart_name = $name, company_name = $company, username = $username, password = $password})

This function creates a new database management object with the specified
characteristics.  The $dbname is the name of the database. the countrycode
is the two-letter ISO code.  The company name is the friendly name for 
dropdown boxes on the Login screen.

As some countries may have multiple available charts, you can also specify
a chart name as well.

Note that the arguments can be any hashref. If it is a LedgerSMB object,
however, it will attempt to copy all attributes beginning with _ into the 
current object (_user, _locale, etc).

=cut

sub new {
    my ($class, $args) = @_;

    my $self = {};
    for (qw(dbname countrycode chart_name company_name username password)){
        $self->{$_} = $args->{$_};
    }
    if (isa($args, 'LedgerSMB')){
        for (keys %$args){
            if ($_ =~ /^_/){
                $self->{$_} = $arg->{$_};
            }
        }
    }
    bless $self, $class;
    return $self;
}

=item $db->create();

Creates a database with the characteristics in the object

=cut

sub create {
    my $self = (@_);
    $self->_init_environment();
    `createdb $self->{dbname}`;
    my $error = $!;
    if ($error){
        $self->error($!);
    }
    for (qw(Database Central)){
        $self->_execute_script("Pg-$_.sql");
    }
    my $chart_path = "sql/$self->{country_code}/";
    $self->_execute_script(
        "coa/$self->{country_code}/chart/$self->{chart_name}"
    );
    my @gifis = glob('sql/$self->{country_code}/gifi/*.sql');
    my @gifi_search;
    my $search_string = $self->{chart_name};
    while ($search_string and (scalar @gifi_search == 0)){
        @gifi_search = grep /^$search_string.sql$/, @gifis;
        if (scalar @gifi_search == 0){
            if ($search_string !~ /[_-]/){
                $search_string = "";
            } else {
                $search_string =~ s/(.*)[_-].*$/$1/;
            }
        }
    }
    if (! scalar @gifi_search){
        push @gifi_search, 'Default';
    }
    my $gifi = $gifi_search[0];
    $gifi =~ s/\.sql$//;
    $self->_execute_script("coa/$self->{country_code}/gifi/$gifi");
    $self->_create_roles();
}

# Private method.  Executes the sql script in psql.
sub _execute_script {
    my ($self, $script) = @_;
    `psql $self->{dbname} < 'sql/$script.sql'`;
    return $!;
}

sub _create_roles {
    #TODO
}

sub update {
    # TODO
}

=back
