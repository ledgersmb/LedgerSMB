
package LedgerSMB::Admin::Command::setup;

=head1 NAME

LedgerSMB::Admin::Command::setup - ledgersmb-admin 'setup' command

=cut

use strict;
use warnings;

use LedgerSMB::Admin::Command;
use LedgerSMB::Company;

use Moose;
extends 'LedgerSMB::Admin::Command';
use namespace::autoclean;


sub load {
    my ($self, $company, @args) = @_;
    my ($file) = @args;
    my $config = $company->configuration;
    my $fh;

    if (not -f $file) {
        $self->logger->error("Input file $file not found");
        return 1;
    }

    if (not open $fh, '<:encoding(UTF-8)', $file) {
        $self->logger->error("Can't open file $file: $!");
        return 1;
    }

    $config->from_xml($fh);

    close $fh
        or $self->logger->warn("Can't close file $file: $!");

    $company->dbh->commit;
    $company->dbh->disconnect;
    $self->logger->error("Succesfully loaded configuration $file");
    return 0;
}

sub _before_dispatch {
    my ($self, @args) = @_;
    my @rv = $self->SUPER::_before_dispatch(@args);

    return (LedgerSMB::Company->new(dbh => $self->db->connect), @rv);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

   ledgersmb-admin setup help
   ledgersmb-admin setup load <setup>

=head1 DESCRIPTION

...

These subcommands are supported:

=head1 SUBCOMMANDS

=head2 load <name> <setup>

...

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

