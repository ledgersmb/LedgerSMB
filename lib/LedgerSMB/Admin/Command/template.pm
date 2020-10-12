
package LedgerSMB::Admin::Command::template;

=head1 NAME

LedgerSMB::Admin::Command::template - ledgersmb-admin 'template' command

=cut

use strict;
use warnings;

use LedgerSMB::Admin::Command;

use Moose;
extends 'LedgerSMB::Admin::Command';
use namespace::autoclean;


sub list {
    my ($self, $dbh, @args) = @_;
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
    my ($self, $dbh, @args) = @_;
    my ($name, $format, $language) = @args;
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

sub load {
    my ($self, $dbh, @args) = @_;
    my ($name, $format, $language) = @args;
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
    my ($self, @args) = @_;
    my @rv = $self->SUPER::_before_dispatch(@args);

    return ($self->db->connect, @rv);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

   ledgersmb-admin template help
   ledgersmb-admin template list
   ledgersmb-admin template dump <name> <format> [<language>]
   ledgersmb-admin template load <name> <format> [<language>]

=head1 DESCRIPTION

This command allows you to query the and modify the templates stored
in the database. These subcommands are supported:

=head1 SUBCOMMANDS

=head2 list

Lists the templates stored in the database

=head2 dump <name> <format> [<language>]

Dumps the content of a specific template to STDOUT. The values
of the arguments must be equal to in the output of the 'list'
command. When not specified, <language> is assumed to be equal
to 'all'.

=head2 load <name> <format> [<language>]

Stores the content of a template read from STDIN into the database.
The values of the arguments must be equal to in the output of the
'list' command. When not specified, <language> is assumed to be
equal to 'all'.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

