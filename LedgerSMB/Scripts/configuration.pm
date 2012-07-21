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

our @default_textboxes = (
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
   { name => 'check_prefix', label => $locale->text('Check Prefix') },
   { name => 'password_duration', label => $locale->text('Password Duration') },
   { name => 'default_email_to', label => $locale->text('Default Email To') },
   { name => 'default_email_cc', label => $locale->text('Default Email CC') },
   { name => 'default_email_bcc', label => $locale->text('Default Email BCC') },
   { name => 'default_email_from', 
     label => $locale->text('Default Email From') },
   { name => 'company_name', label => $locale->text('Company Name') },
   { name => 'company_address', label => $locale->text('Company Address') },
   { name => 'company_phone', label => $locale->text('Company Phone') },
   { name => 'company_fax', label => $locale->text('Company Fax') },
   { name => 'company_sales_tax_id', 
                             label =>  $locale->text('Company Sales Tax ID') },
   { name => 'company_license_number',
                           label =>  $locale->text('Company License Number') },
   { name => 'check_max_invoices',
                           label =>  $locale->text('Max Invoices per Check Stub') },
   { name => 'decimal_places',
                           label =>  $locale->text('Decimal Places for Money') },
);

our @default_others = qw(businessnumber weightunit separate_duties default_language
                        inventory_accno_id income_accno_id expense_accno_id 
                        fxgain_accno_id fxloss_accno_id default_country 
                        templates curr template_images);



=head1 METHODS/ACTIONS

=over

=item defaults_screen

Shows the defaults screen

=cut

sub defaults_screen{
    my ($request) = @_;
    my $setting_handle = LedgerSMB::Setting->new({base => $request});
    my @defaults = @default_others;
    for my $tb (@default_textboxes){
        push @defaults, $tb->{name};
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
                           options => $setting_handle->accounts_by_link('FX_loss')},
        'fxgain_accno_id' => {name => 'fxgain_accno_id', 
                           options => $setting_handle->accounts_by_link('FX_gain')},
        'expense_accno_id' => {name => 'expense_accno_id', 
                            options => $setting_handle->accounts_by_link('IC_expense')},
        'income_accno_id' => {name => 'income_accno_id',
                           options => $setting_handle->accounts_by_link('IC_income')},
        'inventory_accno_id' => {name => 'inventory_accno_id', 
                     options => $setting_handle->accounts_by_link('IC')},
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
        default_textboxes => \@default_textboxes,
    });
}

=item save_defaults

Saves settings from the defaults screen

=cut

sub save_defaults {
    my ($request) = @_;
    my $setting_handle = LedgerSMB::Setting->new({base => $request});
    my @defaults = @default_others;
    for my $tb (@default_textboxes){
        push @defaults, $tb->{name};
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
