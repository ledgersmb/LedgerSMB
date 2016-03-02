=head1 NAME

LedgerSMB::Scripts::transtemplate - Transaction Template Workflows for LedgerSMB

=head1 SYNPOSIS

 LedgerSMB::Scripts::transtemplate::view($request);

=cut

package LedgerSMB::Scripts::transtemplate;

use strict;
use warnings;

use LedgerSMB::DBObject::TransTemplate;
use LedgerSMB::Template;

our $VERSION = '0.1';

=head1 ROUTINES

=over

=item view

Views the transaction template.  Requires that id be set.

=cut

sub view {
    my $request = shift @_;
    use LedgerSMB::Form;
    our $template_dispatch =
    {
        ap         => {script => 'bin/ap.pl', function => sub {update()}},
        ar         => {script => 'bin/ar.pl', function => sub {update()}},
        gl         => {script => 'bin/gl.pl', function => sub {update()}},
    };

    our $form = new Form;
    $form->{dbh} = $request->{dbh};
    our $locale = $request->{_locale};
    our %myconfig = ();
    %myconfig = %{$request->{_user}};
    $form->{stylesheet} = $myconfig{stylesheet};
    $locale = $request->{_locale};
    my $transtemplate = LedgerSMB::DBObject::TransTemplate->new({base => $request});
    $transtemplate->get;
    my $script = $template_dispatch->{$request->{entry_type}}->{script};
    $form->{script} = $script;
    $form->{script} =~ s/(bin|scripts)\///;
    delete $form->{id};
    if ($script =~ /^bin/){
    # I hate this old code!
        {
             no strict;
             no warnings 'redefine';
             convert_to_form($transtemplate, $form, $request->{entry_type});
             do $script;
        }

    } elsif ($script =~ /scripts/) {
         { do $script }

    }

    $template_dispatch->{$request->{entry_type}}->{function}($form);

}

=item convert_to_form

largely private function designed to convert the request object to a Form
object for old code.

=cut

sub convert_to_form{
    my ($trans, $form, $type) = @_;
    my %myconfig;
    if ($type eq 'gl'){
        $form->{reference} = $trans->{reference};
        $form->{description} = $trans->{description};
        $form->{rowcount} = 0;
        if (!$form->{reference}){
             $form->{reference} = $form->update_defaults(\%myconfig,'glnumber');
        }
        for my $row (@{$trans->{line_items}}){
            if ($row->{amount} < 0){
                $form->{"debit_$form->{rowcount}"} = $row->{amount} * -1;
            } else {
                $form->{"credit_$form->{rowcount}"} = $row->{amount};
            }
            my $act = $trans->get_account_info($row->{account_id});
            $form->{"accno_$form->{rowcount}"} =
                       "$act->{accno}--$act->{description}";
            ++$form->{rowcount};
        }
    } else { #ar or ap
        my $meta_number = $trans->{credit_data}->{meta_number};
        if ($type eq 'ar'){
            $form->{customer} = $meta_number;
        } else {
            $form->{vendor} = $meta_number;
        }
        $form->{rowcount} = 1;
        for my $row (@{$trans->{line_items}}){
            $form->{"amount_$form->{rowcount}"} = $row->{amount};
        }
    }
}

=item search

Displays transaction template filter

=cut

sub search {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/transtemplate',
        template => 'filter',
        format   => 'HTML',
   );
   $template->render($request);
}

=item display_results

Displays a list of template transactions

=cut

sub display_results {
    my ($request) = @_;
    my $transtemplate = LedgerSMB::DBObject::TransTemplate->new({base => $request});
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI',
        template => 'form-dynatable',
        format   => 'HTML',
   );
   my @cols = qw(id entry_type reference description meta_number entity_name entity_class);
   my $column_headers = {
      id          => 'ID',
      reference   => 'Reference',
      description => 'Description',
      meta_number => 'Account Number',
      entity_name => 'Name',
      entity_class       => 'Type of Account',
   };
   my $rows = [];
   my $base_url = $request->{script} . "?action=view";
   $transtemplate->search;
   for my $line (@{$transtemplate->{search_results}}){
       if (!$line->{reference}){
           $line->{reference} = '[none]';
       }
       if (lc($line->{entity_class}) eq 'vendor'){
           $line->{entry_type} = 'ap';
       }
       elsif (lc($line->{entity_class}) eq 'customer'){
           $line->{entry_type} = 'ar';
       }
       else {
           $line->{entry_type} = 'gl';
       }
       $line->{reference} = {
            text => $line->{reference},
	    href => "$base_url&entry_type=$line->{entry_type}&id=$line->{id}",
       };
       push @$rows, $line;
   }
   $template->render({
      columns => \@cols,
      heading => $column_headers,
      title   => $request->{_locale}->text('Memorized Transaction List'),
      rows    => $rows,
      form    => $request,
   });
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
