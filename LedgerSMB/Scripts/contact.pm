
=pod

=head1 NAME

LedgerSMB::Scripts::contact - LedgerSMB class defining the Controller
functions, template instantiation and rendering for customer editing and display.

=head1 SYOPSIS

This module is the UI controller for the customer, vendor, etc functions; it 

=head1 METHODS

=cut

package LedgerSMB::Scripts::contact;

use LedgerSMB::DBObject::Entity::Company;
use LedgerSMB::DBObject::Entity::Credit_Account;
use LedgerSMB::DBObject::Entity::Location;
use LedgerSMB::DBObject::Entity::Contact;
use LedgerSMB::DBObject::Entity::Bank;
use LedgerSMB::DBObject::Entity::Note;
use LedgerSMB::App_State;

my $locale = $LedgerSMB::App_State::Locale;

=head1 COPYRIGHT

Copyright (c) 2012, the LedgerSMB Core Team.  This is licensed under the GNU 
General Public License, version 2, or at your option any later version.  Please 
see the accompanying License.txt for more information.

=cut

=head1 METHODS

=over

=item get_by_cc 

Populates the company area with info on the company, pulled up through the 
control code

=cut

sub get_by_cc {
    my ($request) = @_;
    $request->{entity_class} ||= $request->{account_class};
    $request->{legal_name} ||= 'test';
    $request->{country_id} = 0;
    my $company = LedgerSMB::DBObject::Entity::Company->new(%$request);
    $company = $company->get_by_cc($request->{control_code});
    _main_screen($request, $company);
}


=item get($self, $request, $user)

Requires form var: id

Extracts a single company from the database, using its company ID as the primary
point of uniqueness. Shows (appropriate to user privileges) and allows editing
of the company information.

=cut

sub get {
    my ($request) = @_;
    $request->{entity_class} ||= $request->{account_class};
    $request->{legal_name} ||= 'test';
    my $company = LedgerSMB::DBObject::Entity::Company->new(%$request);
    $company = $company->get($request->{entity_id});
    _main_screen($request, $company);
}


# private method _main_screen 
#
# this attaches everything other than {company} to $request and displays it.

sub _main_screen {
    my ($request, $company) = @_;
    # DIVS logic
    my @DIVS;
    if ($company->{entity_id}){
       @DIVS = qw(company credit address contact_info bank_act notes);
    } else {
       @DIVS = qw(company);
    }

    %DIV_LABEL = (
             company => $locale->text('Company'),
              credit => $locale->text('Credit Accounts'),
             address => $locale->text('Addresses'),
        contact_info => $locale->text('Contact Info'),
            bank_act => $locale->text('Bank Accounts'),
               notes => $locale->text('Notes'),
    );

    # DIVS contents
    my @credit_list = 
       LedgerSMB::DBObject::Entity::Credit_Account->list_for_entity(
                          $company->{entity_id},
                          $request->{entity_class}
        );
    my $credit_act;
    for my $ref(@credit_list){
        $credit_act = $ref 
            if ($request->{credit_id} eq $ref->{id}) 
                or ($request->{meta_number} eq $ref->{meta_number});
    }

    my @locations = LedgerSMB::DBObject::Entity::Location->get_active(
                       {entity_id => $request->{entity_id},
                        credit_id => $credit_act->{id}}
          );

    my @contact_class_list =
          LedgerSMB::DBObject::Entity::Contact->list_classes;

    my @contacts = LedgerSMB::DBObject::Entity::Contact->list(
              {entity_id => $request->{entity_id},
               credit_id => $credit_act->{id}}
    );
    my @bank_account = 
         LedgerSMB::DBObject::Entity::Bank->list($request->{entity_id});
    my @notes =
         LedgerSMB::DBObject::Entity::Note->list($request->{entity_id},
                                                 $credit_act->{id});
    $attach_level_options = [
        {label => $locale->text('Entity'), value => 1} ];
    push@{$attach_level_options},
        {label => $locale->text('Credit Account'),
         value => 3} if $credit_act->{id};
    ;

    # Template info and rendering 
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        template => 'contact',
        locale => $request->{_locale},
        path => 'UI/Contact',
        format => 'HTML'
    );

    #use Data::Dumper;
    #$Data::Dumper::Sortkeys = 1;
    @country_list = $request->call_procedure(
                     procname => 'location_list_country'
      );
    @entity_classes = $request->call_procedure(
                      procname => 'entity__list_classes'
    );

    $template->render({
                     DIVS => \@DIVS,
                DIV_LABEL => \%DIV_LABEL,
                  request => $request,
                  company => $company,
             country_list => \@country_list,
               credit_act => $credit_act,
              credit_list => \@credit_list,
           entity_classes => \@entity_classes,
                locations => \@locations,
                 contacts => \@contacts,
             bank_account => \@bank_account,
                    notes => \@notes,
     attach_level_options => $attach_level_options
    });
}

=item generate_control_code 

Generates a control code and hands off execution to other routines

=cut

sub generate_control_code {
    my ($request) = @_;
    my ($ref) = $request->call_procedure(
                             procname => 'setting_increment', 
                             args     => ['entity_control']
                           );
    ($request->{control_code}) = values %$ref;
    $request->{dbh}->commit;
    _main_screen($request, $request);
}

=item dispatch_legacy

This is a semi-private method which interfaces with the old code.  Note that
as long as any other functions use this, the contact interface cannot be said to 
be safe for code caching.

Not fully documented because this will go away as soon as possible.

=cut

sub dispatch_legacy {
    our ($request) = shift @_;
    use LedgerSMB::Form;
    my $aa;
    my $inv;
    my $otype;
    my $qtype;
    my $cv;
    if ($request->{account_class} == 1){
       $aa = 'ap';
       $inv = 'ir';
       $otypr = 'purchase_order';
       $qtype = 'request_quotation';
       $cv = 'vendor';
    } elsif ($request->{account_class} == 2){
       $aa = 'ar';
       $inv = 'is';
       $otypr = 'sales_order';
       $qtype = 'sales_quotation';
       $cv = 'customer';
    } else {
       $request->error($request->{_locale}->text('Unsupport account type'));
    }
    our $dispatch = 
    {
        add_transaction  => {script => "bin/$aa.pl", 
                               data => {"${cv}_id" => $request->{credit_id}},
                            },
        add_invoice      => {script => "bin/$inv.pl",
                               data => {"${cv}_id" => $request->{credit_id}},
                            },
        add_order        => {script => 'bin/oe.pl', 
                               data => {"${cv}_id" => $request->{credit_id},
                                            type   => $otype,
                                               vc  => $cv,
                                       },
                            },
        rfq              => {script => 'bin/oe.pl', 
                               data => {"${cv}_id" => $request->{credit_id},
                                            type   => $qtype,
                                               vc  => $cv,
                                       },
                            },
 
    };

    our $form = new Form;
    our %myconfig = ();
    %myconfig = %{$request->{_user}};
    $form->{stylesheet} = $myconfig{stylesheet};
    our $locale = $request->{_locale};

    for (keys %{$dispatch->{$request->{action}}->{data}}){
        $form->{$_} = $dispatch->{$request->{action}}->{data}->{$_};
    }

    my $script = $dispatch->{$request->{action}}{script};
    $form->{script} = $script;
    $form->{action} = 'add';
    $form->{dbh} = $request->{dbh};
    $form->{script} =~ s|.*/||;
    { no strict; no warnings 'redefine'; do $script; }

    $form->{action}();
}

=item add_transaction

Dispatches to the Add (AR or AP as appropriate) transaction screen.

=cut

sub add_transaction {
    my $request = shift @_;
    dispatch_legacy($request);
}

=item add_invoice

Dispatches to the (sales or vendor, as appropriate) invoice screen.

=cut

sub add_invoice {
    my $request = shift @_;
    dispatch_legacy($request);
}

=item add_order

Dispatches to the sales/purchase order screen.

=cut

sub add_order {
    my $request = shift @_;
    dispatch_legacy($request);
}

=item rfq

Dispatches to the quotation/rfq screen

=cut

sub rfq {
    my $request = shift @_;
    dispatch_legacy($request);
}

=item add

This method creates a blank screen for entering a company's information.

=back

=cut 

sub add {
    my ($request) = @_;
    _main_screen($request, $request);
}

=item save_company

Saves a company and moves on to the next screen

=cut

sub save_company {
    my ($request) = @_;
    my $company = LedgerSMB::DBObject::Entity::Company->new(%$request);
    use Data::Dumper;
    $Data::Dumper::Sortkeys => 1;
    $company = $company->save;
    _main_screen($request, $company);
}

1;
