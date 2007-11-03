#=====================================================================
# LedgerSMB Small Medium Business Accounting
# http://www.ledgersmb.org/
#

# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.
#
# This file contains source code included with or based on SQL-Ledger which
# is Copyright Dieter Simader and DWS Systems Inc. 2000-2005 and licensed
# under the GNU General Public License version 2 or, at your option, any later
# version.  For a full list including contact information of contributors,
# maintainers, and copyright holders, see the CONTRIBUTORS file.
#
# Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
# Copyright (c) 2001
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors: Reed White <alta@alta-research.com>
#
#
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#======================================================================
#
# customer/vendor module
#
#======================================================================

use LedgerSMB::CT;
use LedgerSMB::Template;

1;

# end of main

sub add {

    $form->{title} = "Add";

    # $locale->text('Add Customer')
    # $locale->text('Add Vendor')

    $form->{callback} =
"$form->{script}?action=add&db=$form->{db}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    CT->create_links( \%myconfig, \%$form );

    &form_header;
    &form_footer;

}

sub history {

    # $locale->text('Customer History')
    # $locale->text('Vendor History')

    my %hiddens;
    my @buttons;
    $history = 1;
    $label   = ucfirst $form->{db};
    $label .= " History";

    if ( $form->{db} eq 'customer' ) {
        $form->{invlabel} = $locale->text('Sales Invoices');
        $form->{ordlabel} = $locale->text('Sales Orders');
        $form->{quolabel} = $locale->text('Quotations');
    } else {
        $form->{invlabel} = $locale->text('Vendor Invoices');
        $form->{ordlabel} = $locale->text('Purchase Orders');
        $form->{quolabel} = $locale->text('Request for Quotations');
    }

    $form->{title} = $locale->text($label);

    $form->{nextsub} = "list_history";

    &search_name(\%hiddens, \@buttons);

##SC: Temporary removal
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'ct-search',
        );
    $template->render({
        form => $form,
        user => \%myconfig, 
        hiddens => \%hiddens,
        buttons => \@buttons,
    });
}

sub transactions {
    if ( $form->{db} eq 'customer' ) {
        $form->{translabel} = $locale->text('AR Transactions');
        $form->{invlabel}   = $locale->text('Sales Invoices');
        $form->{ordlabel}   = $locale->text('Sales Orders');
        $form->{quolabel}   = $locale->text('Quotations');
    } else {
        $form->{translabel} = $locale->text('AP Transactions');
        $form->{invlabel}   = $locale->text('Vendor Invoices');
        $form->{ordlabel}   = $locale->text('Purchase Orders');
        $form->{quolabel}   = $locale->text('Request for Quotations');
    }
}

sub include_in_report {

    $label = ucfirst $form->{db};

    my @fields = ();

    push @fields, {
        name => 'l_ndx',
        label => $locale->text('No.'),
        };
    push @fields, {
        name => 'l_id',
        label => $locale->text('ID'),
        };
    push @fields, {
        name => "l_$form->{db}number",
        label => $locale->text($label . ' Number'),
        };
    push @fields, {
        name => 'l_name',
        label => $locale->text('Company Name'),
        $form->{l_name} => $form->{l_name},
        };
    push @fields, {
        name => 'l_contact',
        label => $locale->text('Contact'),
        $form->{l_contact} => $form->{l_contact},
        };
    push @fields, {
        name => 'l_email',
        label => $locale->text('E-mail'),
        $form->{l_email} => $form->{l_email},
        };
    push @fields, {
        name => 'l_address',
        label => $locale->text('Address'),
        };
    push @fields, {
        name => 'l_city',
        label => $locale->text('City'),
        };
    push @fields, {
        name => 'l_state',
        label => $locale->text('State/Province'),
        };
    push @fields, {
        name => 'l_zipcode',
        label => $locale->text('Zip/Postal Code'),
        };
    push @fields, {
        name => 'l_country',
        label => $locale->text('Country'),
        };
    push @fields, {
        name => 'l_phone',
        label => $locale->text('Phone'),
        $form->{l_phone} => $form->{l_phone},
        };
    push @fields, {
        name => 'l_fax',
        label => $locale->text('Fax'),
        };
    push @fields, {
        name => 'l_cc',
        label => $locale->text('Cc'),
        };

    if ( $myconfig{role} =~ /(admin|manager)/ ) {
        push @fields, {
            name => 'l_bcc',
            label => $locale->text('Bcc'),
            };
    }

    push @fields, {
        name => 'l_notes',
        label => $locale->text('Notes'),
        };
    push @fields, {
        name => 'l_discount',
        label => $locale->text('Discount'),
        };
    push @fields, {
        name => 'l_taxaccount',
        label => $locale->text('Tax Account'),
        };
    push @fields, {
        name => 'l_taxnumber',
        label => $locale->text('Tax Number'),
        };

    if ( $form->{db} eq 'customer' ) {
        push @fields, {
            name => 'l_employee',
            label => $locale->text('Salesperson'),
            };
        push @fields, {
            name => 'l_manager',
            label => $locale->text('Manager'),
            };
        push @fields, {
            name => 'l_pricegroup',
            label => $locale->text('Pricegroup'),
            };

    } else {
        push @fields, {
            name => 'l_employee',
            label => $locale->text('Employee'),
            };
        push @fields, {
            name => 'l_manager',
            label => $locale->text('Manager'),
            };
        push @fields, {
            name => 'l_gifi_accno',
            label => $locale->text('GIFI'),
            };
    }

    push @fields, {
        name => 'l_sic_code',
        label => $locale->text('SIC'),
        };
    push @fields, {
        name => 'l_iban',
        label => $locale->text('IBAN'),
        };
    push @fields, {
        name => 'l_bic',
        label => $locale->text('BIC'),
        };
    push @fields, {
        name => 'l_business',
        label => $locale->text('Type of Business'),
        };
    push @fields, {
        name => 'l_terms',
        label => $locale->text('Terms'),
        };
    push @fields, {
        name => 'l_langauge',
        label => $locale->text('Language'),
        };
    push @fields, {
        name => 'l_startdate',
        label => $locale->text('Startdate'),
        };
    push @fields, {
        name => 'l_enddate',
        label => $locale->text('Enddate'),
        };

    $form->{includes} = [];
    my $i = 0;
    while (@fields) {
        push @{$form->{includes}}, [];
        for ( 1 .. 5 ) {
            push @{$form->{includes}[$i]}, shift(@fields);
            if ($form->{includes}[$i][$_ - 1]) {
                $form->{includes}[$i][$_ - 1]{type} = 'checkbox';
                $form->{includes}[$i][$_ - 1]{value} = 'Y';
            }
        }
        $i++;
    }
}

sub search {

    # $locale->text('Customers')
    # $locale->text('Vendors')

    my %hiddens;
    my @buttons;
    $form->{title} = $locale->text('Search') unless $form->{title};

    for (qw(name contact phone email)) { $form->{"l_$_"} = 'checked' }

    $form->{nextsub} = "list_names";

    &transactions;
    &include_in_report;
    &search_name(\%hiddens, \@buttons);

##SC: Temporary removal
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'ct-search',
        );
    $template->render({
        form => $form,
        user => \%myconfig, 
        hiddens => \%hiddens,
        buttons => \@buttons,
    });
}

sub search_name {

    my $hiddens = shift;
    my $buttons = shift;

    my $label = ucfirst $form->{db};
    $form->{label} = $label;
    $hiddens->{$_} = $form->{$_} foreach qw(db nextsub path login sessionid);
    push @{$buttons}, {
        name => 'action',
        value => 'continue',
        text => $locale->text('Continue'),
        };
}

sub list_names {

    my %hiddens;
    my @buttons;
    my @options;

    CT->search( \%myconfig, \%$form );

    my $href =
"$form->{script}?action=list_names&direction=$form->{direction}&oldsort=$form->{oldsort}&db=$form->{db}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&status=$form->{status}&l_subtotal=$form->{l_subtotal}";

    $form->sort_order();

    my $callback =
"$form->{script}?action=list_names&direction=$form->{direction}&oldsort=$form->{oldsort}&db=$form->{db}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&status=$form->{status}&l_subtotal=$form->{l_subtotal}";

    my @columns = $form->sort_columns( id, name, "$form->{db}number", address,
        city,       state,      zipcode,   country,
        contact,    phone,      fax,       email,
        cc,         bcc,        employee,  manager,
        notes,      discount,   terms,     taxaccount,
        taxnumber,  gifi_accno, sic_code,  business,
        pricegroup, language,   iban,      bic,
        startdate,  enddate,    invnumber, invamount,
        invtax,     invtotal,   ordnumber, ordamount,
        ordtax,     ordtotal,   quonumber, quoamount,
        quotax,     quototal
    );
    unshift @columns, "ndx";

    $form->{l_invnumber} = "Y" if $form->{l_transnumber};
    foreach my $item (qw(inv ord quo)) {
        if ( $form->{"l_${item}number"} ) {
            for (qw(amount tax total)) {
                $form->{"l_$item$_"} = $form->{"l_$_"};
            }
            $removeemployee = 1;
            $openclosed     = 1;
        }
    }
    $form->{open} = $form->{closed} = "" if !$openclosed;

    my @column_index;
    foreach my $item (@columns) {
        if ( $form->{"l_$item"} eq "Y" ) {
            push @column_index, $item;

            # add column to href and callback
            $callback .= "&l_$item=Y";
            $href     .= "&l_$item=Y";
        }
    }

    foreach my $item (qw(amount tax total transnumber)) {
        if ( $form->{"l_$item"} eq "Y" ) {
            $callback .= "&l_$item=Y";
            $href     .= "&l_$item=Y";
        }
    }

    if ( $form->{status} eq 'all' ) {
        push @options, $locale->text('All');
    } elsif ( $form->{status} eq 'orphaned' ) {
        push @options, $locale->text('Orphaned');
    } elsif ( $form->{status} eq 'active' ) {
        push @options, $locale->text('Active');
    } elsif ( $form->{status} eq 'inactive' ) {
        push @options, $locale->text('Inactive');
    }

    if ( $form->{name} ) {
        $callback .= "&name=" . $form->escape( $form->{name}, 1 );
        $href   .= "&name=" . $form->escape( $form->{name} );
        push @options, $locale->text('Name: [_1]', $form->{name});
    }
    if ( $form->{address} ) {
        $callback .= "&address=" . $form->escape( $form->{address}, 1 );
        $href   .= "&address=" . $form->escape( $form->{address} );
        push @options, $locale->text('Address: [_1]', $form->{address});
    }
    if ( $form->{city} ) {
        $callback .= "&city=" . $form->escape( $form->{city}, 1 );
        $href   .= "&city=" . $form->escape( $form->{city} );
        push @options, $locale->text('City: [_1]', $form->{city});
    }
    if ( $form->{state} ) {
        $callback .= "&state=" . $form->escape( $form->{state}, 1 );
        $href   .= "&state=" . $form->escape( $form->{state} );
        push @options, $locale->text('State: [_1]', $form->{state});
    }
    if ( $form->{zipcode} ) {
        $callback .= "&zipcode=" . $form->escape( $form->{zipcode}, 1 );
        $href .= "&zipcode=" . $form->escape( $form->{zipcode} );
        push @options, $locale->text('Zip/Postal Code: [_1]', $form->{zipcode});
    }
    if ( $form->{country} ) {
        $callback .= "&country=" . $form->escape( $form->{country}, 1 );
        $href   .= "&country=" . $form->escape( $form->{country} );
        push @options, $locale->text('Country: [_1]', $form->{country});
    }
    if ( $form->{contact} ) {
        $callback .= "&contact=" . $form->escape( $form->{contact}, 1 );
        $href   .= "&contact=" . $form->escape( $form->{contact} );
        push @options, $locale->text('Contact: [_1]', $form->{contact});
    }
    if ( $form->{employee} ) {
        $callback .= "&employee=" . $form->escape( $form->{employee}, 1 );
        $href   .= "&employee=" . $form->escape( $form->{employee} );
        if ( $form->{db} eq 'customer' ) {
            push @options, $locale->text('Salesperson: [_1]', $form->{employee});
        } elsif ( $form->{db} eq 'vendor' ) {
            push @options, $locale->text('Employee: [_1]', $form->{employee});
        }
    }

    my $fromdate = "";
    my $todate   = "";
    if ( $form->{startdatefrom} ) {
        $callback .= "&startdatefrom=$form->{startdatefrom}";
        $href     .= "&startdatefrom=$form->{startdatefrom}";
        $fromdate = $locale->date( \%myconfig, $form->{startdatefrom}, 1 );
    }
    if ( $form->{startdateto} ) {
        $callback .= "&startdateto=$form->{startdateto}";
        $href     .= "&startdateto=$form->{startdateto}";
        $todate = $locale->date( \%myconfig, $form->{startdateto}, 1 );
    }
    if ( $fromdate || $todate ) {
        push @options,
            $locale->text('Startdate [_1] - [_2]', $fromdate, $todate);
    }

    if ( $form->{notes} ) {
        $callback .= "&notes=" . $form->escape( $form->{notes}, 1 );
        $href   .= "&notes=" . $form->escape( $form->{notes} );
        push @options, $locale->text('Notes: [_1]', $form->{notes});
    }
    if ( $form->{"$form->{db}number"} ) {
        $callback .=
          qq|&$form->{db}number=|
          . $form->escape( $form->{"$form->{db}number"}, 1 );
        $href .=
          "&$form->{db}number=" . $form->escape( $form->{"$form->{db}number"} );
        push @options,
            $locale->text('Number: [_1]', $form->{"$form->{db}number"});
    }
    if ( $form->{phone} ) {
        $callback .= "&phone=" . $form->escape( $form->{phone}, 1 );
        $href   .= "&phone=" . $form->escape( $form->{phone} );
        push @options, $locale->text('Phone: [_1]', $form->{phone});
    }
    if ( $form->{email} ) {
        $callback .= "&email=" . $form->escape( $form->{email}, 1 );
        $href   .= "&email=" . $form->escape( $form->{email} );
        push @options, $locale->text('E-mail: [_1]', $form->{email});
    }
    if ( $form->{transdatefrom} ) {
        $callback .= "&transdatefrom=$form->{transdatefrom}";
        $href     .= "&transdatefrom=$form->{transdatefrom}";
        push @options, $locale->text('From [_1]',
            $locale->date( \%myconfig, $form->{transdatefrom}, 1 ));
    }
    if ( $form->{transdateto} ) {
        $callback .= "&transdateto=$form->{transdateto}";
        $href     .= "&transdateto=$form->{transdateto}";
        if ( $form->{transdatefrom} ) {
            pop @options;
            push @options, $locale->text('From [_1] To [_2]',
                $locale->date( \%myconfig, $form->{transdatefrom}, 1 ),
                $locale->date( \%myconfig, $form->{transdateto}, 1 ));
        } else {
            push @options, $locale->text('To [_1]',
                $locale->date( \%myconfig, $form->{transdateto}, 1 ));
        }
    }
    if ( $form->{open} ) {
        $callback .= "&open=$form->{open}";
        $href     .= "&open=$form->{open}";
        push @options, $locale->text('Open');
    }
    if ( $form->{closed} ) {
        $callback .= "&closed=$form->{closed}";
        $href     .= "&closed=$form->{closed}";
        push @options, $locale->text('Closed');
    }

    $form->{callback} = "$callback&sort=$form->{sort}";
    $callback = $form->escape( $form->{callback} );

    my %column_header;
    $column_header{ndx} = ' ';
    $column_header{id} = $locale->text('ID');
    $column_header{"$form->{db}number"} = {
        href => "$href&sort=$form->{db}number",
        text => $locale->text('Number')
        };
    $column_header{name} = {
        href => "$href&sort=name",
        text => $locale->text('Name')
        };
    $column_header{address} = $locale->text('Address');
    $column_header{city} = {
        href => "$href&sort=city",
        text => $locale->text('City')
        };
    $column_header{state} = {
        href => "$href&sort=state",
        text => $locale->text('State/Province')
        };
    $column_header{zipcode} = {
        href => "$href&sort=zipcode",
        text => $locale->text('Zip/Postal Code')
        };
    $column_header{country} = {
        href => "$href&sort=country",
        text => $locale->text('Country')
        };
    $column_header{contact} = {
        href => "$href&sort=contact",
        text => $locale->text('Contact'),
        };
    $column_header{phone} = {
        href => "$href&sort=phone",
        text => $locale->text('Phone')
        };
    $column_header{fax} = {
        href => "$href&sort=fax",
        text => $locale->text('Fax')
        };
    $column_header{email} = {
        href => "$href&sort=email",
        text => $locale->text('E-mail')
        };
    $column_header{cc} = {
        href => "$href&sort=cc",
        text => $locale->text('Cc')
        };
    $column_header{bcc} = {
        href => "$href&sort=cc",
        text => $locale->text('Bcc')
        };
    $column_header{notes} = {
        href => "$href&sort=notes",
        text => $locale->text('Notes')
        };
    $column_header{discount} = '%';
    $column_header{terms} = $locale->text('Terms');

    $column_header{taxnumber} = {
        href => "$href&sort=taxnumber",
        text => $locale->text('Tax Number')
        };
    $column_header{taxaccount} = $locale->text('Tax Account');
    $column_header{gifi_accno} = {
        href => "$href&sort=gifi_accno",
        text => $locale->text('GIFI')
        };
    $column_header{sic_code} = {
        href => "$href&sort=sic_code",
        text => $locale->text('SIC')
        };
    $column_header{business} = {
        href => "$href&sort=business",
        text => $locale->text('Type of Business')
        };
    $column_header{iban} = $locale->text('IBAN');
    $column_header{bic} = $locale->text('BIC');
    $column_header{startdate} = {
        href => "$href&sort=startdate",
        text => $locale->text('Startdate')
        };
    $column_header{enddate} = {
        href => "$href&sort=enddate",
        text => $locale->text('Enddate')
        };

    $column_header{invnumber} = {
        href => "$href&sort=invnumber",
        text => $locale->text('Invoice')
        };
    $column_header{ordnumber} = {
        href => "$href&sort=ordnumber",
        text => $locale->text('Order')
        };
    $column_header{quonumber} = {
        href => "$href&sort=quonumber",
        text => $locale->text('Quotation')
        };

    if ( $form->{db} eq 'customer' ) {
        $column_header{employee} = {
            href => "$href&sort=employee",
            text => $locale->text('Salesperson')
            };
    } else {
        $column_header{employee} = {
            href => "$href&sort=employee",
            text => $locale->text('Employee')
            };
    }
    $column_header{manager} = {
        href => "$href&sort=manager",
        text => $locale->text('Manager')
        };

    $column_header{pricegroup} = {
        href => "$href&sort=pricegroup",
        text => $locale->text('Pricegroup')
        };
    $column_header{language} = {
        href => "$href&sort=language",
        text => $locale->text('Language')
        };

    $amount = $locale->text('Amount');
    $tax    = $locale->text('Tax');
    $total  = $locale->text('Total');

    $column_header{invamount} = $amount;
    $column_header{ordamount} = $amount;
    $column_header{quoamount} = $amount;

    $column_header{invtax} = $tax;
    $column_header{ordtax} = $tax;
    $column_header{quotax} = $tax;

    $column_header{invtotal} = $total;
    $column_header{ordtotal} = $total;
    $column_header{quototal} = $total;

    if ( $form->{status} ) {
        $label = ucfirst $form->{db} . "s";
        $form->{title} = $locale->text($label);
    } else {
        $label = ucfirst $form->{db};
        $form->{title} = $locale->text( $label . " Transactions" );
    }

    my $ordertype =
      ( $form->{db} eq 'customer' ) ? 'sales_order' : 'purchase_order';
    my $quotationtype =
      ( $form->{db} eq 'customer' ) ? 'sales_quotation' : 'request_quotation';
    $subtotal = 0;

    my $i = 0;
    my @rows;
    foreach my $ref ( @{ $form->{CT} } ) {

        if ( $ref->{ $form->{sort} } ne $sameitem && $form->{l_subtotal} ) {
            # append subtotal
            if ($subtotal) {
                push @rows, &list_subtotal;
            }
        }

        my %column_data;
        if ( $ref->{id} eq $sameid ) {
            for (@column_index) { $column_data{$_} = ' ' }
        } else {

            $i++;

            $ref->{notes} =~ s/\r?\n/<br>/g;
            for (@column_index) {
                $column_data{$_} = $ref->{$_};
            }
            $column_data{ndx} = $i;

            if ( $ref->{ $form->{sort} } eq $sameitem ) {
                $column_data{ $form->{sort} } = ' ';
            }

            $column_data{address} =
              "$ref->{address1} $ref->{address2}";
            $column_data{name} = {
                text => $ref->{name},
                href => "$form->{script}?action=edit&id=$ref->{id}&db=$form->{db}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&status=$form->{status}&callback=$callback",
                };

            $email = "";
            if ( $form->{sort} =~ /(email|cc)/ ) {
                if ( $ref->{ $form->{sort} } ne $sameitem ) {
                    $email = 1;
                }
            } else {
                $email = 1;
            }

            if ($email) {
                foreach $item (qw(email cc bcc)) {
                    if ( $ref->{$item} ) {
                        $email = $ref->{$item};
                        $column_data{$item} = {
                            href => "mailto:$ref->{$item}",
                            text => $email,
                            };
                    }
                }
            }
        }

        if ( $ref->{formtype} eq 'invoice' ) {
            $column_data{invnumber} = {
                href => "$ref->{module}.pl?action=edit&id=$ref->{invid}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback",
                text => $ref->{invnumber},
                };

            $column_data{invamount} =
                $form->format_amount( \%myconfig, $ref->{netamount}, 2, ' ' );
            $column_data{invtax} = $form->format_amount( \%myconfig,
                $ref->{amount} - $ref->{netamount}, 2, ' ' );
            $column_data{invtotal} =
                $form->format_amount( \%myconfig, $ref->{amount}, 2, ' ' );

            $invamountsubtotal += $ref->{netamount};
            $invtaxsubtotal    += ( $ref->{amount} - $ref->{netamount} );
            $invtotalsubtotal  += $ref->{amount};
            $subtotal = 1;
        } elsif ( $ref->{formtype} eq 'order' ) {
            $column_data{ordnumber} = {
                href => "$ref->{module}.pl?action=edit&id=$ref->{invid}&type=$ordertype&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback",
                text => $ref->{ordnumber},
                };

            $column_data{ordamount} =
                $form->format_amount( \%myconfig, $ref->{netamount}, 2, ' ' );
            $column_data{ordtax} = $form->format_amount( \%myconfig,
                $ref->{amount} - $ref->{netamount}, 2, ' ' );
            $column_data{ordtotal} =
                $form->format_amount( \%myconfig, $ref->{amount}, 2, ' ' );

            $ordamountsubtotal += $ref->{netamount};
            $ordtaxsubtotal    += ( $ref->{amount} - $ref->{netamount} );
            $ordtotalsubtotal  += $ref->{amount};
            $subtotal = 1;
        } elsif ( $ref->{formtype} eq 'quotation' ) {
            $column_data{quonumber} = {
                href => "$ref->{module}.pl?action=edit&id=$ref->{invid}&type=$quotationtype&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback",
                text => $ref->{quonumber},
                };

            $column_data{quoamount} =
                $form->format_amount( \%myconfig, $ref->{netamount}, 2, ' ' );
            $column_data{quotax} = $form->format_amount( \%myconfig,
                $ref->{amount} - $ref->{netamount}, 2, ' ' );
            $column_data{quototal} =
                $form->format_amount( \%myconfig, $ref->{amount}, 2, ' ' );

            $quoamountsubtotal += $ref->{netamount};
            $quotaxsubtotal    += ( $ref->{amount} - $ref->{netamount} );
            $quototalsubtotal  += $ref->{amount};
            $subtotal = 1;
        }

        if ( $sameid ne "$ref->{id}" ) {
            if ( $form->{l_discount} ) {
                $column_data{discount} = 
                    $form->format_amount( \%myconfig, $ref->{discount} * 100,
                    "", ' ' );
            }
            if ( $form->{l_terms} ) {
                $column_data{terms} = 
                    $form->format_amount( \%myconfig, $ref->{terms}, "", ' ' );
            }
        }

        $j++;
        $j %= 2;
        $column_data{i} = $j;

        $sameitem = $ref->{$form->{sort}};
        $sameid   = $ref->{id};

        push @rows, \%column_data;
    }

    if ( $form->{l_subtotal} && $subtotal ) {
        push @rows, &list_subtotal;
    }

    $i = 1;
    if ( $myconfig{acs} !~ /AR--AR/ ) {
        if ( $form->{db} eq 'customer' ) {
            $button{'AR--Customers--Add Customer'}{code} = {
                name => 'action',
                value => 'add_customer',
                text => $locale->text('Add Customer'),
                };
            $button{'AR--Customers--Add Customer'}{order} = $i++;
        }
    }
    if ( $myconfig{acs} !~ /AP--AP/ ) {
        if ( $form->{db} eq 'vendor' ) {
            $button{'AP--Vendors--Add Vendor'}{code} = {
                name => 'action',
                value => 'add_vendor',
                text => $locale->text('Add Vendor'),
                };
            $button{'AP--Vendors--Add Vendor'}{order} = $i++;
        }
    }

    foreach $item ( split /;/, $myconfig{acs} ) {
        delete $button{$item};
    }

    $hiddens{$_} = $form->{$_} foreach qw(callback db path login sessionid);

    if ( $form->{status} ) {
        foreach $item ( sort { $a->{order} <=> $b->{order} } %button ) {
            push @buttons, $item->{code};
        }
    }

##SC: Temporary removal
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'form-dynatable',
        );
    $template->render({
        form => $form,
        user => \%myconfig, 
        hiddens => \%hiddens,
        buttons => \@buttons,
        options => \@options,
        rows => \@rows,
        columns => \@column_index,
        heading => \%column_header,
    });
}

sub list_subtotal {

    my %column_data;
    $column_data{invamount} =
        $form->format_amount( \%myconfig, $invamountsubtotal, 2, ' ' );
    $column_data{invtax} =
        $form->format_amount( \%myconfig, $invtaxsubtotal, 2, ' ' );
    $column_data{invtotal} =
        $form->format_amount( \%myconfig, $invtotalsubtotal, 2, ' ' );

    $invamountsubtotal = 0;
    $invtaxsubtotal    = 0;
    $invtotalsubtotal  = 0;

    $column_data{ordamount} =
        $form->format_amount( \%myconfig, $ordamountsubtotal, 2, ' ' );
    $column_data{ordtax} =
        $form->format_amount( \%myconfig, $ordtaxsubtotal, 2, ' ' );
    $column_data{ordtotal} =
        $form->format_amount( \%myconfig, $ordtotalsubtotal, 2, ' ' );

    $ordamountsubtotal = 0;
    $ordtaxsubtotal    = 0;
    $ordtotalsubtotal  = 0;

    $column_data{quoamount} =
        $form->format_amount( \%myconfig, $quoamountsubtotal, 2, ' ' );
    $column_data{quotax} =
        $form->format_amount( \%myconfig, $quotaxsubtotal, 2, ' ' );
    $column_data{quototal} =
        $form->format_amount( \%myconfig, $quototalsubtotal, 2, ' ' );

    $quoamountsubtotal = 0;
    $quotaxsubtotal    = 0;
    $quototalsubtotal  = 0;

    $column_data{class} = 'subtotal';
    \%column_data;
}

sub list_history {

    CT->get_history( \%myconfig, \%$form );

    $href =
"$form->{script}?action=list_history&direction=$form->{direction}&oldsort=$form->{oldsort}&db=$form->{db}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&type=$form->{type}&transdatefrom=$form->{transdatefrom}&transdateto=$form->{transdateto}&history=$form->{history}";

    $form->sort_order();

    $callback =
"$form->{script}?action=list_history&direction=$form->{direction}&oldsort=$form->{oldsort}&db=$form->{db}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&type=$form->{type}&transdatefrom=$form->{transdatefrom}&transdateto=$form->{transdateto}&history=$form->{history}";

    $form->{l_fxsellprice} = $form->{l_curr};
    @columns = $form->sort_columns( partnumber, description, qty, unit,
        sellprice,    fxsellprice,   curr, discount,
        deliverydate, projectnumber, serialnumber
    );

    if ( $form->{history} eq 'summary' ) {
        @columns =
          $form->sort_columns( partnumber, description, qty, unit, sellprice,
            curr );
    }

    foreach $item (@columns) {
        if ( $form->{"l_$item"} eq "Y" ) {
            push @column_index, $item;

            # add column to href and callback
            $callback .= "&l_$item=Y";
            $href     .= "&l_$item=Y";
        }
    }

    if ( $form->{history} eq 'detail' ) {
        $option = $locale->text('Detail');
    }
    if ( $form->{history} eq 'summary' ) {
        $option .= $locale->text('Summary');
    }
    if ( $form->{name} ) {
        $callback .= "&name=" . $form->escape( $form->{name}, 1 );
        $href   .= "&name=" . $form->escape( $form->{name} );
        $option .= "\n<br>" . $locale->text('Name') . " : $form->{name}";
    }
    if ( $form->{contact} ) {
        $callback .= "&contact=" . $form->escape( $form->{contact}, 1 );
        $href   .= "&contact=" . $form->escape( $form->{contact} );
        $option .= "\n<br>" . $locale->text('Contact') . " : $form->{contact}";
    }
    if ( $form->{"$form->{db}number"} ) {
        $callback .=
          qq|&$form->{db}number=|
          . $form->escape( $form->{"$form->{db}number"}, 1 );
        $href .=
          "&$form->{db}number=" . $form->escape( $form->{"$form->{db}number"} );
        $option .= "\n<br>"
          . $locale->text('Number')
          . qq| : $form->{"$form->{db}number"}|;
    }
    if ( $form->{email} ) {
        $callback .= "&email=" . $form->escape( $form->{email}, 1 );
        $href   .= "&email=" . $form->escape( $form->{email} );
        $option .= "\n<br>" . $locale->text('E-mail') . " : $form->{email}";
    }
    if ( $form->{transdatefrom} ) {
        $callback .= "&transdatefrom=$form->{transdatefrom}";
        $href     .= "&transdatefrom=$form->{transdatefrom}";
        $option   .= "\n<br>" if ($option);
        $option .=
            $locale->text('From') . "&nbsp;"
          . $locale->date( \%myconfig, $form->{transdatefrom}, 1 );
    }
    if ( $form->{transdateto} ) {
        $callback .= "&transdateto=$form->{transdateto}";
        $href     .= "&transdateto=$form->{transdateto}";
        if ( $form->{transdatefrom} ) {
            $option .= " ";
        }
        else {
            $option .= "\n<br>" if ($option);
        }
        $option .=
            $locale->text('To') . "&nbsp;"
          . $locale->date( \%myconfig, $form->{transdateto}, 1 );
    }
    if ( $form->{open} ) {
        $callback .= "&open=$form->{open}";
        $href     .= "&open=$form->{open}";
        $option   .= "\n<br>" if ($option);
        $option   .= $locale->text('Open');
    }
    if ( $form->{closed} ) {
        $callback .= "&closed=$form->{closed}";
        $href     .= "&closed=$form->{closed}";
        $option   .= "\n<br>" if ($option);
        $option   .= $locale->text('Closed');
    }

    $form->{callback} = "$callback&sort=$form->{sort}";
    $callback = $form->escape( $form->{callback} );

    $column_header{partnumber} =
        qq|<th><a class=listheading href=$href&sort=partnumber>|
      . $locale->text('Part Number')
      . qq|</a></th>|;
    $column_header{description} =
        qq|<th><a class=listheading href=$href&sort=description>|
      . $locale->text('Description')
      . qq|</a></th>|;

    if ( $form->{history} eq 'summary' ) {
        $column_header{sellprice} =
          qq|<th class=listheading>| . $locale->text('Total') . qq|</th>|;
    }
    else {
        $column_header{sellprice} =
          qq|<th class=listheading>| . $locale->text('Sell Price') . qq|</th>|;
    }
    $column_header{fxsellprice} = qq|<th>&nbsp;</th>|;

    $column_header{curr} =
      qq|<th class=listheading>| . $locale->text('Curr') . qq|</th>|;
    $column_header{discount} =
      qq|<th class=listheading>| . $locale->text('Discount') . qq|</th>|;
    $column_header{qty} =
      qq|<th class=listheading>| . $locale->text('Qty') . qq|</th>|;
    $column_header{unit} =
      qq|<th class=listheading>| . $locale->text('Unit') . qq|</th>|;
    $column_header{deliverydate} =
        qq|<th><a class=listheading href=$href&sort=deliverydate>|
      . $locale->text('Delivery Date')
      . qq|</a></th>|;
    $column_header{projectnumber} =
        qq|<th><a class=listheading href=$href&sort=projectnumber>|
      . $locale->text('Project Number')
      . qq|</a></th>|;
    $column_header{serialnumber} =
        qq|<th><a class=listheading href=$href&sort=serialnumber>|
      . $locale->text('Serial Number')
      . qq|</a></th>|;

    # $locale->text('Customer History')
    # $locale->text('Vendor History')

    $label = ucfirst $form->{db};
    $form->{title} = $locale->text( $label . " History" );

    $colspan = $#column_index + 1;

    $form->header;

    print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
|;

    for (@column_index) { print "$column_header{$_}\n" }

    print qq|
        </tr>
|;

    $module = 'oe';
    if ( $form->{db} eq 'customer' ) {
        $invlabel = $locale->text('Sales Invoice');
        $ordlabel = $locale->text('Sales Order');
        $quolabel = $locale->text('Quotation');

        $ordertype     = 'sales_order';
        $quotationtype = 'sales_quotation';
        if ( $form->{type} eq 'invoice' ) {
            $module = 'is';
        }
    }
    else {
        $invlabel = $locale->text('Vendor Invoice');
        $ordlabel = $locale->text('Purchase Order');
        $quolabel = $locale->text('RFQ');

        $ordertype     = 'purchase_order';
        $quotationtype = 'request_quotation';
        if ( $form->{type} eq 'invoice' ) {
            $module = 'ir';
        }
    }

    $ml = ( $form->{db} eq 'vendor' ) ? -1 : 1;

    foreach $ref ( @{ $form->{CT} } ) {

        if ( $ref->{id} ne $sameid ) {

            # print the header
            print qq|
        <tr class=listheading>
	  <th colspan=$colspan><a class=listheading href=$form->{script}?action=edit&id=$ref->{ctid}&db=$form->{db}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{name} $ref->{address}</a></th>
	</tr>
|;
        }

        if ( $form->{type} ne 'invoice' ) {
            $ref->{fxsellprice} = $ref->{sellprice};
            $ref->{sellprice} *= $ref->{exchangerate};
        }

        if ( $form->{history} eq 'detail' and $ref->{invid} ne $sameinvid ) {

            # print inv, ord, quo number
            $i++;
            $i %= 2;

            print qq|
	  <tr class=listrow$i>
|;

            if ( $form->{type} eq 'invoice' ) {
                print
qq|<th align=left colspan=$colspan><a href=${module}.pl?action=edit&id=$ref->{invid}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$invlabel $ref->{invnumber} / $ref->{employee}</a></th>|;
            }

            if ( $form->{type} eq 'order' ) {
                print
qq|<th align=left colspan=$colspan><a href=${module}.pl?action=edit&id=$ref->{invid}&type=$ordertype&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ordlabel $ref->{ordnumber} / $ref->{employee}</a></th>|;
            }

            if ( $form->{type} eq 'quotation' ) {
                print
qq|<th align=left colspan=$colspan><a href=${module}.pl?action=edit&id=$ref->{invid}&type=$quotationtype&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$quolabel $ref->{quonumber} / $ref->{employee}</a></th>|;
            }

            print qq|
          </tr>
|;
        }

        for (@column_index) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }

        if ( $form->{l_curr} ) {
            $column_data{fxsellprice} =
                qq|<td align=right>|
              . $form->format_amount( \%myconfig, $ref->{fxsellprice}, 2 )
              . "</td>";
        }
        $column_data{sellprice} =
          qq|<td align=right>|
          . $form->format_amount( \%myconfig, $ref->{sellprice}, 2 ) . "</td>";

        $column_data{qty} =
          qq|<td align=right>|
          . $form->format_amount( \%myconfig, $ref->{qty} * $ml ) . "</td>";
        $column_data{discount} = qq|<td align=right>|
          . $form->format_amount( \%myconfig, $ref->{discount} * 100,
            "", "&nbsp;" )
          . "</td>";
        $column_data{partnumber} =
qq|<td><a href=ic.pl?action=edit&id=$ref->{pid}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{partnumber}</td>|;

        $i++;
        $i %= 2;
        print qq|
        <tr class=listrow$i>
|;

        for (@column_index) { print "$column_data{$_}\n" }

        print qq|
        </tr>
|;

        $sameid    = $ref->{id};
        $sameinvid = $ref->{invid};

    }

    print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

|;

    if ( $form->{lynx} ) {
        require "bin/menu.pl";
        &menubar;
    }

    print qq|
  </form>

</body>
</html>
|;

}

sub edit {

    # $locale->text('Edit Customer')
    # $locale->text('Edit Vendor')

    CT->create_links( \%myconfig, \%$form );

    for ( keys %$form ) { $form->{$_} = $form->quote( $form->{$_} ) }

    $form->{title} = "Edit";

    # format discount
    $form->{discount} *= 100;

    &form_header;
    &form_footer;

}

sub form_header {

    $form->{taxincluded} = ( $form->{taxincluded} ) ? "checked" : "";
    $form->{creditlimit} =
      $form->format_amount( \%myconfig, $form->{creditlimit}, 0 );
    $form->{discount} =
      $form->format_amount( \%myconfig, $form->{discount}, "" );
    $form->{terms} = $form->format_amount( \%myconfig, $form->{terms}, "" );

    if ( $myconfig{role} =~ /(admin|manager)/ ) {
        $bcc = qq|
        <tr>
	  <th align=right nowrap>| . $locale->text('Bcc') . qq|</th>
	  <td><input name=bcc size=35 value="$form->{bcc}"></td>
	</tr>
|;
    }

    if ( $form->{currencies} ) {

        # currencies
        for ( split /:/, $form->{currencies} ) {
            $form->{selectcurrency} .= "<option>$_\n";
        }
        $form->{selectcurrency} =~ s/option>($form->{curr})/option selected>$1/;
        $currency = qq|
	  <th>| . $locale->text('Currency') . qq|</th>
	  <td><select name=curr>$form->{selectcurrency}</select></td>
|;
    }

    foreach $item ( split / /, $form->{taxaccounts} ) {
        if ( $form->{tax}{$item}{taxable} ) {
            $taxable .=
qq| <input name="tax_$item" value=1 class=checkbox type=checkbox checked>&nbsp;<b>$form->{tax}{$item}{description}</b>|;
        }
        else {
            $taxable .=
qq| <input name="tax_$item" value=1 class=checkbox type=checkbox>&nbsp;<b>$form->{tax}{$item}{description}</b>|;
        }
    }

    if ($taxable) {
        $tax = qq|
	<tr>
	  <th align=right>| . $locale->text('Taxable') . qq|</th>
	  <td colspan=5>
	    <table>
	      <tr>
		<td>$taxable</td>
		<td><input name=taxincluded class=checkbox type=checkbox value=1 $form->{taxincluded}></td>
		<th align=left>| . $locale->text('Tax Included') . qq|</th>
	      </tr>
	    </table>
	  </td>
	</tr>
|;
    }

    $typeofbusiness = qq|
          <th></th>
	  <td></td>
|;

    if ( @{ $form->{all_business} } ) {
        $form->{selectbusiness} = qq|<option>\n|;
        for ( @{ $form->{all_business} } ) {
            $form->{selectbusiness} .=
qq|<option value="$_->{description}--$_->{id}">$_->{description}\n|;
        }

        $form->{selectbusiness} =~
s/(<option value="\Q$form->{business}--$form->{business_id}\E")>/$1 selected>/;

        $typeofbusiness = qq|
 	  <th align=right>| . $locale->text('Type of Business') . qq|</th>
	  <td><select name=business>$form->{selectbusiness}</select></td>
|;

    }

    $pricegroup = qq|
          <th></th>
	  <td></td>
|;

    if ( @{ $form->{all_pricegroup} } && $form->{db} eq 'customer' ) {
        $form->{selectpricegroup} = qq|<option>\n|;
        for ( @{ $form->{all_pricegroup} } ) {
            $form->{selectpricegroup} .=
              qq|<option value="$_->{pricegroup}--$_->{id}">$_->{pricegroup}\n|;
        }

        $form->{selectpricegroup} =~
s/(<option value="\Q$form->{pricegroup}--$form->{pricegroup_id}\E")/$1 selected/;

        $pricegroup = qq|
 	  <th align=right>| . $locale->text('Pricegroup') . qq|</th>
	  <td><select name=pricegroup>$form->{selectpricegroup}</select></td>
|;
    }

    $lang = qq|
          <th></th>
	  <td></td>
|;

    if ( @{ $form->{all_language} } ) {
        $form->{selectlanguage} = qq|<option>\n|;
        for ( @{ $form->{all_language} } ) {
            $form->{selectlanguage} .=
qq|<option value="$_->{description}--$_->{code}">$_->{description}\n|;
        }

        $form->{selectlanguage} =~
s/(<option value="\Q$form->{language}--$form->{language_code}\E")/$1 selected/;

        $lang = qq|
 	  <th align=right>| . $locale->text('Language') . qq|</th>
	  <td><select name=language>$form->{selectlanguage}</select></td>
|;
    }

    $employeelabel = $locale->text('Salesperson');

    $form->{selectemployee} = qq|<option>\n|;
    for ( @{ $form->{all_employee} } ) {
        $form->{selectemployee} .=
          qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
    }

    $form->{selectemployee} =~
s/(<option value="\Q$form->{employee}--$form->{employee_id}\E")/$1 selected/;

    if ( $form->{db} eq 'vendor' ) {
        $gifi = qq|
    	  <th align=right>| . $locale->text('Sub-contract GIFI') . qq|</th>
	  <td><input name=gifi_accno size=9 value="$form->{gifi_accno}"></td>
|;
        $employeelabel = $locale->text('Employee');
    }

    if ( @{ $form->{all_employee} } ) {
        $employee = qq|
	        <th align=right>$employeelabel</th>|;

        if ( $myconfig{role} ne 'user' || !$form->{id} ) {
            $employee .= qq|
		<td><select name=employee>$form->{selectemployee}</select></td>
|;
        }
        else {
            $employee .= qq|
                <td>$form->{employee}</td>
		<input type=hidden name=employee value="$form->{employee}--$form->{employee_id}">|;
        }
    }

    # $locale->text('Customer Number')
    # $locale->text('Vendor Number')

    $label = ucfirst $form->{db};
    $form->{title} = $locale->text("$form->{title} $label");

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr valign=top>
	  <td width=50%>
	    <table width=100%>
	      <tr class=listheading>
		<th class=listheading colspan=2 width=50%>|
      . $locale->text('Billing Address')
      . qq|</th>
	      <tr>
		<th align=right nowrap>| . $locale->text( $label . ' Number' ) . qq|</th>
		<td><input name="$form->{db}number" size=35 maxlength=32 value="$form->{"$form->{db}number"}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Company Name') . qq|</th>
		<td><input name=name size=35 maxlength=64 value="$form->{name}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Address') . qq|</th>
		<td><input name=address1 size=35 maxlength=32 value="$form->{address1}"></td>
	      </tr>
	      <tr>
		<th></th>
		<td><input name=address2 size=35 maxlength=32 value="$form->{address2}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('City') . qq|</th>
		<td><input name=city size=35 maxlength=32 value="$form->{city}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('State/Province') . qq|</th>
		<td><input name=state size=35 maxlength=32 value="$form->{state}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Zip/Postal Code') . qq|</th>
		<td><input name=zipcode size=10 maxlength=10 value="$form->{zipcode}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Country') . qq|</th>
		<td><input name=country size=35 maxlength=32 value="$form->{country}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Contact') . qq|</th>
		<td><input name=contact size=35 maxlength=64 value="$form->{contact}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Phone') . qq|</th>
		<td><input name=phone size=20 maxlength=20 value="$form->{phone}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Fax') . qq|</th>
		<td><input name=fax size=20 maxlength=20 value="$form->{fax}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('E-mail') . qq|</th>
		<td><input name=email size=35 value="$form->{email}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Cc') . qq|</th>
		<td><input name=cc size=35 value="$form->{cc}"></td>
	      </tr>
	      $bcc
	    </table>
	  </td>
	  <td width=50%>
	    <table width=100%>
	      <tr>
		<th class=listheading colspan=2>|
      . $locale->text('Shipping Address')
      . qq|</th>
	      </tr>
	      <tr>
		<td><input name=none size=35 value=| . ( "=" x 35 ) . qq|></td>
	      </tr>
	      <tr>
		<td><input name=shiptoname size=35 maxlength=64 value="$form->{shiptoname}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptoaddress1 size=35 maxlength=32 value="$form->{shiptoaddress1}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptoaddress2 size=35 maxlength=32 value="$form->{shiptoaddress2}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptocity size=35 maxlength=32 value="$form->{shiptocity}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptostate size=35 maxlength=32 value="$form->{shiptostate}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptozipcode size=10 maxlength=10 value="$form->{shiptozipcode}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptocountry size=35 maxlength=32 value="$form->{shiptocountry}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptocontact size=35 maxlength=64 value="$form->{shiptocontact}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptophone size=20 maxlength=20 value="$form->{shiptophone}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptofax size=20 maxlength=20 value="$form->{shiptofax}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptoemail size=35 value="$form->{shiptoemail}"></td>
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
	$tax
	<tr>
	  <th align=right>| . $locale->text('Startdate') . qq|</th>
	  <td><input class="date" name=startdate size=11 title="$myconfig{dateformat}" value=$form->{startdate}></td>
	  <th align=right>| . $locale->text('Enddate') . qq|</th>
	  <td><input class="date" name=enddate size=11 title="$myconfig{dateformat}" value=$form->{enddate}></td>
	</tr>
	<tr>
	  <th align=right>| . $locale->text('Credit Limit') . qq|</th>
	  <td><input name=creditlimit size=9 value="$form->{creditlimit}"></td>
	  <th align=right>| . $locale->text('Terms') . qq|</th>
	  <td><input name=terms size=2 value="$form->{terms}"> <b>|
      . $locale->text('days')
      . qq|</b></td>
	  <th align=right>| . $locale->text('Discount') . qq|</th>
	  <td><input name=discount size=4 value="$form->{discount}">
	  <b>%</b></td>
	</tr>
	<tr>
	  <th align=right>| . $locale->text('Tax Number / SSN') . qq|</th>
	  <td><input name=taxnumber size=20 value="$form->{taxnumber}"></td>
	  $gifi
	  <th align=right>| . $locale->text('SIC') . qq|</th>
	  <td><input name=sic_code size=6 maxlength=6 value="$form->{sic_code}"></td>
	</tr>
	<tr>
	  $typeofbusiness
	  <th align=right>| . $locale->text('BIC') . qq|</th>
	  <td><input name=bic size=11 maxlength=11 value="$form->{bic}"></td>
	  <th align=right>| . $locale->text('IBAN') . qq|</th>
	  <td><input name=iban size=24 maxlength=34 value="$form->{iban}"></td>
	</tr>
	<tr>
	  $pricegroup
	  $lang
	  $currency
	</tr>
	<tr valign=top>
	  $employee
	  <td colspan=4>
	    <table>
	      <tr valign=top>
		<th align=left nowrap>| . $locale->text('Notes') . qq|</th>
		<td><textarea name=notes rows=3 cols=40 wrap=soft>$form->{notes}</textarea></td>
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

}

sub form_footer {

    # type=submit $locale->text('Save')
    # type=submit $locale->text('Save as new')
    # type=submit $locale->text('AR Transaction')
    # type=submit $locale->text('Sales Invoice')
    # type=submit $locale->text('Sales Order')
    # type=submit $locale->text('Quotation')
    # type=submit $locale->text('AP Transaction')
    # type=submit $locale->text('Vendor Invoice')
    # type=submit $locale->text('Purchase Order')
    # type=submit $locale->text('RFQ')
    # type=submit $locale->text('Pricelist')
    # type=submit $locale->text('Delete')
    # type=submit $locale->text('POS')

    %button = (
        'save' => { ndx => 1, key => 'S', value => $locale->text('Save') },
        'save_as_new' =>
          { ndx => 2, key => 'N', value => $locale->text('Save as new') },
        'ar_transaction' =>
          { ndx => 7, key => 'A', value => $locale->text('AR Transaction') },
        'ap_transaction' =>
          { ndx => 8, key => 'A', value => $locale->text('AP Transaction') },
        'sales_invoice' =>
          { ndx => 9, key => 'I', value => $locale->text('Sales Invoice') },
        'pos' => { ndx => 10, key => 'C', value => $locale->text('POS') },
        'sales_order' =>
          { ndx => 11, key => 'O', value => $locale->text('Sales Order') },
        'quotation' =>
          { ndx => 12, key => 'Q', value => $locale->text('Quotation') },
        'vendor_invoice' =>
          { ndx => 13, key => 'I', value => $locale->text('Vendor Invoice') },
        'purchase_order' =>
          { ndx => 14, key => 'O', value => $locale->text('Purchase Order') },
        'rfq' => { ndx => 15, key => 'Q', value => $locale->text('RFQ') },
        'pricelist' =>
          { ndx => 16, key => 'P', value => $locale->text('Pricelist') },
        'delete' => { ndx => 17, key => 'D', value => $locale->text('Delete') },
    );

    %a = ();

    if ( $form->{db} eq 'customer' ) {
        if ( $myconfig{acs} !~ /AR--Customers--Add Customer/ ) {
            $a{'save'} = 1;

            if ( $form->{id} ) {
                $a{'save_as_new'} = 1;
                if ( $form->{status} eq 'orphaned' ) {
                    $a{'delete'} = 1;
                }
            }
        }

        if ( $myconfig{acs} !~ /AR--AR/ ) {
            if ( $myconfig{acs} !~ /AR--Add Transaction/ ) {
                $a{'ar_transaction'} = 1;
            }
            if ( $myconfig{acs} !~ /AR--Sales Invoice/ ) {
                $a{'sales_invoice'} = 1;
            }
        }
        if ( $myconfig{acs} !~ /POS--POS/ ) {
            if ( $myconfig{acs} !~ /POS--Sale/ ) {
                $a{'pos'} = 1;
            }
        }
        if ( $myconfig{acs} !~ /Order Entry--Order Entry/ ) {
            if ( $myconfig{acs} !~ /Order Entry--Sales Order/ ) {
                $a{'sales_order'} = 1;
            }
        }
        if ( $myconfig{acs} !~ /Quotations--Quotations/ ) {
            if ( $myconfig{acs} !~ /Quotations--Quotation/ ) {
                $a{'quotation'} = 1;
            }
        }
    }

    if ( $form->{db} eq 'vendor' ) {
        if ( $myconfig{acs} !~ /AP--Vendors--Add Vendor/ ) {
            $a{'save'} = 1;

            if ( $form->{id} ) {
                $a{'save_as_new'} = 1;
                if ( $form->{status} eq 'orphaned' ) {
                    $a{'delete'} = 1;
                }
            }
        }

        if ( $myconfig{acs} !~ /AP--AP/ ) {
            if ( $myconfig{acs} !~ /AP--Add Transaction/ ) {
                $a{'ap_transaction'} = 1;
            }
            if ( $myconfig{acs} !~ /AP--Vendor Invoice/ ) {
                $a{'vendor_invoice'} = 1;
            }
        }
        if ( $myconfig{acs} !~ /Order Entry--Order Entry/ ) {
            if ( $myconfig{acs} !~ /Order Entry--Purchase Order/ ) {
                $a{'purchase_order'} = 1;
            }
        }
        if ( $myconfig{acs} !~ /Quotations--Quotations/ ) {
            if ( $myconfig{acs} !~ /Quotations--RFQ/ ) {
                $a{'rfq'} = 1;
            }
        }
    }

    if ( $myconfig{acs} !~ /Goods & Services--Goods & Services/ ) {
        $myconfig{acs} =~
          s/(Goods & Services--)Add (Service|Assembly).*;/$1--Add Part/g;
        if ( $myconfig{acs} !~ /Goods & Services--Add Part/ ) {
            $a{'pricelist'} = 1;
        }
    }

    $form->hide_form(qw(id taxaccounts path login sessionid callback db));

    for ( keys %button ) { delete $button{$_} if !$a{$_} }
    for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button ) {
        $form->print_button( \%button, $_ );
    }

    if ( $form->{lynx} ) {
        require "bin/menu.pl";
        &menubar;
    }

    print qq|
 
  </form>

</body>
</html>
|;

}

sub pricelist {

    $form->isblank( "name", $locale->text('Name missing!') );

    $form->{display_form} ||= "display_pricelist";

    CT->pricelist( \%myconfig, \%$form );

    foreach $ref ( @{ $form->{"all_partspricelist"} } ) {
        $i++;
        for ( keys %$ref ) { $form->{"${_}_$i"} = $ref->{$_} }
    }
    $form->{rowcount} = $i;

    # currencies
    @curr = split /:/, $form->{currencies};
    for (@curr) { $form->{selectcurrency} .= "<option>$_\n" }

    if ( @{ $form->{all_partsgroup} } ) {
        $form->{selectpartsgroup} = "";
        foreach $ref ( @{ $form->{all_partsgroup} } ) {
            $form->{selectpartsgroup} .= qq|$ref->{partsgroup}--$ref->{id}\n|;
        }
    }

    for (qw(currencies all_partsgroup all_partspricelist)) {
        delete $form->{$_};
    }

    foreach $i ( 1 .. $form->{rowcount} ) {

        if ( $form->{db} eq 'customer' ) {

            $form->{"pricebreak_$i"} =
              $form->format_amount( \%myconfig, $form->{"pricebreak_$i"} );

            $form->{"sellprice_$i"} =
              $form->format_amount( \%myconfig, $form->{"sellprice_$i"}, 2 );

        }

        if ( $form->{db} eq 'vendor' ) {

            $form->{"leadtime_$i"} =
              $form->format_amount( \%myconfig, $form->{"leadtime_$i"} );

            $form->{"lastcost_$i"} =
              $form->format_amount( \%myconfig, $form->{"lastcost_$i"}, 2 );

        }
    }

    $form->{rowcount}++;
    &{"$form->{db}_pricelist"};

}

sub customer_pricelist {

    @flds =
      qw(runningnumber id partnumber description sellprice unit partsgroup pricebreak curr validfrom validto);

    $form->{rowcount}--;

    # remove empty rows
    if ( $form->{rowcount} ) {

        foreach $i ( 1 .. $form->{rowcount} ) {

            for (qw(pricebreak sellprice)) {
                $form->{"${_}_$i"} =
                  $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
            }

            ( $a, $b ) = split /\./, $form->{"pricebreak_$i"};
            $a     = length $a;
            $b     = length $b;
            $whole = ( $whole > $a ) ? $whole : $a;
            $dec   = ( $dec > $b ) ? $dec : $b;
        }
        $pad1 = '0' x $whole;
        $pad2 = '0' x $dec;

        foreach $i ( 1 .. $form->{rowcount} ) {
            ( $a, $b ) = split /\./, $form->{"pricebreak_$i"};

            $a = substr( "$pad1$a", -$whole );
            $b = substr( "$b$pad2", 0, $dec );
            $ndx{qq|$form->{"partnumber_$i"}_$form->{"id_$i"}_$a$b|} = $i;
        }

        $i = 1;
        for ( sort keys %ndx ) { $form->{"runningnumber_$ndx{$_}"} = $i++ }

        foreach $i ( 1 .. $form->{rowcount} ) {
            if ( $form->{"partnumber_$i"} && $form->{"sellprice_$i"} ) {
                if ( $form->{"id_$i"} eq $sameid ) {
                    $j = $i + 1;
                    next
                      if ( $form->{"id_$j"} eq $sameid
                        && !$form->{"pricebreak_$i"} );
                }

                push @a, {};
                $j = $#a;

                for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
                $count++;
            }
            $sameid = $form->{"id_$i"};
        }

        $form->redo_rows( \@flds, \@a, $count, $form->{rowcount} );
        $form->{rowcount} = $count;

    }

    $form->{rowcount}++;

    if ( $form->{display_form} ) {
        &{"$form->{display_form}"};
    }

}

sub vendor_pricelist {

    @flds =
      qw(runningnumber id sku partnumber description lastcost unit partsgroup curr leadtime);

    $form->{rowcount}--;

    # remove empty rows
    if ( $form->{rowcount} ) {

        foreach $i ( 1 .. $form->{rowcount} ) {

            for (qw(leadtime lastcost)) {
                $form->{"${_}_$i"} =
                  $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
            }
            $var =
              ( $form->{"partnumber_$i"} )
              ? $form->{"sku_$i"}
              : qq|_$form->{"sku_$i"}|;
            $ndx{$var} = $i;

        }

        $i = 1;
        for ( sort keys %ndx ) { $form->{"runningnumber_$ndx{$_}"} = $i++ }

        foreach $i ( 1 .. $form->{rowcount} ) {
            if ( $form->{"sku_$i"} ) {
                push @a, {};
                $j = $#a;

                for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
                $count++;
            }
        }

        $form->redo_rows( \@flds, \@a, $count, $form->{rowcount} );
        $form->{rowcount} = $count;

    }

    $form->{rowcount}++;

    if ( $form->{display_form} ) {
        &{"$form->{display_form}"};
    }

}

sub display_pricelist {

    &pricelist_header;
    delete $form->{action};
    $form->hide_form;
    &pricelist_footer;

}

sub pricelist_header {

    $form->{title} = $form->{name};

    $form->header;

    print qq|
<body>

<form method=post action="$form->{script}">

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
|;

    if ( $form->{db} eq 'customer' ) {
        @column_index = qw(partnumber description);
        push @column_index, "partsgroup" if $form->{selectpartsgroup};
        push @column_index, qw(pricebreak sellprice curr validfrom validto);

        $column_header{pricebreak} =
            qq|<th class=listheading nowrap>|
          . $locale->text('Break')
          . qq|</th>|;
        $column_header{sellprice} =
            qq|<th class=listheading nowrap>|
          . $locale->text('Sell Price')
          . qq|</th>|;
        $column_header{validfrom} =
          qq|<th class=listheading nowrap>| . $locale->text('From') . qq|</th>|;
        $column_header{validto} =
          qq|<th class=listheading nowrap>| . $locale->text('To') . qq|</th>|;
    }

    if ( $form->{db} eq 'vendor' ) {
        @column_index = qw(sku partnumber description);
        push @column_index, "partsgroup" if $form->{selectpartsgroup};
        push @column_index, qw(lastcost curr leadtime);

        $column_header{sku} =
          qq|<th class=listheading nowrap>| . $locale->text('SKU') . qq|</th>|;
        $column_header{leadtime} =
            qq|<th class=listheading nowrap>|
          . $locale->text('Leadtime')
          . qq|</th>|;
        $column_header{lastcost} =
          qq|<th class=listheading nowrap>| . $locale->text('Cost') . qq|</th>|;
    }

    $column_header{partnumber} =
      qq|<th class=listheading nowrap>| . $locale->text('Number') . qq|</th>|;
    $column_header{description} =
        qq|<th class=listheading nowrap width=80%>|
      . $locale->text('Description')
      . qq|</th>|;
    $column_header{partsgroup} =
      qq|<th class=listheading nowrap>| . $locale->text('Group') . qq|</th>|;
    $column_header{curr} =
      qq|<th class=listheading nowrap>| . $locale->text('Curr') . qq|</th>|;

    print qq|
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

    for (@column_index) { print "\n$column_header{$_}" }

    print qq|
       </tr>
|;

    $sameid = "";
    foreach $i ( 1 .. $form->{rowcount} ) {

        $selectcurrency = $form->{selectcurrency};
        $selectcurrency =~
          s/option>\Q$form->{"curr_$i"}\E/option selected>$form->{"curr_$i"}/;

        if ( $form->{selectpartsgroup} ) {
            if ( $i < $form->{rowcount} ) {
                ($partsgroup) = split /--/, $form->{"partsgroup_$i"};
                $column_data{partsgroup} = qq|<td>$partsgroup</td>
	<input type=hidden name="partsgroup_$i" value="|
                  . $form->quote( $form->{"partsgroup_$i"} ) . qq|">|;
            }
        }

        if ( $i < $form->{rowcount} ) {

            if ( $form->{"id_$i"} eq $sameid ) {
                for (qw(partnumber description partsgroup)) {
                    $column_data{$_} = qq|<td>&nbsp;</td>
	<input type=hidden name="${_}_$i" value="|
                      . $form->quote( $form->{"${_}_$i"} ) . qq|">|;
                }
            }
            else {

                $column_data{sku} =
                  qq|<td><input name="sku_$i" value="$form->{"sku_$i"}"></td>|;
                $column_data{partnumber} =
qq|<td><input name="partnumber_$i" value="$form->{"partnumber_$i"}"></td>|;

                $column_data{description} =
                  qq|<td>$form->{"description_$i"}&nbsp;</td>
	<input type=hidden name="description_$i" value="|
                  . $form->quote( $form->{"description_$i"} ) . qq|">|;

            }

            $column_data{partnumber} .= qq|
        <input type=hidden name="id_$i" value="$form->{"id_$i"}">|;

        }
        else {

            if ( $form->{db} eq 'customer' ) {
                $column_data{partnumber} =
qq|<td><input name="partnumber_$i" value="$form->{"partnumber_$i"}"></td>|;
            }
            else {
                $column_data{partnumber} = qq|<td>&nbsp;</td>|;
            }

            $column_data{partnumber} .= qq|
        <input type=hidden name="id_$i" value="$form->{"id_$i"}">|;

            $column_data{sku} =
              qq|<td><input name="sku_$i" value="$form->{"sku_$i"}"></td>|;
            $column_data{description} =
qq|<td><input name="description_$i" value="$form->{"description_$i"}"></td>|;

            if ( $form->{selectpartsgroup} ) {
                $selectpartsgroup = "<option>";
                foreach $line ( split /\n/, $form->{selectpartsgroup} ) {
                    $selectpartsgroup .=
                        qq|\n<option value="|
                      . $form->quote($line) . qq|">|
                      . ( split /--/, $line )[0];
                }
                $column_data{partsgroup} =
qq|<td><select name="partsgroup_$i">$selectpartsgroup</select></td>|;
            }

        }

        if ( $form->{db} eq 'customer' ) {

            $column_data{pricebreak} =
                qq|<td align=right><input name="pricebreak_$i" size=5 value=|
              . $form->format_amount( \%myconfig, $form->{"pricebreak_$i"} )
              . qq|></td>|;
            $column_data{sellprice} =
                qq|<td align=right><input name="sellprice_$i" size=10 value=|
              . $form->format_amount( \%myconfig, $form->{"sellprice_$i"}, 2 )
              . qq|></td>|;

            $column_data{validfrom} =
qq|<td><input name="validfrom_$i" size=11 value=$form->{"validfrom_$i"}></td>|;
            $column_data{validto} =
qq|<td><input name="validto_$i" size=11 value=$form->{"validto_$i"}></td>|;
        }

        if ( $form->{db} eq 'vendor' ) {
            $column_data{leadtime} =
                qq|<td align=right><input name="leadtime_$i" size=5 value=|
              . $form->format_amount( \%myconfig, $form->{"leadtime_$i"} )
              . qq|></td>|;
            $column_data{lastcost} =
                qq|<td align=right><input name="lastcost_$i" size=10 value=|
              . $form->format_amount( \%myconfig, $form->{"lastcost_$i"}, 2 )
              . qq|></td>|;
        }

        $column_data{curr} =
          qq|<td><select name="curr_$i">$selectcurrency</select></td>|;

        print qq|<tr valign=top>|;

        for (@column_index) { print "\n$column_data{$_}" }

        print qq|</tr>|;

        $sameid = $form->{"id_$i"};

    }

    print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

    # delete variables
    foreach $i ( 1 .. $form->{rowcount} ) {
        for ( @column_index, "id" ) { delete $form->{"${_}_$i"} }
    }
    for (qw(title titlebar script none)) { delete $form->{$_} }

}

sub pricelist_footer {

    # type=submit $locale->text('Update')
    # type=submit $locale->text('Save Pricelist')

    %button = (
        'update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
        'save_pricelist' =>
          { ndx => 3, key => 'S', value => $locale->text('Save Pricelist') },
    );

    for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button ) {
        $form->print_button( \%button, $_ );
    }

    print qq|
</form>

</body>
</html>
|;

}

sub update {

    $i       = $form->{rowcount};
    $additem = 0;

    if ( $form->{db} eq 'customer' ) {
        $additem = 1
          if !(( $form->{"partnumber_$i"} eq "" )
            && ( $form->{"description_$i"} eq "" )
            && ( $form->{"partsgroup_$i"}  eq "" ) );
    }
    if ( $form->{db} eq 'vendor' ) {
        if (
            !(
                   ( $form->{"sku_$i"} eq "" )
                && ( $form->{"description_$i"} eq "" )
                && ( $form->{"partsgroup_$i"}  eq "" )
            )
          )
        {
            $additem = 1;
            $form->{"partnumber_$i"} = $form->{"sku_$i"};
        }
    }

    if ($additem) {

        CT->retrieve_item( \%myconfig, \%$form );

        $rows = scalar @{ $form->{item_list} };

        if ( $rows > 0 ) {

            if ( $rows > 1 ) {

                &select_item;
                exit;

            } else {

                $sellprice  = $form->{"sellprice_$i"};
                $pricebreak = $form->{"pricebreak_$i"};
                $lastcost   = $form->{"lastcost_$i"};

                for (qw(partnumber description)) {
                    $form->{item_list}[0]{$_} =
                      $form->quote( $form->{item_list}[0]{$_} );
                }
                for ( keys %{ $form->{item_list}[0] } ) {
                    $form->{"${_}_$i"} = $form->{item_list}[0]{$_};
                }

                if ( $form->{db} eq 'customer' ) {

                    if ($sellprice) {
                        $form->{"sellprice_$i"} = $sellprice;
                    }

                    $form->{"sellprice_$i"} =
                      $form->format_amount( \%myconfig, $form->{"sellprice_$i"},
                        2 );

                    $form->{"pricebreak_$i"} = $pricebreak;

                }
                else {

                    foreach $j ( 1 .. $form->{rowcount} - 1 ) {
                        if ( $form->{"sku_$j"} eq $form->{"partnumber_$i"} ) {
                            $form->error(
                                $locale->text('Item already on pricelist!') );
                        }
                    }

                    if ($lastcost) {
                        $form->{"lastcost_$i"} = $lastcost;
                    }

                    $form->{"lastcost_$i"} =
                      $form->format_amount( \%myconfig, $form->{"lastcost_$i"},
                        2 );

                    $form->{"sku_$i"} = $form->{"partnumber_$i"};

                    #	  delete $form->{"partnumber_$i"};

                }

                $form->{rowcount}++;

            }

        }
        else {

            $form->error( $locale->text('Item not on file!') );

        }
    }

    &{"$form->{db}_pricelist"};

}

sub select_item {
    my %hiddens;

    my @column_index =
      qw(ndx partnumber description partsgroup unit sellprice lastcost);

    my %column_data;
    $column_data{ndx} = ' ';
    $column_data{partnumber} = locale->text('Number');
    $column_data{description} = $locale->text('Description');
    $column_data{partsgroup} = $locale->text('Group');
    $column_data{unit} = $locale->text('Unit');
    $column_data{sellprice} = $locale->text('Sell Price');
    $column_data{lastcost} = $locale->text('Cost');

    $form->{title} = $locale->text('Select items');

    my $i = 0;
    my @rows;
    foreach $ref ( @{ $form->{item_list} } ) {
        $i++;
        my %column_data;

        for (qw(partnumber description unit)) {
            $ref->{$_} = $form->quote( $ref->{$_} );
        }

        $column_data{ndx} = {input => {
            name => "ndx_$i",
            type => 'checkbox',
            value => $i,
            }};

        $column_data{$_} = $ref->{$_} foreach
            qw(partnumber description partsgroup unit);
        $column_data{sellprice} =
            $form->format_amount( \%myconfig, $ref->{sellprice}, 2, ' ' );
        $column_data{lastcost} =
            $form->format_amount( \%myconfig, $ref->{lastcost}, 2, ' ' );

        $j++;
        $j %= 2;
        $column_data{i} = $j;

        push @rows, \%column_data;

        $hiddens{"new_${_}_$i"} = $ref->{$_} foreach 
            qw(partnumber description partsgroup partsgroup_id sellprice lastcost unit id);
    }

    # delete action variable
    for (qw(nextsub item_list)) { delete $form->{$_} }
    $form->{action} = "item_selected";

    $hiddens{$_} = $form->{$_} foreach sort keys %$form;
    $hiddens{nextsub} = 'item_selected';
    $hiddens{lastndx} = $i;

    my @buttons = ({
        name => 'action',
        value => 'item_selected',
        text => $locale->text('Continue'),
        });
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'form-dynatable',
        );
    $template->render({
        form => $form,
        user => \%myconfig, 
        hiddens => \%hiddens,
        buttons => \@buttons,
        options => \@options,
        rows => \@rows,
        columns => \@column_index,
        heading => \%column_header,
    });
}

sub item_selected {

    # add rows
    $i = $form->{rowcount};

    %id = ();
    for $i ( 1 .. $form->{rowcount} - 1 ) {
        $id{ $form->{"id_$i"} } = 1;
    }

    for $j ( 1 .. $form->{lastndx} ) {

        if ( $form->{"ndx_$j"} ) {

            if ( $id{ $form->{"new_id_$j"} } ) {
                next if $form->{db} eq 'vendor';
            }

            for (qw(id partnumber description unit sellprice lastcost)) {
                $form->{"${_}_$i"} = $form->{"new_${_}_$j"};
            }

            $form->{"partsgroup_$i"} =
              qq|$form->{"new_partsgroup_$j"}--$form->{"new_partsgroup_id_$j"}|;
            $form->{"sku_$i"} = $form->{"new_partnumber_$j"};

            $i++;

        }
    }

    $form->{rowcount} = $i;

    # delete all the new_ variables
    for $i ( 1 .. $form->{lastndx} ) {
        for (
            qw(id partnumber description unit sellprice lastcost partsgroup partsgroup_id)
          )
        {
            delete $form->{"new_${_}_$i"};
        }
        delete $form->{"ndx_$i"};
    }

    for (qw(ndx lastndx nextsub)) { delete $form->{$_} }

    &{"$form->{db}_pricelist"};

}

sub save_pricelist {

    &{"CT::save_$form->{db}"}( "", \%myconfig, \%$form );

    $callback = $form->{callback};
    $form->{callback} = "$form->{script}?action=edit";
    for (qw(db id login path sessionid)) {
        $form->{callback} .= "&$_=$form->{$_}";
    }
    $form->{callback} .= "&callback=" . $form->escape( $callback, 1 );

    if ( CT->save_pricelist( \%myconfig, \%$form ) ) {
        $form->redirect;
    }
    else {
        $form->error( $locale->text('Could not save pricelist!') );
    }

}

sub add_transaction {

    $form->isblank( "name", $locale->text("Name missing!") );

    &{"CT::save_$form->{db}"}( "", \%myconfig, \%$form );

    $form->{callback} = $form->escape( $form->{callback}, 1 );
    $name = $form->escape( $form->{name}, 1 );

    $form->{callback} =
"$form->{script}?login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}&action=add&vc=$form->{db}&$form->{db}_id=$form->{id}&$form->{db}=$name&type=$form->{type}&callback=$form->{callback}";

    $form->redirect;

}

sub ap_transaction {

    $form->{script} = "ap.pl";
    $form->{type}   = "ap_transaction";
    &add_transaction;

}

sub ar_transaction {

    $form->{script} = "ar.pl";
    $form->{type}   = "ar_transaction";
    &add_transaction;

}

sub sales_invoice {

    $form->{script} = "is.pl";
    $form->{type}   = "invoice";
    &add_transaction;

}

sub pos {

    $form->{script} = "ps.pl";
    $form->{type}   = "pos_invoice";
    &add_transaction;

}

sub vendor_invoice {

    $form->{script} = "ir.pl";
    $form->{type}   = "invoice";
    &add_transaction;

}

sub rfq {

    $form->{script} = "oe.pl";
    $form->{type}   = "request_quotation";
    &add_transaction;

}

sub quotation {

    $form->{script} = "oe.pl";
    $form->{type}   = "sales_quotation";
    &add_transaction;

}

sub sales_order {

    $form->{script} = "oe.pl";
    $form->{type}   = "sales_order";
    &add_transaction;

}

sub purchase_order {

    $form->{script} = "oe.pl";
    $form->{type}   = "purchase_order";
    &add_transaction;

}

sub save_as_new {

    delete $form->{id};
    &save;

}

sub save {

    # $locale->text('Customer saved!')
    # $locale->text('Vendor saved!')

    $msg = ucfirst $form->{db};
    $msg .= " saved!";

    $form->isblank( "name", $locale->text("Name missing!") );
    &{"CT::save_$form->{db}"}( "", \%myconfig, \%$form );

    $form->redirect( $locale->text($msg) );

}

sub delete {

    # $locale->text('Customer deleted!')
    # $locale->text('Cannot delete customer!')
    # $locale->text('Vendor deleted!')
    # $locale->text('Cannot delete vendor!')

    CT->delete( \%myconfig, \%$form );

    $msg = ucfirst $form->{db};
    $msg .= " deleted!";
    $form->redirect( $locale->text($msg) );

}

sub continue { &{ $form->{nextsub} } }

sub add_customer { &add }
sub add_vendor   { &add }

