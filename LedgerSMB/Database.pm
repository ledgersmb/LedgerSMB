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
use strict;

my $temp = $LedgerSMB::Sysconfig::temp_dir;

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
    for (qw(countrycode chart_name chart_gifi company_name username password
            contrib_dir source_dir)){
        $self->{$_} = $args->{$_};
    }
    if ($self->{source_dir}){
        $self->{source_dir} =~ s/\/*$/\//;
    }
    if (isa($args, 'LedgerSMB')){
        for (keys %$args){
            if ($_ =~ /^_/){
                $self->{$_} = $args->{$_};
            }
        }
    }
    bless $self, $class;
    return $self;
}

=item $db->create();

Creates a database and loads the contrib files.

Returns true if successful, false of not.  Creates a log called dblog in the 
temporary directory with all the output from the psql files.  

In DEBUG mode, will show all lines to STDERR.  In ERROR logging mode, will 
display only those lines containing the word ERROR.

=cut

sub create {
    my ($self) = @_;
    
    my $rc = system("createdb -E UTF8 > $temp/dblog");

     my @contrib_scripts = qw(pg_trgm tsearch2 tablefunc);

     for my $contrib (@contrib_scripts){
         my $rc2;
         $rc2=system("psql -f $ENV{PG_CONTRIB_DIR}/$contrib.sql >>$temp/dblog");
         $rc ||= $rc2
     }
     if (!system("psql -f $self->{source_dir}sql/Pg-database.sql >> $temp/dblog"
     )){
         $rc = 1;
     }
     # TODO Add logging of errors/notices

     return !$rc;
}

=item $db->load_modules($loadorder)

Loads or reloads sql modules from $loadorder

=cut

sub load_modules {
    my ($self, $loadorder) = @_;
    open (LOADORDER, '<', "$self->{source_dir}sql/modules/$loadorder");
    for my $mod (<LOADORDER>){
        chomp($mod);
        $mod =~ s/#.*//;
        $mod =~ s/^\s*//;
        $mod =~ s/\s*$//;
        next if $mod eq '';
        $self->exec_script({script => "$self->{source_dir}sql/modules/$mod",
                            log    => "$temp/dblog"});

    }
    close (LOADORDER);
}

=item $db->exec_script({script => 'path/to/file', logfile => 'path/to/log'})

Executes the script.  Returns 0 if successful, 1 if there are errors suggesting
that types are already created, and 2 if there are other errors.

=cut

sub exec_script {
    my ($self, $args) = @_;
    open (LOG, '>>', $args->{log});
    open (PSQL, '-|', "psql -f $args->{script}");
    my $test = 0;
    while (my $line = <PSQL>){
        if ($line =~ /ERROR/){
            if (($test < 2) and ($line =~ /relation .* exists/)){
                $test = 1;
            } else {
                $test  =2;
            }
        }
        print LOG $line;
    }
    close(PSQL);
    close(LOG);
    return $test;
}

=item $db->create_and_load();

Creates a database and then loads it.

=cut

sub create_and_load(){
    my ($self) = @_;
    $self->create();
    $self->load_modules('LOADORDER');
}


=item $db->process_roles($rolefile);

Loads database Roles templates.

=cut

sub process_roles {
    my ($self, $rolefile) = @_;

    open (ROLES, '<', "sql/modules/$rolefile");
    open (TROLES, '>', "$temp/lsmb_roles.sql");

    for my $line (<ROLES>){
        $line =~ s/<\?lsmb dbname \?>/$self->{company_name}/;
        print TROLES $line;
    }

    close ROLES;
    close TROLES;

    $self->exec_script({script => "sql/modules/$rolefile", 
                        log    => "$temp/dblog"});
}

=item $db->log_from_logfile();

Process log file and log relevant pieces via the log classes.

=cut

#TODO
