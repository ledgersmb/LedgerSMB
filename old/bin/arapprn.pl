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
# This file has not undergone any whitespace cleanup.
#
# printing routines for ar, ap
#

package lsmb_legacy;
use Try::Tiny;
use LedgerSMB::Template;
use LedgerSMB::Company_Config;

require 'old/bin/aa.pl'; # for arapprn::reprint() and arapprn::print[_transaction]()
require 'old/bin/printer.pl';# centralizing print options display

# any custom scripts for this one
if ( -f "old/bin/custom/arapprn.pl" ) {
    eval { require "old/bin/custom/arapprn.pl"; };
}
if ( -f "old/bin/custom/$form->{login}_arapprn.pl" ) {
    eval { require "old/bin/custom/$form->{login}_arapprn.pl"; };
}

# end of main

sub print {

    &create_links;
    $form->{title} = $locale->text("Edit");
    if ($form->{reverse}){
        if ($form->{ARAP} eq 'AR'){
            $form->{subtype} = 'credit_note';
            $form->{type} = 'transaction';
        } elsif ($form->{ARAP} eq 'AP'){
            $form->{subtype} = 'debit_note';
            $form->{type} = 'transaction';
        } else {
            $form->error("Unknown AR/AP selection value: $form->{ARAP}");
        }

    }

    my $csettings = $LedgerSMB::Company_Config::settings;
    $form->{company} = $csettings->{company_name};
    $form->{businessnumber} = $csettings->{businessnumber};
    $form->{email} = $csettings->{company_email};
    $form->{address} = $csettings->{company_address};
    $form->{tel} = $csettings->{company_phone};
    $form->{fax} = $csettings->{company_fax};

    if ( $form->{media} !~ /screen/ ) {
        $form->error( $locale->text('Select postscript or PDF!')  )
          if $form->{format} !~ /(postscript|pdf)/;
        $old_form = Form->new;
        for ( keys %$form ) { $old_form->{$_} = $form->{$_} }
    }

    if ( !$form->{invnumber} ) {
        $invfld = 'sinumber';
        $invfld = 'vinumber' if $form->{ARAP} eq 'AP';
        $form->{invnumber} = $form->update_defaults( \%myconfig, $invfld );
        if ( $form->{media} eq 'screen' ) {
            if ( $form->{media} eq 'screen' ) {
                &update;
                $form->finalize_request();
            }
        }
    }

    if ( $filename = $queued{ $form->{formname} } ) {
        $form->{queued} =~ s/$form->{formname} $filename//;
        unlink "${LedgerSMB::Sysconfig::spool}/$filename";
        $filename =~ s/\..*$//g;
    }
    else {
        $filename = time;
        $filename .= $$;
    }

    $filename .= ( $form->{format} eq 'postscript' ) ? '.ps' : '.pdf';

    if ( $form->{media} ne 'screen' ) {
        $form->{OUT} = "${LedgerSMB::Sysconfig::spool}/$filename";
        $form{printmode} = '>';
    }

    $form->{queued} .= " $form->{formname} $filename";
    $form->{queued} =~ s/^ //;
    $printform = Form->new;
    for ( keys %$form ) {
        $printform->{$_} = $form->{$_};
    }

    if ( $form->{printandpost} ) {
        $form->{action} = 'post';
        delete $form->{printandpost};
        &post;
    }
    else {
        &{"print_$form->{formname}"}( $old_form, 1 );
    }

}


sub print_transaction {
    my ($old_form) = @_;

    $display_form =
      ( $form->{display_form} ) ? $form->{display_form} : "display_form";

    &{"$form->{vc}_details"};
    @a = qw(name address1 address2 city state zipcode country);

    $form->{invtotal} = 0;
    foreach my $i ( 1 .. $form->{rowcount} - 1 ) {
        ( $form->{tempaccno}, $form->{tempaccount} ) = split /--/,
          $form->{"$form->{ARAP}_amount_$i"};
        ( $form->{tempprojectnumber} ) = split /--/,
          $form->{"projectnumber_$i"};
        $form->{tempdescription} = $form->{"description_$i"};


        push( @{ $form->{accno} },         $form->{tempaccno} );
        push( @{ $form->{account} },       $form->{tempaccount} );
        push( @{ $form->{description} },   $form->{tempdescription} );
        push( @{ $form->{projectnumber} }, $form->{tempprojectnumber} );

        push( @{ $form->{amount} }, $form->{"amount_$i"} );

        $form->{subtotal} +=
          $form->parse_amount( \%myconfig, $form->{"amount_$i"} );

    }
    foreach my $accno ( split / /, $form->{taxaccounts} ) {
        if ( $form->{"tax_$accno"} ) {
            $form->format_string("${accno}_description");

            $tax += $form->parse_amount( \%myconfig, $form->{"tax_$accno"} );

            $form->{"${accno}_tax"} = $form->{"tax_$accno"};
            push( @{ $form->{tax} }, $form->{"tax_$accno"} );

            push(
                @{ $form->{taxdescription} },
                $form->{"${accno}_description"}
            );

            $form->{"${accno}_taxrate"} =
              $form->format_amount( \%myconfig, $form->{"${accno}_rate"} * 100 );
            push( @{ $form->{taxrate} }, $form->{"${accno}_taxrate"} );

            push( @{ $form->{taxnumber} }, $form->{"${accno}_taxnumber"} );
        }
    }

    $tax = 0 if $form->{taxincluded};

    push @a, $form->{ARAP};
    $form->format_string(@a);

    $form->{paid} = 0;
    foreach my $i ( 1 .. $form->{paidaccounts} - 1 ) {

        if ( $form->{"paid_$i"} ) {
            @a = ();
            $form->{paid} +=
              $form->parse_amount( \%myconfig, $form->{"paid_$i"} );

            if ( exists $form->{longformat} ) {
                $form->{"datepaid_$i"} =
                  $locale->date( \%myconfig, $form->{"datepaid_$i"},
                    $form->{longformat} );
            }

            push @a, "$form->{ARAP}_paid_$i", "source_$i", "memo_$i";
            $form->format_string(@a);

            ( $accno, $account ) = split /--/, $form->{"$form->{ARAP}_paid_$i"};

            push( @{ $form->{payment} },        $form->{"paid_$i"} );
            push( @{ $form->{paymentdate} },    $form->{"datepaid_$i"} );
            push( @{ $form->{paymentaccount} }, $account );
            push( @{ $form->{paymentsource} },  $form->{"source_$i"} );
            push( @{ $form->{paymentmemo} },    $form->{"memo_$i"} );
        }

    }

    $form->{invtotal} = $form->{subtotal} + $tax;
    $form->{total}    = $form->{invtotal} - $form->{paid};

    ( $whole, $form->{decimal} ) = split /\./, $form->{invtotal};

    $form->{decimal} .= "00";
    $form->{decimal}        = substr( $form->{decimal}, 0, 2 );
    $form->{integer_amount} = $form->format_amount( \%myconfig, $whole );

    foreach my $field (qw(invtotal subtotal paid total)) {
        $form->{$field} = $form->format_amount( \%myconfig, $form->{$field}, 2 );
    }

    ( $form->{employee} ) = split /--/, $form->{employee};

    if ( exists $form->{longformat} ) {
        foreach my $field (qw(duedate transdate crdate)) {
            $form->{$field} =
              $locale->date( \%myconfig, $form->{$field}, $form->{longformat} );
        }
    }

    $form->{notes} =~ s/^\s+//g;

    @a = ( "invnumber", "transdate", "duedate", "crdate", "notes" );

    push @a,
      qw(company address tel fax businessnumber text_amount text_decimal);

    $form->{invdate} = $form->{transdate};

    if ($form->{formname} eq 'transaction' ){
        $form->{IN} = lc $form->{ARAP} . "_$form->{formname}.html";
        $form->{formname} = lc $form->{ARAP} . "_$form->{formname}";
    } else {
        $form->{IN} ="$form->{formname}.html";
    }
    if ( $form->{format} =~ /(postscript|pdf)/ ) {
        $form->{IN} =~ s/html$/tex/;
    }
    if ( $form->{media} eq 'queue' ) {
        %queued = split / /, $form->{queued};

        if ( $filename = $queued{ $form->{formname} } ) {
            $form->{queued} =~ s/$form->{formname} $filename//;
            unlink "${LedgerSMB::Sysconfig::spool}/$filename";
            $filename =~ s/\..*$//g;
        }
        else {
            $filename = time;
            $filename .= $$;
        }

        $filename .= ( $form->{format} eq 'postscript' ) ? '.ps' : '.pdf';
        $form->{OUT}       = "${LedgerSMB::Sysconfig::spool}/$filename";
        $form->{printmode} = '>';

        $form->{queued} .= " $form->{formname} $filename";
        $form->{queued} =~ s/^ //;

        # save status
        $form->update_status;

        $old_form->{queued} = $form->{queued};
    }

    if ( lc($form->{media}) eq 'zip'){
        $form->{OUT}       = $form->{zipdir};
        $form->{printmode} = '>';
    } elsif ( $form->{media} !~ /(zip|screen)/ ) {
        $form->{OUT}       = ${LedgerSMB::Sysconfig::printer}{ $form->{media} };
        $form->{printmode} = '|-';

        if ( $form->{printed} !~ /$form->{formname}/ ) {

            $form->{printed} .= " $form->{formname}";
            $form->{printed} =~ s/^ //;

            $form->update_status;
        }

        $old_form->{printed} = $form->{printed} if %$old_form;
    }

    $form->{fileid} = $form->{invnumber};
    $form->{fileid} =~ s/(\s|\W)+//g;

    my %output_options = (
        filename => "$form->{formname}-$form->{invnumber}.$form->{format}"
        );
    my $template = LedgerSMB::Template->new(
        user => \%myconfig,
        template => $form->{'formname'},
        path => 'DB',
        locale => $locale,
        output_options => \%output_options,
        format => uc $form->{format} );
    $template->render($form);

    if (%$old_form) {
        $old_form->{invnumber} = $form->{invnumber};
        $old_form->{invtotal}  = $form->{invtotal};

        for ( keys %$form ) { delete $form->{$_} }
        for ( keys %$old_form ) { $form->{$_} = $old_form->{$_} }

        if ( !$form->{printandpost} ) {
            foreach my $field (qw(exchangerate creditlimit creditremaining)) {
                $form->{$field} = $form->parse_amount( \%myconfig, $form->{$field} );
            }

            foreach my $i ( 1 .. $form->{rowcount} ) {
                $form->{"amount_$i"} =
                  $form->parse_amount( \%myconfig, $form->{"amount_$i"} );
            }

            foreach my $account ( split / /, $form->{taxaccounts} ) {
                $form->{"tax_$account"} =
                  $form->parse_amount( \%myconfig, $form->{"tax_$account"} );
            }

            foreach my $i ( 1 .. $form->{paidaccounts} ) {
                for (qw(paid exchangerate)) {
                    $form->{"${_}_$i"} =
                      $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
                }
            }
        }
        return if 'zip' eq lc($form->{media});
        &{"$display_form"};

    }

}

sub vendor_details { IR->vendor_details( \%myconfig, \%$form ) }
sub customer_details { IS->customer_details( \%myconfig, \%$form ) }

sub print_and_post {

    $form->error( $locale->text('Select postscript or PDF!') )
      if $form->{format} !~ /(postscript|pdf)/;
    $form->error( $locale->text('Select a Printer!') )
      if $form->{media} eq 'screen';

    $form->{printandpost} = 1;
    $form->{display_form} = "post";
    &print;

}

1;
