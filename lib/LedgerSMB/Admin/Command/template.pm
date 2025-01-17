
package LedgerSMB::Admin::Command::template;

=head1 NAME

LedgerSMB::Admin::Command::template - ledgersmb-admin 'template' command

=cut

use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use DateTime::Format::Strptime;
use File::Spec;
use IO::Handle;

use LedgerSMB::Admin::Command;
use LedgerSMB::App_State;
use LedgerSMB::Database;
use LedgerSMB::Template::DB;

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
    $language = undef if $language and $language eq 'all';
    my $template = $dbh->selectall_arrayref(
        q{SELECT template FROM template
           WHERE ($1 is null OR template_name = $1)
             AND ($2 is null OR format is null or format = $2)
        AND ($3 is null OR language_code = $3)},
        { Slice => {} },
        $name, $format, $language)
        or die $dbh->errstr;
    $dbh->disconnect;

    STDOUT->flush();
    binmode STDOUT, ':encoding(UTF-8)';
    print $template->[0]->{template};
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
        binmode STDIN, ':encoding(UTF-8)';
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


sub load_all {
    my ($self, $dbh, $options, @args) = @_;
    my ($db, $dir) = @args;

    local $LedgerSMB::App_State::DBH = $dbh;
    if (opendir my $dh, $dir) {
        for my $template (readdir $dh) {
            next if ($template eq '.' or $template eq '..');
            my $path = File::Spec->catfile($dir, $template);
            if (-f $path) {
                $self->logger->info("Loading template $template");
                my $dbtemp = LedgerSMB::Template::DB->get_from_file($path);
                $dbtemp->save;
            }
            else {
                $self->logger->debug("Skipping non-file path $template in templates directory");
            }
        }
        closedir $dh
            or $self->logger->warn("Failed to close directory: $@");
    }
    else {
        $self->logger->error("Failed to read file list from directory '$dir': $@");
        $dbh->rollback;
    }

    $dbh->commit;
    $dbh->disconnect;
    return 0;
}


sub _before_dispatch {
    my ($self, $options, @args) = @_;

    my $db_uri = (@args) ? $args[0] : undef;
    my $connect_data = {
        $self->config->get('connect_data')->%*,
        $self->connect_data_from_arg($db_uri)->%*,
    };
    $self->db(
        LedgerSMB::Database->new(
            connect_data => $connect_data,
            source_dir   => $self->config->sql_directory,
            schema       => $self->config->get('schema'),
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
   ledgersmb-admin template load-all <db-uri> <directory>

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

=head2 load-all <db-uri> <directory>

Stores the content of all templates read from the input directory into
the database similar to selecting the template-set from the company
creation process in C<setup.pl>.

Important: if the templates in the database have been edited, these edits
are lost as all templates are overwritten.

=head1 METHODS

=head2 load_all

This method implements the 'load-all' command.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020-2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

