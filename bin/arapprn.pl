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

# any custom scripts for this one
if ( -f "bin/custom/arapprn.pl" ) {
    eval { require "bin/custom/arapprn.pl"; };
}
if ( -f "bin/custom/$form->{login}_arapprn.pl" ) {
    eval { require "bin/custom/$form->{login}_arapprn.pl"; };
}

1;

# end of main

sub print {

    my $csettings = $LedgerSMB::Company_Config::settings;
    $form->{company} = $csettings->{company_name};
    $form->{businessnumber} = $csettings->{businessnumber};
    $form->{email} = $csettings->{company_email};
    $form->{address} = $csettings->{company_address};
    $form->{tel} = $csettings->{company_phone};
    $form->{fax} = $csettings->{company_fax};

    if ( $form->{media} !~ /screen/ ) {
        $form->error( $locale->text('Select postscript or PDF!') )
          if $form->{format} !~ /(postscript|pdf)/;
        $old_form = new Form;
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
    $printform = new Form;
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
    foreach $i ( 1 .. $form->{rowcount} - 1 ) {
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
    foreach $accno ( split / /, $form->{taxaccounts} ) {
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
    for $i ( 1 .. $form->{paidaccounts} - 1 ) {

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

    for (qw(invtotal subtotal paid total)) {
        $form->{$_} = $form->format_amount( \%myconfig, $form->{$_}, 2 );
    }

    ( $form->{employee} ) = split /--/, $form->{employee};

    if ( exists $form->{longformat} ) {
        for (qw(duedate transdate crdate)) {
            $form->{$_} =
              $locale->date( \%myconfig, $form->{$_}, $form->{longformat} );
        }
    }

    $form->{notes} =~ s/^\s+//g;

    @a = ( "invnumber", "transdate", "duedate", "crdate", "notes" );

    push @a,
      qw(company address tel fax businessnumber text_amount text_decimal);

    $form->{invdate} = $form->{transdate};

    $form->{templates} = "$myconfig{templates}";
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
        $form->update_status( \%myconfig, 1);

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

            $form->update_status( \%myconfig, 1);
        }

        $old_form->{printed} = $form->{printed} if %$old_form;
    }

    $form->{fileid} = $form->{invnumber};
    $form->{fileid} =~ s/(\s|\W)+//g;

    my $template = LedgerSMB::Template->new(
        user => \%myconfig, template => $form->{'formname'},
        locale => $locale,
    no_auto_output => 1,
        format => uc $form->{format} );

    $template->render($form);
    $template->output(%{$form});

    if (%$old_form) {
        $old_form->{invnumber} = $form->{invnumber};
        $old_form->{invtotal}  = $form->{invtotal};

        for ( keys %$form ) { delete $form->{$_} }
        for ( keys %$old_form ) { $form->{$_} = $old_form->{$_} }

        if ( !$form->{printandpost} ) {
            for (qw(exchangerate creditlimit creditremaining)) {
                $form->{$_} = $form->parse_amount( \%myconfig, $form->{$_} );
            }

            for ( 1 .. $form->{rowcount} ) {
                $form->{"amount_$_"} =
                  $form->parse_amount( \%myconfig, $form->{"amount_$_"} );
            }
            for ( split / /, $form->{taxaccounts} ) {
                $form->{"tax_$_"} =
                  $form->parse_amount( \%myconfig, $form->{"tax_$_"} );
            }

            for $i ( 1 .. $form->{paidaccounts} ) {
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

sub select_payment {

    my %hiddens;
    my @column_index =
      ( "ndx", "datepaid", "source", "memo", "paid", "$form->{ARAP}_paid" );

    # list payments with radio button on a form
    $form->{title} = $locale->text('Select payment');

    my $column_names = {
        ndx => ' ',
        datepaid => 'Date',
        source => 'Source',
        memo => 'Memo',
        paid => 'Amount',
        "$form->{ARAP}_paid" => 'Account'
    };

    my $checked = "checked";
    my @rows;
    my $j;
    my $ok;
    foreach my $i ( 1 .. $form->{paidaccounts} - 1 ) {

        my %column_data;
        for (@column_index) {
            $column_data{$_} = $form->{"${_}_$i"};
        }
        $column_data{ndx} = {input => {
            name => 'ndx',
            type => 'radio',
            value => $i,
            }};
        $column_data{ndx}{input}{checked} = 'checked' if $checked;
        $column_data{paid} = $form->{"paid_$i"};

        $checked = "";
        $ok = 1;

        $j++;
        $j %= 2;
        $column_data{i} = $j;

        push @rows, \%column_data;
    }

    for (qw(action nextsub)) { delete $form->{$_} }
    $hiddens{$_} = $form->{$_} foreach keys %$form;
    $hiddens{nextsub} = 'payment_selected';

    my @buttons;
    if ($ok) {
        push @buttons, {
            name => 'action',
            value => 'payment_selected',
            text => $locale->text('Continue'),
            };
    }

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig,
        locale => $locale,
        template => 'form-dynatable',
        );

    my $column_heading = $template->column_heading($column_names);

    $template->render({
        form => $form,
        buttons => \@buttons,
        hiddens => \%hiddens,
        columns => \@column_index,
        heading => $column_heading,
        rows => \@rows,
        row_alignment => {'paid' => 'right'},
    });
}

sub payment_selected {

    &{"print_$form->{formname}"}( $form->{oldform}, $form->{ndx} );

}

sub print_options {

    if ( $form->{selectlanguage} ) {
        $form->{"selectlanguage"} =~ s/ selected//;
        $form->{"selectlanguage"} =~
          s/(<option value="\Q$form->{language_code}\E")/$1 selected/;
        $lang = qq|<select data-dojo-type="dijit/form/Select" name=language_code>$form->{selectlanguage}</select>|;
    }

    $type = qq|<select data-dojo-type="dijit/form/Select" name=formname>$form->{selectformname}</select>
  <input type=hidden name=selectformname value="|
      . $form->escape( $form->{selectformname}, 1 ) . qq|">|;

    $media = qq|<select data-dojo-type="dijit/form/Select" name=media>
          <option value="screen">| . $locale->text('Screen');

    $form->{selectformat} = qq|<option value="html">html<option value="csv">csv\n|;

    if ( %{LedgerSMB::Sysconfig::printer} && ${LedgerSMB::Sysconfig::latex} ) {
        for ( sort keys %{LedgerSMB::Sysconfig::printer} ) {
            $media .= qq|
          <option value="$_">$_|;
        }
    }

    if ( ${LedgerSMB::Sysconfig::latex} ) {
        $form->{selectformat} .= qq|
            <option value="postscript">| . $locale->text('Postscript') . qq|
        <option value="pdf">| . $locale->text('PDF');
    }

    $format = qq|<select data-dojo-type="dijit/form/Select" name=format>$form->{selectformat}</select>|;
    $format =~ s/(<option value="\Q$form->{format}\E")/$1 selected/;
    $media .= qq|</select>|;
    $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;

    print qq|
  <table width=100%>
    <tr>
      <td>$type</td>
      <td>$lang</td>
      <td>$format</td>
      <td>$media</td>
      <td align=right width=90%>
  |;

    if ( $form->{printed} =~ /$form->{formname}/ ) {
        print $locale->text('Printed') . qq|<br>|;
    }

    if ( $form->{recurring} ) {
        print $locale->text('Scheduled');
    }

    print qq|
      </td>
    </tr>
  </table>
|;

}

sub print_and_post {

    $form->error( $locale->text('Select postscript or PDF!') )
      if $form->{format} !~ /(postscript|pdf)/;
    $form->error( $locale->text('Select a Printer!') )
      if $form->{media} eq 'screen';

    $form->{printandpost} = 1;
    $form->{display_form} = "post";
    &print;

}

