=head1 NAME 

LedgerSMB::Scripts::business_unit

=cut

package LedgerSMB::Scripts::business_unit;
use LedgerSMB::DBObject::Business_Unit_Class;
use LedgerSMB::DBObject::App_Module;
use LedgerSMB::DBObject::Business_Unit;
use LedgerSMB::Template;
use Carp;

$Carp::Verbose = 1;

=head1 SYNOPSIS

Workflow routines for LedgerSMB business reporting units

=head1 FUNCTIONS

All functions take a single $request object as their sole argument

=over

=item list_classes

=cut

sub list_classes {
    my ($request) = @_;
    my $bu_class = LedgerSMB::DBObject::Business_Unit_Class->new(%$request);
    my $lsmb_modules = LedgerSMB::DBObject::App_Module->new(%$request);
    @{$request->{classes}} = $bu_class->list;
    @{$request->{modules}} = $lsmb_modules->list;
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user},
        locale => $request->{_locale},
        path => 'UI/business_units',
        template => 'list_classes',
        format => 'HTML'
    );
    $template->render($request);
}

=item add

Adds a new business unit.  $request->{class_id} must be set.

=cut

sub add {
    my ($request) = @_;
    if (!$request->{class_id}){
        $request->{class_id} = $request->{id};
    }
    $request->{control_code} = '';
    my $b_unit = LedgerSMB::DBObject::Business_Unit->new(%$request);
    @{$request->{parent_options}} = $b_unit->list($request->{class_id});
    $request->{id} = undef;
    _display($request); 
}

=item edit

Edits an existing business unit.  $request->{id} must be set.

=cut

sub edit {
    my ($request) = @_;
    $request->{control_code} = '';
    $request->{class_id} = 0 unless $request->{class_id} = 0;
    my $b_unit = LedgerSMB::DBObject::Business_Unit->new(%$request);
    my $bu = $b_unit->get($request->{id});
    _display($bu);
}

sub _display {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user},
        locale => $request->{_locale},
        path => 'UI/business_units',
        template => 'edit',
        format => 'HTML'
    );
    $template->render($request);

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
    $request->{control_code} = '';
    $request->{class_id} = 0 unless $request->{class_id} = 0;
    my $b_unit = LedgerSMB::DBObject::Business_Unit->new(%$request);
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user},
        locale => $request->{_locale},
        path => 'UI',
        template => 'form-dynatable',
        format => 'HTML'
    );
    my $cols;
    @$cols = qw(id control_code description start_date end_date);
    my $heading = {
                  id => $request->{_locale}->text('ID'),
        control_code => $request->{_locale}->text('Control Code'),
         description => $request->{_locale}->text('Description'),
          start_date => $request->{_locale}->text('Start Date'),
            end_date => $request->{_locale}->text('End Date'),
    };
    my $rows;
    @$rows = $b_unit->list($request->{id}); 
    my $base_href= "business_unit.pl?action=edit";
    for $row(@$rows){
        $row->{control_code} = {text => $row->{control_code},
                                href => "$base_href&id=$row->{id}"};
    }
    $template->render({
         form    => $request,
         heading => $heading,
         rows    => $rows,
         columns => $cols,
    });
}

=item delete

Deletes an existing business unit.  Only vaid for ones with no transactions or 
sub-units.

$request->{id} must be set.

=cut

sub delete {
    my ($request) = @_;
    my $unit = LedgerSMB::DBObject::Business_Unit->new(%$request);
    $unit->delete;
    list($request);
}

=item delete_class

Deletes an existing business unit class.  Only valid of no units are of class.

$request->{id} must be set.

=cut

sub delete_class {
    my ($request) = @_;
    my $bu_class = LedgerSMB::DBObject::Business_Unit_Class->new($request);
    $bu_class->delete;
    list_classes($request);
}

=item save

Saves the existing unit.  Standard properties of 
LedgerSMB::DBObject::Business_Unit must be set for $request.

=cut

sub save {
    my ($request) = @_;
    $request->{start_date} = LedgerSMB::PGDate->from_input($request->{start_date}, 0)
                              if defined $request->{start_date};
    $request->{end_date} = LedgerSMB::PGDate->from_input($request->{end_date}, 0)
                              if defined $request->{end_date};
    my $unit = LedgerSMB::DBObject::Business_Unit->new(%$request);
    $unit->save;
    add($request);
}

=item save_class

Saves the existing unit class.  Standard properties for 
LedgerSMB::DBObject::Business_Unit_Class must be set for $request.

=cut

sub save_class {
    my ($request) = @_;
    my $lsmb_modules = LedgerSMB::DBObject::App_Module->new(%$request);
    my @modules = $lsmb_modules->list;
    my $modlist = [];
    for my $mod (@modules){
        if ($request->{"module_" . $mod->id}){
            push @$modlist, $mod;
        }
    }
    for my $key (qw(active non_accounting)){
        if (!$request->{$key}){
            $request->{$key} = 0;
        }
    }
    my $bu_class = LedgerSMB::DBObject::Business_Unit_Class->new(%$request);
    $bu_class->modules($modlist);
    $bu_class->save;
    list_classes($request);
}

=back

=head COPYRIGHT

Copyright (C) 2012 LedgerSMB core team.  Redistribution and use of work is 
governed under the GNU General Public License, version 2 or at your option any
later version.

=cut

1;
