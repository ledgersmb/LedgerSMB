
package LedgerSMB::Scripts::business_unit;

=head1 NAME

LedgerSMB::Scripts::business_unit - web entry points for reporting class admin

=head1 DESCRIPTION

Workflow routines for LedgerSMB business reporting units

=head1 METHODS

This module doesn't specify any methods.

=cut

use strict;
use warnings;

use Carp;

use LedgerSMB::App_Module;
use LedgerSMB::Business_Unit;
use LedgerSMB::Business_Unit_Class;
use LedgerSMB::PGDate;
use LedgerSMB::Report::Listings::Business_Unit;
use LedgerSMB::Setting::Sequence;

=head1 FUNCTIONS

All functions take a single $request object as their sole argument

=over

=item list_classes

=cut

sub list_classes {
    my ($request) = @_;
    my $bu_class = LedgerSMB::Business_Unit_Class->new(%$request);
    my $lsmb_modules = LedgerSMB::App_Module->new(%$request);
    @{$request->{classes}} = $bu_class->list;
    @{$request->{modules}} = $lsmb_modules->list;
    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'business_units/list_classes',
                             {request => $request});
}

=item add

Adds a new business unit.  $request->{class_id} must be set.

=cut

sub add {
    my ($request) = @_;
    if (!$request->{class_id}){
        $request->{class_id} = $request->{id};
        delete $request->{id};
    }
    @{$request->{sequences}} =
          LedgerSMB::Setting::Sequence->list('projectnumber')
          unless $request->{id};
    $request->{control_code} = '';
    $request->{description} = '';
    $request->{id} = undef;
    $request->{mode} = 'add';
    my $b_unit = LedgerSMB::Business_Unit->new(%$request);
    return _display($request, {
        parent_options => [ $b_unit->list($request->{class_id} ) ],
        %$b_unit });
}

=item edit

Edits an existing business unit.  $request->{id} must be set.

=cut

sub edit {
    my ($request) = @_;
    $request->{control_code} = '';
    $request->{class_id} = 0 unless $request->{class_id};
    my $b_unit = LedgerSMB::Business_Unit->new(%$request);
    my $bu = $b_unit->get($request->{id});
    @{$bu->{parent_options}} = $b_unit->list($bu->{class_id});
    $bu->{mode} = 'edit';

    return _display($request, $bu);
}

sub _display {
    my ($request, $bu) = @_;
    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'business_units/edit', $bu);

}

=item list

Lists business units.  The following properties of $request may be set:

=over

=item class_id (required)

Lists units for appropriate class.

=item active_on

If set filters for units active on the date in question, inclusive of start/end
dates

=item credit_id

If set, filters excludes those which are for customers/vendors other than than
identified by this value.

=item strict_credit_id

If set, excludes those which are not associated with customers/vendors.

=back

=cut

sub list {
    my ($request) = @_;
    return $request->render_report(
        LedgerSMB::Report::Listings::Business_Unit->new(
            %$request,
            formatter_options => $request->formatter_options
        ));
}

=item delete

Deletes an existing business unit.  Only vaid for ones with no transactions or
sub-units.

$request->{id} must be set.

=cut

sub delete {
    my ($request) = @_;
    my $unit = LedgerSMB::Business_Unit->new(%$request);
    $unit->delete;
    return list($request);
}

=item delete_class

Deletes an existing business unit class.  Only valid of no units are of class.

$request->{id} must be set.

=cut

sub delete_class {
    my ($request) = @_;
    my $bu_class = LedgerSMB::Business_Unit_Class->new(%$request);
    $bu_class->delete;
    return list_classes($request);
}


=item save_new

Saves a new unit and returns to the add entry screen

=cut

sub save_new {
    my ($request) = @_;
    my $unit = _save($request);
    $request->{message} = $request->{_locale}->text('Added id [_1]', $unit->id);
    return add($request);
}

=item save

Saves the existing unit.  Standard properties of
LedgerSMB::Business_Unit must be set for $request.

=cut

sub save {
    my ($request) = @_;
    my $unit = _save($request);
    $request->{message} = $request->{_locale}->text('Saved id [_1]', $unit->id);
    return edit($request);
}

sub _save {
    my ($request) = @_;

    if ($request->{sequence}){
       $request->{control_code} =
           LedgerSMB::Setting::Sequence->increment($request->{sequence},
                                                              $request)
              if LedgerSMB::Setting::Sequence->should_increment(
                        $request, 'control_code', $request->{sequence});
    }
    $request->{start_date} = $request->parse_date( $request->{start_date} )
        if defined $request->{start_date};
    $request->{end_date} = $request->parse_date( $request->{end_date})
        if defined $request->{end_date};
    my $unit = LedgerSMB::Business_Unit->new(%$request);
    $unit = $unit->save;

    return $unit;
}



=item save_class

Saves the existing unit class.  Standard properties for
LedgerSMB::Business_Unit_Class must be set for $request.

=cut

sub save_class {
    my ($request) = @_;
    my $lsmb_modules = LedgerSMB::App_Module->new(%$request);
    my @modules = $lsmb_modules->list;
    my $modlist = [];
    for my $mod (@modules){
        if ($request->{'module_' . $mod->id}){
            push @$modlist, $mod;
        }
    }
    for my $key (qw(active non_accounting)){
        if (!$request->{$key}){
            $request->{$key} = 0;
        }
    }
    my $bu_class = LedgerSMB::Business_Unit_Class->new(%$request);
    $bu_class->modules($modlist);
    $bu_class->save;
    return list_classes($request);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
