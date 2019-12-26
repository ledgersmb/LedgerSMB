=head1 NAME 

printer.pl - centralized printing logic used for printing in legacy sl code

=cut


package lsmb_legacy;
use LedgerSMB::Sysconfig;
use LedgerSMB::Setting;
use LedgerSMB::Company_Config;

sub print_options {

    my $hiddens = shift;
    my %options;
    $form->{format} = $form->get_setting('format') unless $form->{format};
    $form->{sendmode} = "attachment";
    $form->{copies} = 1 unless $form->{copies};

    $form->{SM}{ $form->{sendmode} } = "selected";

    delete $form->{all_language};
    $form->all_languages;
    if ( ref $form->{all_language} eq 'ARRAY') {
        $options{lang} = {
            name => 'language_code',
            id => 'language-code',
            default_values => $form->{oldlanguage_code},
            options => [{text => ' ', value => ''}],
            };
        for my $lang (@{$form->{all_language}}) {
            push @{$options{lang}{options}}, {
                text => $lang->{description},
                value => $lang->{code},
                };
        }
        $hiddens->{oldlanguage_code} = $form->{oldlanguage_code};
    }

    $options{formname} = {
        name => 'formname',
        default_values => $form->{formname},
        options => [],
        };

    # SC: Option values extracted from other old/bin/ scripts
    if ($form->{type} && $form->{type} eq 'invoice') {
    push @{$options{formname}{options}}, {
        text => $locale->text('Invoice'),
        value => 'invoice',
        };
    }
    if ($form->{type} && $form->{type} eq 'sales_quotation') {
        push @{$options{formname}{options}}, {
            text => $locale->text('Quotation'),
            value => 'sales_quotation',
            };
    } elsif ($form->{type} && $form->{type} eq 'request_quotation') {
        push @{$options{formname}{options}}, {
            text => $locale->text('RFQ'),
            value => 'request_quotation',
            };
    } elsif ($form->{type} && $form->{type} eq 'sales_order') {
        push @{$options{formname}{options}}, {
            text => $locale->text('Sales Order'),
            value => 'sales_order',
            };
        push @{$options{formname}{options}}, {
            text => $locale->text('Work Order'),
            value => 'work_order',
            };
        push @{$options{formname}{options}}, {
            text => $locale->text('Pick List'),
            value => 'pick_list',
            };
        push @{$options{formname}{options}}, {
            text => $locale->text('Packing List'),
            value => 'packing_list',
            };
    } elsif ($form->{type} && $form->{type} eq 'purchase_order') {
        push @{$options{formname}{options}}, {
            text => $locale->text('Purchase Order'),
            value => 'purchase_order',
            };
        push @{$options{formname}{options}}, {
            text => $locale->text('Bin List'),
            value => 'bin_list',
            };
    } elsif ($form->{type} && $form->{type} eq 'ship_order') {
        push @{$options{formname}{options}}, {
            text => $locale->text('Pick List'),
            value => 'pick_list',
            };
        push @{$options{formname}{options}}, {
            text => $locale->text('Packing List'),
            value => 'packing_list',
            };
    } elsif ($form->{type} && $form->{type} eq 'receive_order') {
        push @{$options{formname}{options}}, {
            text => $locale->text('Bin List'),
            value => 'bin_list',
            };
    }
    push @{$options{formname}{options}}, {
            text => $locale->text('Envelope'),
            value => 'envelope',
            };
    push @{$options{formname}{options}}, {
            text => $locale->text('Shipping Label'),
            value => 'shipping_label',
            };

    if ( $form->{media} && $form->{media} eq 'email' ) {
        $options{media} = {
            name => 'sendmode',
            options => [{
                text => $locale->text('Attachment'),
                value => 'attachment'}, {
                text => $locale->text('In-line'),
                value => 'inline'}
                ]};
        $options{media}{default_values} = 'attachment' if $form->{SM}{attachment};
        $options{media}{default_values} = 'inline' if $form->{SM}{inline};
    } else {
        $options{media} = {
            name => 'media',
            default_values => $form->{media},
            options => [{
                text => $locale->text('Screen'),
                value => 'screen'}
                ]};
        if (   %{LedgerSMB::Sysconfig::printer}
            && ${LedgerSMB::Sysconfig::latex} )
        {
            for ( sort keys %{LedgerSMB::Sysconfig::printer} ) {
                push @{$options{media}{options}}, {text => $_, value => $_};
            }
        }
    }

    $options{format} = {
        name => 'format',
        default_values => $form->{selectformat},
        options => [{text => 'HTML', value => 'html'},
                    {text => 'CSV', value => 'csv'} ],
        };
    if ( ${LedgerSMB::Sysconfig::latex} ) {
        push @{$options{format}{options}}, {
            text => $locale->text('Postscript'),
            value => 'postscript',
            };
        push @{$options{format}{options}}, {
            text => 'PDF',
            value => 'pdf',
            };
    }
    if ($form->{type} && $form->{type} eq 'invoice'){
       push @{$options{format}{options}}, {
            text => '894.EDI',
            value => '894.edi',
            };
    }

    if (   %{LedgerSMB::Sysconfig::printer}
        && ${LedgerSMB::Sysconfig::latex}
        && $form->{media} ne 'email' )
    {
        $options{copies} = 1;
    }

    # $locale->text('Printed')
    # $locale->text('E-mailed')
    # $locale->text('Scheduled')

    $options{status} = {
        printed   => 'Printed',
        emailed   => 'E-mailed',
        recurring => 'Scheduled'
    };

    $options{groupby} = {};
    $options{groupby}{groupprojectnumber} = "checked" if $form->{groupprojectnumber};
    $options{groupby}{grouppartsgroup} = "checked" if $form->{grouppartsgroup};

    $options{sortby} = {};
    for (qw(runningnumber partnumber description bin)) {
        $options{sortby}{$_} = "checked" if $form->{sortby} && $_ && $form->{sortby} eq $_;
    }

    \%options;
}

sub print_select { # Needed to print new printoptions output from non-template
                   # screens --CT
    my ($form, $select) = @_;
    my $name = $select->{name};
    my $id = $name;
    $id =~ s/\_/-/;
    print qq|<select data-dojo-type="dijit/form/Select" id="$id" name="$name" class="$select->{class}">\n|;
    for my $opt (@{$select->{options}}){
        print qq|<option value="$opt->{value}" |;
        if ($form->{$select->{name}} eq $opt->{value}){
            print qq|SELECTED="SELECTED"|;
        }
        print qq|>$opt->{text}</option>\n|;
    }
    print "</select>";
}
1;
