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
# Copyright (c) 2003
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
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
# Batch printing
#
#======================================================================

use LedgerSMB::BP;
use LedgerSMB::Template;

1;

# end of main

sub search {

    # $locale->text('Sales Invoices')
    # $locale->text('Packing Lists')
    # $locale->text('Pick Lists')
    # $locale->text('Sales Orders')
    # $locale->text('Work Orders')
    # $locale->text('Purchase Orders')
    # $locale->text('Bin Lists')
    # $locale->text('Quotations')
    # $locale->text('RFQs')
    # $locale->text('Time Cards')
    my %hiddens;

    # setup customer/vendor selection
    BP->get_vc( \%myconfig, \%$form );

    my %name;
    if ( ref $form->{"all_$form->{vc}"} eq 'ARRAY' ) {
        $name{type} = 'select';
        $name{data} = {name => $form->{vc}, options => [{text => '', value => ''}]};
        for ( @{ $form->{"all_$form->{vc}"} } ) {
            push @{$name{data}{options}}, {
                text => $_->{name},
                value => "$_->{name}--$_->{id}"
                };
        }
    } else {
        $name{type} = 'input';
        $name{data} = {name => $form->{vc}, size => 35};
    }

    # $locale->text('Customer')
    # $locale->text('Vendor')
    # $locale->text('Employee')

    my %label = (
        invoice           => { title => 'Sales Invoices',  name => 'Customer' },
        packing_list      => { title => 'Packing Lists',   name => 'Customer' },
        pick_list         => { title => 'Pick Lists',      name => 'Customer' },
        sales_order       => { title => 'Sales Orders',    name => 'Customer' },
        work_order        => { title => 'Work Orders',     name => 'Customer' },
        purchase_order    => { title => 'Purchase Orders', name => 'Vendor' },
        bin_list          => { title => 'Bin Lists',       name => 'Vendor' },
        sales_quotation   => { title => 'Quotations',      name => 'Customer' },
        request_quotation => { title => 'RFQs',            name => 'Vendor' },
        timecard          => { title => 'Time Cards',      name => 'Employee' },
        check             => { title => 'Check',           name => 'Vendor' },
    );

    $label{invoice}{invnumber} = {
        label => $locale->text('Invoice Number'),
        name => 'invnumber',
        };
    $label{invoice}{ordnumber} = {
        label => $locale->text('Order Number'),
        name => 'ordnumber',
        };
    $label{sales_quotation}{quonumber} = {
        label => $locale->text('Quotation Number'),
        name => 'quonumber',
        };

    $label{packing_list}{invnumber}      = $label{invoice}{invnumber};
    $label{packing_list}{ordnumber}      = $label{invoice}{ordnumber};
    $label{pick_list}{invnumber}         = $label{invoice}{invnumber};
    $label{pick_list}{ordnumber}         = $label{invoice}{ordnumber};
    $label{sales_order}{ordnumber}       = $label{invoice}{ordnumber};
    $label{work_order}{ordnumber}        = $label{invoice}{ordnumber};
    $label{purchase_order}{ordnumber}    = $label{invoice}{ordnumber};
    $label{bin_list}{ordnumber}          = $label{invoice}{ordnumber};
    $label{request_quotation}{quonumber} = $label{sales_quotation}{quonumber};

    # do one call to text
    $form->{title} = $locale->text("Print $label{$form->{type}}{title}");

    # accounting years
    if ( @{ $form->{all_years} } ) {

        # accounting years
        $form->{selectaccountingyear} = {
            name => 'year',
            options => [{text => '', value => ''}]
            };
        for ( @{ $form->{all_years} } ) {
            push @{$form->{selectaccountingyear}{options}}, {
                text => $_,
                value => $_
                };
        }
        $form->{selectaccountingmonth} = {
            name => 'month',
            options => [{text => '', value => ''}]
            };
        for ( sort keys %{ $form->{all_month} } ) {
            push @{$form->{selectaccountingmonth}{options}}, {
                text => $locale->text($form->{all_month}{$_}),
                value => $_
                };
        }
    }

    $hiddens{vc} = $form->{vc};
    $hiddens{type} = $form->{type};
    $hiddens{title} = $form->{title};
    $hiddens{sort} = 'transdate';
    $hiddens{nextsub} = 'list_spool';
    $hiddens{path} = $form->{path};
    $hiddens{login} = $form->{login};
    $hiddens{sessionid} = $form->{sessionid};

    my @buttons = ({
        name => 'action',
        value => 'list_spool',
        text => $locale->text('Continue'),
    });
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'bp-search',
        );
    $template->render({
        form => $form,
        user => \%myconfig,
        label => \%label,
        name => \%name,
        hiddens => \%hiddens,
        buttons => \@buttons,
    });
}

sub remove {

    my $selected = 0;
    my %hiddens;

    for $i ( 1 .. $form->{rowcount} ) {
        if ( $form->{"checked_$i"} ) {
            $selected = 1;
            last;
        }
    }

    $form->error( $locale->text('Nothing selected!') ) unless $selected;

    $form->{title} = $locale->text('Confirm!');

    for (qw(action header)) { delete $form->{$_} }
    foreach my $key ( keys %$form ) {
        $hiddens{$key} = $form->{$key};
    }

    my $query = $locale->text(
        'Are you sure you want to remove the marked entries from the queue?');

    my @buttons = ({
        name => 'action',
        value => 'remove_from_queue',
        text => $locale->text('Yes'),
    });
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'form-confirmation',
        );
    $template->render({
        form => $form,
        query => $query,
        hiddens => \%hiddens,
        buttons => \@buttons,
    });

}

sub remove_from_queue {

    $form->info( $locale->text('Removing marked entries from queue ...') );
    $form->{callback} .= "&header=1" if $form->{callback};

    if ( BP->delete_spool( \%myconfig, \%$form, ${LedgerSMB::Sysconfig::spool} )
      )
    {
        $form->redirect( $locale->text('Removed spoolfiles!') );
    }
    else {
        $form->error( $locale->text('Cannot remove files!') );
    }

}

sub print {

    if ( $form->{callback} ) {
        for ( 1 .. $form->{rowcount} ) {
            $form->{callback} .= "&checked_$_=1" if $form->{"checked_$_"};
        }
        $form->{callback} .= "&header=1";
    }

    for $i ( 1 .. $form->{rowcount} ) {
        if ( $form->{"checked_$i"} ) {
            ##SC: XXX adjust later once printing hooked up to templates
            $form->{OUT} = "${LedgerSMB::Sysconfig::printer}{$form->{media}}";
            $form->{printmode} = '|-';
            $form->info( $locale->text('Printing') . " ..." );

            if (
                BP->print_spool(
                    \%myconfig, \%$form, ${LedgerSMB::Sysconfig::spool}
                )
              )
            {
                print $locale->text('done');
                $form->redirect( $locale->text('Marked entries printed!') );
            }
            $form->finalize_request();
        }
    }

    $form->error('Nothing selected!');

}

sub list_spool {

    my %hiddens;
    my @buttons;

    $form->{ $form->{vc} } = $form->unescape( $form->{ $form->{vc} } );
    ( $form->{ $form->{vc} }, $form->{"$form->{vc}_id"} ) =
      split( /--/, $form->{ $form->{vc} } );

    BP->get_spoolfiles( \%myconfig, \%$form );

    my $title = $form->escape( $form->{title} );
    my $href =
"$form->{script}?action=list_spool&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&vc=$form->{vc}&type=$form->{type}&title=$title";

    $form->sort_order();

    $title = $form->escape( $form->{title}, 1 );
    my $callback =
"$form->{script}?action=list_spool&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&vc=$form->{vc}&type=$form->{type}&title=$title";

    my @options;
    if ( $form->{ $form->{vc} } ) {
        $callback .=
          "&$form->{vc}=" . $form->escape( $form->{ $form->{vc} }, 1 );
        $href .= "&$form->{vc}=" . $form->escape( $form->{ $form->{vc} } );
        push @options, 
          ( $form->{vc} eq 'customer' )
          ? $locale->text('Customer: [_1]', $form->{$form->{vc}})
          : $locale->text('Vendor: [_1]', $form->{$form->{vc}});
    }
    if ( $form->{account} ) {
        $callback .= "&account=" . $form->escape( $form->{account}, 1 );
        $href   .= "&account=" . $form->escape( $form->{account} );
        push @options, $locale->text('Account: [_1]', $form->{account});
    }
    if ( $form->{invnumber} ) {
        $callback .= "&invnumber=" . $form->escape( $form->{invnumber}, 1 );
        $href   .= "&invnumber=" . $form->escape( $form->{invnumber} );
        push @options, $locale->text('Invoice Number: [_1]', $form->{invnumber});
    }
    if ( $form->{ordnumber} ) {
        $callback .= "&ordnumber=" . $form->escape( $form->{ordnumber}, 1 );
        $href   .= "&ordnumber=" . $form->escape( $form->{ordnumber} );
        push @options, $locale->text('Order Number: [_1]', $form->{ordnumber});
    }
    if ( $form->{quonumber} ) {
        $callback .= "&quonumber=" . $form->escape( $form->{quonumber}, 1 );
        $href   .= "&quonumber=" . $form->escape( $form->{quonumber} );
        push @options, $locale->text('Quotation Number: [_1]', $form->{quonumber});
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
        push @options, $locale->text('To [_1]',
            $locale->date( \%myconfig, $form->{transdateto}, 1 ));
    }

    my $name = ucfirst $form->{vc};

    my @columns = qw(transdate);
    if ( $form->{type} =~ /(invoice)/ ) {
        push @columns, "invnumber";
    }
    if ( $form->{type} =~ /(packing|pick)_list/ ) {
        push @columns, "invnumber";
    }
    if ( $form->{type} =~ /_(order|list)$/ ) {
        push @columns, "ordnumber";
    }
    if ( $form->{type} =~ /_quotation$/ ) {
        push @columns, "quonumber";
    }
    if ( $form->{type} eq 'timecard' ) {
        push @columns, "id";
    }

    push @columns, ( name, spoolfile );
    my @column_index = $form->sort_columns(@columns);
    unshift @column_index, "checked";

    my %column_header;
    $column_header{checked} = ' ';
    $column_header{transdate} = {
        href => "$href&sort=transdate",
        text => $locale->text('Date'),
        };
    $column_header{invnumber} = {
        href => "$href&sort=invnumber",
        text => $locale->text('Invoice'),
        };
    $column_header{ordnumber} = {
        href => "$href&sort=ordnumber",
        text => $locale->text('Order'),
        };
    $column_header{quonumber} = {
        href => "$href&sort=quonumber",
        text => $locale->text('Quotation'),
        };
    $column_header{name} = {
        href => "$href&sort=name",
        text => $locale->text($name),
        };
    $column_header{id} = {
        href => "$href&sort=id",
        text => $locale->text('ID'),
        };
    $column_header{spoolfile} = $locale->text('Spoolfile');

    # add sort and escape callback, this one we use for the add sub
    $form->{callback} = $callback .= "&sort=$form->{sort}";

    # escape callback for href
    $callback = $form->escape($callback);

    my $i = 0;
    my @rows;

    foreach my $ref ( @{ $form->{SPOOL} } ) {

	my %column_data;
        $i++;

        $form->{"checked_$i"} = "checked" if $form->{"checked_$i"};

        # this is for audittrail
        $form->{module} = $ref->{module};

        if ( $ref->{invoice} ) {
            $ref->{module} = ( $ref->{module} eq 'ar' ) ? "is" : "ir";
        }
        $module = "$ref->{module}.pl";

        $column_data{transdate} = $ref->{transdate};

        if ( ${LedgerSMB::Sysconfig::spool} eq $ref->{spoolfile} ) {
            $column_data{checked} = '';
        }
        else {
            $column_data{checked} = {input => {
                name => "checked_$i",
                type => 'checkbox',
                $form->{"checked_$i"} => $form->{"checked_$i"},
                }};
        }

        for (qw(id invnumber ordnumber quonumber)) {
            $column_data{$_} = $ref->{$_};
        }

        if ( $ref->{module} eq 'oe' ) {
            $hiddens{"reference_$i"} = $ref->{ordnumber};
            $column_data{invnumber} = ' ';
            $column_data{ordnumber} = {
                href => "$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&type=$form->{type}&callback=$callback",
                text => $ref->{ordnumber},
                };

            $hiddens{"reference_$i"} = $ref->{quonumber} unless $ref->{ordnumber};
            $column_data{quonumber} = {
                href => "$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&type=$form->{type}&callback=$callback",
                text => $ref->{quonumber},
                };

        }
        elsif ( $ref->{module} eq 'jc' ) {
            $hiddens{"reference_$i"} = $ref->{id};
            $column_data{id} = {
                href => "$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&type=$form->{type}&callback=$callback",
                text => $ref->{id},
                };
        }
        else {
            $hiddens{"reference_$i"} = $ref->{invnumber};
            $column_data{invnumber} = {
                href => "$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&type=$form->{type}&callback=$callback",
                text => $ref->{invnumber},
                };
        }

        $column_data{name} = $ref->{name};
        $column_data{spoolfile} = {
            href => "${LedgerSMB::Sysconfig::spool}/$ref->{spoolfile}",
            text => $ref->{spoolfile},
            };

        ${LedgerSMB::Sysconfig::spool} = $ref->{spoolfile};

        $j++;
        $j %= 2;
        $column_data{i} = $j;

	$hiddens{"id_$i"} = $ref->{id};
	$hiddens{"spoolfile_$i"} = $ref->{spoolfile};
        push @rows, \%column_data;

    }

    $hiddens{rowcount} = $i;

    $hiddens{$_} = $form->{$_} foreach
        qw(callback title vc type sort module account path login sessionid);

    my @printers;
    if ( %{LedgerSMB::Sysconfig::printer} && ${LedgerSMB::Sysconfig::latex} ) {
        foreach my $key ( sort keys %{LedgerSMB::Sysconfig::printer} ) {
            push @printers, {
                type => 'radio',
                name => 'media',
                value => $key,
                label => $key,
                };
            $printers[$#printers]{checked} = 'checked' if $key eq $myconfig{printer};
        }

        # type=submit $locale->text('Select all')
        # type=submit $locale->text('Print')
        # type=submit $locale->text('Remove')

        %button = (
            'select_all' =>
              { ndx => 2, key => 'A', value => $locale->text('Select all') },
            'print' =>
              { ndx => 3, key => 'P', value => $locale->text('Print') },
            'remove' =>
              { ndx => 4, key => 'R', value => $locale->text('Remove') },
        );

        for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button )
        {
            push @buttons, {
                name => 'action',
                value => $_,
                accesskey => $button{$_}{key},
                title => "$button{$_}{value} [Alt-$button{$_}{key}]",
                text => $button{$_}{value},
                };
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
        template => 'bp-list-spool',
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
        printers => \@printers,
    });
}

sub select_all {

    for ( 1 .. $form->{rowcount} ) { $form->{"checked_$_"} = 1 }
    &list_spool;

}

sub continue { &{ $form->{nextsub} } }

