package LedgerSMB::DBObject::Asset;

=head1 NAME

LedgerSMB::DBObject::Asset.pm, LedgerSMB Base Class for Fixed Assets

=head1 SYNOPSIS

This library contains the base utility functions for creating, saving, and
retrieving fixed assets for depreciation

=cut

use base qw(LedgerSMB::DBObject);
use strict;

sub save {
    my ($self) = @_;
    my ($ref) = $self->exec_method(funcname => 'asset__save');
    $self->merge($ref);
    $self->{dbh}->commit || $self->error(
                  $self->{_locale}->text("Unable to save [_1] object", 
                          $self->{_locale}->text('Asset'))
    );
    return $ref if $self->{dbh}->commit;
}

sub import_file {

    my $self = shift @_;

    my $handle = $self->{_request}->upload('import_file');
    my $contents = join("\n", <$handle>);

    $self->{import_entries} = [];
    for my $line (split /(\r\n|\r|\n)/, $contents){
        next if ($line !~ /,/);
        my @fields;
        $line =~ s/[^"]"",/"/g;
        while ($line ne '') {
            if ($line =~ /^"/){
                $line =~ s/"(.*?)"(,|$)//;
                my $field = $1;
                $field =~ s/\s*$//;
                push @fields, $field;
            } else {
                $line =~ s/([^,]*),?//;
                my $field = $1;
                $field =~ s/\s*$//;
                push @fields, $field;
            }
        }
        push @{$self->{import_entries}}, \@fields;
    }     
    unshift @{$self->{import_entries}}; # get rid of header line
    return @{$self->{import_entries}};
}


sub get {
    my ($self) = @_;
    my ($ref) = $self->exec_method(funcname => 'asset__get');
    $self->merge($ref);
    return $ref;
}

sub search {
    my ($self) = @_;
    my @results = $self->exec_method(funcname => 'asset_item__search');
    $self->{search_results} = \@results;
    return @results;
}

sub save_note {
    my ($self) = @_;
    my ($ref) = $self->exec_method(funcname => 'asset_item__add_note');
    $self->{dbh}->commit;
}

sub get_metadata {
    my ($self) = @_;
    @{$self->{asset_classes}} = $self->exec_method(funcname => 'asset_class__list');
   @{$self->{locations}} = $self->exec_method(funcname => 'warehouse__list_all');
   @{$self->{departments}} = $self->exec_method(funcname => 'department__list_all');
    @{$self->{asset_accounts}} = $self->exec_method(funcname => 'asset_class__get_asset_accounts');
    @{$self->{dep_accounts}} = $self->exec_method(funcname => 'asset_class__get_dep_accounts');
    @{$self->{exp_accounts}} = $self->exec_method(
                   funcname => 'asset_report__get_expense_accts'
    );
    my @dep_methods = $self->exec_method(
                                funcname => 'asset_class__get_dep_methods'
    );
    for my $dep(@dep_methods){
        $self->{dep_method}->{$dep->{id}} = $dep;
    }
    for my $acc (@{$self->{asset_accounts}}){
        $acc->{text} = $acc->{accno} . '--' . $acc->{description};
    }
    for my $acc (@{$self->{dep_accounts}}){
        $acc->{text} = $acc->{accno} . '--' . $acc->{description};
    }
    for my $acc (@{$self->{exp_accounts}}){
        $acc->{text} = $acc->{accno} . '--' . $acc->{description};
    }
}

sub get_next_tag {
    my ($self) =  @_;
    my ($ref) = $self->call_procedure(
          procname => 'setting_increment', 
          args     => ['asset_tag']
    );
    $self->{tag} = $ref->{setting_increment};
    $self->{dbh}->commit;
}

sub import_asset {
    my ($self) =  @_;
    my ($ref) = $self->exec_method(funcname => 'asset_report__import');
    return $ref;
}

sub get_invoice_id {
    my ($self) = @_;
    my ($ref) = $self->exec_method(funcname => 'get_vendor_invoice_id');
    if (!$ref) {
        $self->error($self->{_locale}->text('Invoice not found'));
    } else {
        $self->{invoice_id} = $ref->{get_vendor_invoice_id};
    }
}

1;
