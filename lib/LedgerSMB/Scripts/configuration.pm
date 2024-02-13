
package LedgerSMB::Scripts::configuration;

=head1 NAME

LedgerSMB::Scripts::configuration - Configuration Workflows for LedgerSMB

=head1 DESCRIPTION

Implements the presenting and saving done from the screens
System > Defaults and System > Sequences.

=head1 SYNPOPSIS

LedgerSMB::Scripts::configuration->can('__action')->($request);

=head1 METHODS

This module does not specify any methods.

=cut

use strict;
use warnings;

use LedgerSMB::I18N;
use LedgerSMB::Setting::Sequence;

sub _default_settings {
    my ($request) = @_;
    my $locale = $request->{_locale};

    my @default_settings = (
        { title => $locale->text('Company Information'),
          items => [
              { name => 'company_name', label => $locale->text('Company Name') },
              { name => 'company_address',
                type => 'TEXTAREA',
                label => $locale->text('Company Address') },
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
                label => $locale->text('Base Currency'),
                type => 'SELECT_ONE', },
              { name => 'weightunit', label => $locale->text('Weight Unit') },
              { name => 'format',
                type => 'SELECT_ONE',
                label => $locale->text('Default Format'), },
              { name => 'papersize',
                type => 'SELECT_ONE',
                label => $locale->text('Default Paper Size'), },
              ] },
        { title => $locale->text('Security Settings'),
          items => [
              { name => 'disable_back',
                label => $locale->text('Disable Back Button'),
                type => 'YES_NO', },
              { name => 'password_duration',
                label => $locale->text('Password Duration (days)')
              },
              { name => 'session_timeout',
                label => $locale->text('Session Timeout (e.g. "90 minutes")'), },
              { name => 'separate_duties',
                label => $locale->text('Separate Duties'),
                type => 'YES_NO', },
              { name => 'lock_description',
                label => $locale->text('Lock Item Description'),
                type => 'YES_NO', },
              { name => 'gapless_ar',
                label => $locale->text('Gapless AR'),
                type => 'YES_NO', },
              ] },
        { title => $locale->text('Default Accounts'),
          items => [
              { name => 'earn_id',
                type => 'SELECT_ONE',
                label => $locale->text('Current earnings'), },
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
              { name => 'batch_cc', label => $locale->text('Batch Number') },
              { name => 'glnumber', label => $locale->text('GL Reference Number') },
              { name => 'sinumber',
                label => $locale->text('Sales Invoice/AR Transaction Number'), },
              { name => 'sonumber', label => $locale->text('Sales Order Number') },
              { name => 'sqnumber', label => $locale->text('Sales Quotation Number') },
              { name => 'vinumber' ,
                label => $locale->text('Vendor Invoice/AP Transaction Number')},
              { name => 'ponumber', label => $locale->text('Purchase Order Number') },
              { name => 'rfqnumber', label => $locale->text('RFQ Number') },
              { name => 'partnumber', label => $locale->text('Part Number') },
              { name => 'projectnumber', label => $locale->text('Business Unit Number') },
              { name => 'employeenumber', label => $locale->text('Employee Number') },
              { name => 'entity_control', label => $locale->text('Entity number') },
              { name => 'customernumber', label => $locale->text('Customer Number') },
              { name => 'vendornumber', label => $locale->text('Vendor Number') },
              ] },
        { title => $locale->text('Misc Settings'),
          items => [
              { name => 'show_creditlimit', type => 'YES_NO',
                label => $locale->text('Show Credit Limit') },
              { name => 'have_barcodes', type => 'YES_NO_AUTO',
                label => $locale->text('Barcode entry on invoices') },
              { name => 'dojo_theme',
                type => 'SELECT_ONE',
                label => $locale->text('Widgit Themes') },
              { name => 'check_prefix', label => $locale->text('Check Prefix') },
              { name => 'vclimit', label => $locale->text('Max per dropdown') },
              { name => 'check_max_invoices',
                label =>  $locale->text('Max Invoices per Check Stub') },
              { name => 'decimal_places',
                label =>  $locale->text('Decimal Places for Money') },
              { name => 'template_images',
                label => $locale->text('Images in Templates'),
                type => 'YES_NO', },
              { name => 'min_empty',
                label => $locale->text('Min Empty Lines') },
              { name => 'default_buyexchange',
                label => $locale->text('Use web service for current exchange rates'),
                type => 'YES_NO',
                info => ['Rates can be provided automatically to the application by using a web service and providing current date and origin and destination currencies.',
                         'Please review the terms and conditions for the $1 before use.']
                },
              ] },
        { title => $locale->text('Experimental features'),
          items => [
              { name => 'enable_wage_screen', type => 'YES_NO',
                label => $locale->text('Employee wage screen') },
              ] },
        );
    return @default_settings;
}

=head1 METHODS/ACTIONS

=over

=item defaults_screen

Shows the defaults screen

=cut

sub defaults_screen {
    my ($request) = @_;

    my @curr = map { { curr => $_ } } $request->setting->get_currencies();
    my @defaults;
    my @default_settings = &_default_settings($request);
    for my $dg (@default_settings) {
        for my $tb (@{$dg->{items}}){
            push @defaults, $tb->{name};
        }
    }
    for my $skey (@defaults){
        $request->{$skey} = $request->setting->get($skey);
    }

    my @country_list = $request->enabled_countries->@*;
    unshift @country_list, {}
        if ! defined $request->{default_country};

    my @language_code_list =
             $request->call_procedure(funcname => 'person__list_languages');
    unshift @language_code_list, {}
        if ! defined $request->{default_language};

    my $expense_accounts = $request->setting->accounts_by_link('IC_cogs');
    my $income_accounts = $request->setting->accounts_by_link('IC_income');
    my $fx_loss_accounts = $request->setting->all_accounts();
    my $fx_gain_accounts = $request->setting->all_accounts();
    my $inventory_accounts = $request->setting->accounts_by_link('IC');
    my $headings =
        [$request->call_procedure(funcname => 'account__all_headings')];
    for my $ref (@$headings){
        $ref->{text} = "$ref->{accno} -- $ref->{description}";
    }

    unshift @$expense_accounts, {}
        if ! defined $request->{expense_accno_id};
    unshift @$income_accounts, {}
        if ! defined $request->{income_accno_id};
    unshift @$fx_loss_accounts, {}
        if ! defined $request->{fxloss_accno_id};
    unshift @$fx_gain_accounts, {}
        if ! defined $request->{fxgain_accno_id};
    unshift @$inventory_accounts, {}
        if ! defined $request->{inventory_accno_id};
    unshift @$headings, {}
        if ! defined $request->{earn_id};

    my %selects = (
        'dojo_theme' => {
            name => 'dojo_theme', # TODO autodetect
            options => [
                {text => 'Claro', value => 'claro'},
                {text => 'Nihilo', value => 'nihilo'},
                {text => 'Soria', value => 'soria'},
                {text => 'Tundra', value => 'tundra'},
            ],
            default_values  => [$request->{dojo_theme}],
        },
        'earn_id'         => {
            name           => 'earn_id',
            options        => $headings,
            text_attr      => 'text',
            value_attr     => 'id',
            default_values => [$request->{'earn_id'}],
        },
        'curr' => {
            name => 'curr',
            options => \@curr,
            default_values => [$request->{curr}],
            text_attr => 'curr',
            value_attr => 'curr',
        },
        'fxloss_accno_id' => {
            name           => 'fxloss_accno_id',
            options        => $fx_loss_accounts,
            text_attr      => 'text',
            value_attr     => 'id',
            default_values => [$request->{'fxloss_accno_id'}],
        },
        'fxgain_accno_id' => {
            name           => 'fxgain_accno_id',
            text_attr      => 'text',
            options        => $fx_gain_accounts,
            value_attr     => 'id',
            default_values => [$request->{'fxgain_accno_id'}],
        },
        'expense_accno_id' => {
            name           => 'expense_accno_id',
            options        =>  $expense_accounts,
            text_attr      => 'text',
            value_attr     => 'id',
            default_values => [$request->{'expense_accno_id'}],
        },
        'income_accno_id' => {
            name           => 'income_accno_id',
            options        => $income_accounts,
            text_attr      => 'text',
            value_attr     => 'id',
            default_values => [$request->{'income_accno_id'}],
        },
        'inventory_accno_id' => {
            name           => 'inventory_accno_id',
            options        => $inventory_accounts,
            text_attr      => 'text',
            value_attr     => 'id',
            default_values => [$request->{'inventory_accno_id'}],
        },
        'default_country' => {
            name           => 'default_country',
            options        => \@country_list,
            default_values => [$request->{'default_country'}],
            text_attr      => 'name',
            value_attr     => 'id',
        },
        'default_language' => {
            name           => 'default_language',
            options        => \@language_code_list,
            default_values => [$request->{'default_language'}],
            text_attr      => 'description',
            value_attr     => 'code',
        },
        'format' => {
            name           => 'format',
            text_attr      => 'text',
            value_attr     => 'value',
            default_values => [$request->{'format'}],
            options        => [
                {text => 'HTML', value => 'html'},
                {text => 'PDF', value => 'pdf'},
                {text => 'Postscript', value => 'postscript'},
            ]
        },
        'papersize' => {
            name           => 'papersize',
            text_attr      => 'text',
            value_attr     => 'value',
            default_values => [$request->{'papersize'}],
            options        => [
                {text => 'Letter', value => 'letter'},
                {text => 'A4', value => 'a4'},
            ]
        },
    );

    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'Configuration/settings', {
        form => $request,
        # hiddens => \%hiddens,
        selects => \%selects,
        default_settings => \@default_settings,
    });
}

=item sequence_screen

No inputs expected or used

=cut

sub sequence_screen {
    my ($request) = @_;
    @{$request->{sequence_list}} = LedgerSMB::Setting::Sequence->list();
    my @default_settings = &_default_settings($request);
    my $locale = $request->{_locale};
    for my $subset (@default_settings){
        $request->{setting_keys} = $subset->{items}
             if $subset->{title} eq $locale->text('Next in Sequence');
    }
    my $count = 0;
    for my $item (@{$request->{setting_keys}}){
        for my $blacklist (qw(customernumber vendornumber employeenumber)){
            delete $request->{setting_keys}->[$count] if $item->{name} eq $blacklist;
        }
        ++$count;
    }
    return $request->{_wire}->get('ui')
        ->render($request, 'Configuration/sequence', $request);
}

=item save_defaults

Saves settings from the defaults screen

=cut

sub save_defaults {
    my ($request) = @_;
    if (!$request->is_allowed_role(
        {allowed_roles => ['system_settings_change'] })
    ){
       die $request->{_locale}->text('Access Denied');
    }
    my @defaults;
    my @default_settings = &_default_settings($request);
    for my $dg (@default_settings){
        for my $tb (@{$dg->{items}}){
            push @defaults, $tb->{name};
        }
    }
    for my $skey (@defaults){
        $request->{$skey} =~ s/--.*$// if $skey =~ /accno_id/;
        $request->setting->set($skey, $request->{$skey});
    }
    return defaults_screen($request);
}

=item save_sequences

Saves the items in the sequence screen

=cut

sub save_sequences {
    my ($request) = @_;
    for my $count (1 .. $request->{count}){
        if ($request->{"save_$count"} and $request->{"label_$count"}){
           LedgerSMB::Setting::Sequence->new(
               map { $_ => $request->{"${_}_$count"} }
               qw(accept_input setting_key label prefix sequence suffix)
           )->save;
        }
    }
    return sequence_screen($request);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
