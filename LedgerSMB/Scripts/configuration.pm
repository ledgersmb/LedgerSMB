=head1 NAME

LedgerSMB::Scripts::configuration - Configuration Workflows for LedgerSMB

=head1 SYNPOPSIS

LedgerSMB::Scripts::configuration->can('action')->($request);

=cut
package LedgerSMB::Scripts::configuration;
use LedgerSMB::Setting;
use LedgerSMB::AM; # To be removed, only for template directories right now
use strict;
use warnings;

my $locale = $LedgerSMB::App_State::Locale;

our @default_settings = (
   { title => $locale->text('Company Information'),
     items => [
       { name => 'company_name', label => $locale->text('Company Name') },
       { name => 'company_address', label => $locale->text('Company Address') },
       { name => 'company_phone', label => $locale->text('Company Phone') },
       { name => 'company_fax', label => $locale->text('Company Fax') },
       { name => 'businessnumber', label => $locale->text('Business Number') },
       { name => 'default_email_to', 
        label => $locale->text('Default Email To') },
       { name => 'default_email_cc', 
        label => $locale->text('Default Email CC') },
       { name => 'default_email_bcc', 
        label => $locale->text('Default Email BCC') },
       { name => 'default_email_from', 
        label => $locale->text('Default Email From') },
       { name => 'company_sales_tax_id', 
        label =>  $locale->text('Company Sales Tax ID') },
       { name => 'company_license_number',
        label =>  $locale->text('Company License Number') },
       { name => 'curr', 
        label => $locale->text('Currencies (colon-separated)')},
       { name => 'weightunit', label => $locale->text('Weight Unit') },
       { name => 'default_country',
        label => $locale->text('Default Country'),
         type => 'SELECT_ONE', },
       { name => 'default_language',
        label => $locale->text('Default Language'),
         type => 'SELECT_ONE', },
       { name => 'templates',
         type => 'SELECT_ONE',
        label => $locale->text('Template Set'), },
     ] },
   { title => $locale->text('Security Settings'),
     items => [
       { name => 'password_duration',
        label => $locale->text('Password Duration') },
       { name => 'session_timeout',
        label => $locale->text('Session Timeout'), },
       { name => 'auto_logout',
        label => $locale->text('Automatically Logout'),
         type => 'YES_NO', },
       { name => 'separate_duties',
        label => $locale->text('Separate Duties'),
         type => 'YES_NO', },
     ] },
 { title => $locale->text('Default Accounts'),
   items => [
       { name => 'inventory_accno_id',
         type => 'SELECT_ONE',
        label => $locale->text('Inventory'), },
       { name => 'income_accno_id',
         type => 'SELECT_ONE',
        label => $locale->text('Income'), },
       { name => 'expense_accno_id',
         type => 'SELECT_ONE',
        label => $locale->text('Cost of Goods Sold'), },
       { name => 'fxgain_accno_id',
         type => 'SELECT_ONE',
        label => $locale->text('Foreign Exchange Gain') },
       { name => 'fxloss_accno_id',
         type => 'SELECT_ONE',
        label => $locale->text('Foreign Exchange Loss') },
   ] },
 { title => $locale->text('Next in Sequence'),
   items => [
     { name => 'glnumber', label => $locale->text('GL Reference Number') },
     { name => 'sinumber', 
      label => $locale->text('Sales Invoice/AR Transaction Number'), },
     { name => 'vclimit', label => $locale->text('Max per dropdown') },
     { name => 'sonumber', label => $locale->text('Sales Order Number') },
     { name => 'vinumber' , 
      label => $locale->text('Vendor Invoice/AP Transaction Number')},
     { name => 'sqnumber', label => $locale->text('Sales Quotation Number') },
     { name => 'rfqnumber', label => $locale->text('RFQ Number') },
     { name => 'partnumber', label => $locale->text('Part Number') },
     { name => 'projectnumber', label => $locale->text('Job/Project Number') },
     { name => 'employeenumber', label => $locale->text('Employee Number') },
     { name => 'customernumber', label => $locale->text('Customer Number') },
     { name => 'vendornumber', label => $locale->text('Vendor Number') },
   ] },
   { title => $locale->text('Misc Settings'),
     items => [  
       { name => 'check_prefix', label => $locale->text('Check Prefix') },
       { name => 'check_max_invoices',
        label =>  $locale->text('Max Invoices per Check Stub') },
       { name => 'decimal_places',
        label =>  $locale->text('Decimal Places for Money') },
       { name => 'template_immages',
        label => $locale->text('Images in Templates'),
         type => 'YES_NO', },
     ] },
);

=head1 METHODS/ACTIONS

=over

=item defaults_screen

Shows the defaults screen

=cut

sub defaults_screen{
    my ($request) = @_;
    my $setting_handle = LedgerSMB::Setting->new({base => $request});
    my @defaults;
    for my $dg (@default_settings){
        for my $tb (@{$dg->{items}}){
            push @defaults, $tb->{name};
        }
    }
    for my $skey (@defaults){
        $request->{$skey} = $setting_handle->get($skey);
    }
    my @country_list = $request->call_procedure(
                     procname => 'location_list_country'
    );
    my @language_code_list =
             $request->call_procedure(procname=> 'person__list_languages');

    my %selects = (
        'fxloss_accno_id' => {name => 'fxloss_accno_id', 
                           options => $setting_handle->accounts_by_link('FX_loss'),
                         text_attr => 'text',
                        value_attr => 'id'},
        'fxgain_accno_id' => {name => 'fxgain_accno_id', 
                         text_attr => 'text',
                           options => $setting_handle->accounts_by_link('FX_gain'),
                        value_attr => 'id'},
        'expense_accno_id' => {name => 'expense_accno_id', 
                            options =>  $setting_handle->accounts_by_link('IC_expense'),
                         text_attr => 'text',
                        value_attr => 'id'},
        'income_accno_id' => {name => 'income_accno_id',
                           options => $setting_handle->accounts_by_link('IC_income'),
                         text_attr => 'text',
                        value_attr => 'id'},
        'inventory_accno_id' => {name => 'inventory_accno_id', 
                     options => $setting_handle->accounts_by_link('IC'),
                   text_attr => 'text',
                  value_attr => 'id'},
	'default_country' => {name   => 'default_country', 
			     options => \@country_list,
			     default_values => [$request->{'default_country'}],
			     text_attr => 'name',
			     value_attr => 'id',
		},
	'default_language' => {name   => 'default_language', 
			     options => \@language_code_list,
			     default_values => [$request->{'default_language'}],
			     text_attr => 'description',
			     value_attr => 'code',
		},
	'templates'       => {name => 'templates',
                           options => _get_template_directories(), 
                         text_attr => 'text',
                        value_attr => 'value' 
               },	
        );
    my $template = LedgerSMB::Template->new_UI(
        user => $LedgerSMB::App_State::User, 
        locale => $locale,
        template => 'am-defaults');
    $template->render({
        form => $request,
	# hiddens => \%hiddens,
	selects => \%selects,
        default_settings => \@default_settings,
    });
}

=item save_defaults

Saves settings from the defaults screen

=cut

sub save_defaults {
    my ($request) = @_;
    my $setting_handle = LedgerSMB::Setting->new({base => $request});
    my @defaults;
    for my $dg (@default_settings){
        for my $tb (@{$dg->{items}}){
            push @defaults, $tb->{name};
        }
    }
    for my $skey (@defaults){
        $request->{$skey} =~ s/--.*$// if $skey =~ /accno_id/;
        $setting_handle->set($skey, $request->{$skey});
    }
    defaults_screen($request);
}

=item _get_template_directories

Returns set of template directories available.

=cut

sub _get_template_directories {
    my $subdircount = 0;
    my @dirarray;
    opendir ( DIR, $LedgerSMB::Sysconfig::templates) || die $locale->text("Error while opening directory: [_1]",  "./".$LedgerSMB::Sysconfig::templates);
    while( my $name = readdir(DIR)){
        next if ($name =~ /\./);
        if (-d $LedgerSMB::Sysconfig::templates.'/'.$name) {
            push @dirarray, {text => $name, value => $name};
        }
    }
    closedir(DIR);
    return \@dirarray;
}

=back

=head1 COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team.  This file may be reused under the
conditions of the GNU GPL v2 or at your option any later version.  Please see
the accompanying LICENSE.TXT for more information.

=cut

1;
