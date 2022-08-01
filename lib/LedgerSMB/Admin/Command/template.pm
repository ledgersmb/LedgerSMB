
package LedgerSMB::Admin::Command::template;

=head1 NAME

LedgerSMB::Admin::Command::template - ledgersmb-admin 'template' command

=cut

use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use DateTime::Format::Strptime;

use LedgerSMB::Admin::Command;
use LedgerSMB::Database;

use Moose;
extends 'LedgerSMB::Admin::Command';
use namespace::autoclean;


sub list {
    my ($self, $dbh, $options, @args) = @_;
    my $templates = $dbh->selectall_arrayref(
        'SELECT template_name, format, language_code, last_modified
           FROM template',
        { Slice => {} },
        )
        or die $dbh->errstr;
    my $template;
    # Formats are far from ideal, but exactly the right tool
    # for a simple CLI's formatting requirements based on fixed column
    # layout... Override Perl::Critic
    ## no critic (ProhibitFormats)
format LANG =
@<<<<<<<<<<<<<<<<<<<<<<@<<<<<<@<<<<<<<<<@<<<<<<<<<<<<<<<<<<
$template->{template_name},$template->{format},$template->{language_code},$template->{last_modified}
.
format LANG_TOP =
-----------------------------------------------------------
Template name          Format Language  Last modified
-----------------------------------------------------------
.

    local $^ = 'LANG_TOP';
    local $~ = 'LANG';
    for $template (sort
                   {
                       $a->{template_name} cmp $b->{template_name}
                       or $a->{format} cmp $b->{format}
                   } $templates->@*) {
        $template->{language_code} //= 'all';
        write;
    }

    $dbh->disconnect;
    return 0;
}

sub dump {
    my ($self, $dbh, $options, @args) = @_;
    my ($db, $name, $format, $language) = @args;
    $language = undef if $language eq 'all';
    my $template = $dbh->selectall_arrayref(
        q{SELECT template FROM template
           WHERE ($1 is null OR template_name = $1)
             AND ($2 is null OR format is null or format = $2)
        AND ($3 is null OR language_code = $3)},
        { Slice => {} },
        $name, $format, $language)
        or die $dbh->errstr;

    print $template->[0]->{template};
    $dbh->disconnect;
    return 0;
}

sub archive {
    my ($self, $dbh, $options, @args) = @_;
    my ($db, $archive, $name, $format, $language) = @args;

    # Create a Zip file
    my $zip = Archive::Zip->new();

    $archive //= 'templates.zip';

    $name = undef if $name && $name eq 'all';
    $format = undef if $format && $format eq 'all';
    $language = undef if $language && $language eq 'all';

    my $template = $dbh->selectall_arrayref(
        q{SELECT * FROM template
           WHERE ($1 is null OR template_name = $1)
             AND ($2 is null OR format is null or format = $2)
        AND ($3 is null OR language_code = $3)},
        { Slice => {} },
        $name, $format, $language)
        or die $dbh->errstr;

    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%F%t%T'
    );
    foreach my $t (@$template){
        my $l = $t->{language_code} ? "-$t->{language_code}" : '';
        # Add a file from a string with compression
        my $file = $zip->addString( $t->{template},
                                "$t->{template_name}$l.$t->{format}" );
        $file->desiredCompressionMethod( COMPRESSION_DEFLATED );
        $file->setLastModFileDateTimeFromUnix(
            $strp->parse_datetime($t->{last_modified})->epoch
        );
    }

    # Save the Zip file
    unless ( $zip->writeToFileNamed($archive) == AZ_OK ) {
        die 'write error';
    }

    $dbh->disconnect;
    return 0;
}

sub load {
    my ($self, $dbh, $options, @args) = @_;
    my ($db, $name, $format, $language) = @args;
    $language = undef if $language eq 'all';

    my $content;
    {
        local $/ = undef;
        $content = <STDIN>;
    }
    $dbh->do(q{DELETE FROM template
                WHERE ($1 is null OR template_name = $1)
                  AND ($2 is null OR format is null or format = $2)
                  AND ($3 is null OR language_code = $3)},
             {},
             $name, $format, $language)
        or die $dbh->errstr;
    ###TODO: check number of affected rows! (should be 0 or 1, no more!)

    $dbh->do(q{INSERT INTO template
                 (template_name, format, language_code, template)
             VALUES (?,?,?,?)},
             {},
             $name, $format, $language, $content);

    $dbh->commit;
    $dbh->disconnect;
    return 0;
}

sub _before_dispatch {
    my ($self, $options, @args) = @_;

    my $db_uri = (@args) ? $args[0] : undef;
    $self->db(
        LedgerSMB::Database->new(
            connect_data => {
                $self->config->get('connect_data')->%*,
                $self->connect_data_from_arg($db_uri)->%*,
            },
            schema => $self->config->get('schema')
        ));
    return ($self->db->connect(), $options, @args);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

   ledgersmb-admin template help
   ledgersmb-admin template list <db-uri>
   ledgersmb-admin template dump <db-uri> <name> <format> [<language>]
   ledgersmb-admin template archive <db-uri> <archive> <name> <format> [<language>]
   ledgersmb-admin template load <db-uri> <name> <format> [<language>]

=head1 DESCRIPTION

This command allows you to query the and modify the templates stored
in the database. These subcommands are supported:

=head1 SUBCOMMANDS

=head2 list <db-uri>

Lists the templates stored in the database

=head2 dump <db-uri> <name> <format> [<language>]

Dumps the content of a specific template to STDOUT. The values
of the arguments must be equal to in the output of the 'list'
command. When not specified, <language> is assumed to be equal
to 'all'.

=head2 archive <db-uri> [<archive>] [<name>] [<format>] [<language>]

Archive the templates in file <archive>, defaulting to templates.zip
The values of the arguments selects the desired templates.
When any it not specified, 'all' is assumed.

=head2 load <db-uri> <name> <format> [<language>]

Stores the content of a template read from STDIN into the database.
The values of the arguments must be equal to in the output of the
'list' command. When not specified, <language> is assumed to be
equal to 'all'.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

