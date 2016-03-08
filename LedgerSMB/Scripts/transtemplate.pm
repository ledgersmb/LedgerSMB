=head1 NAME

LedgerSMB::Scripts::transtemplate - Transaction Template Workflows for LedgerSMB

=head1 SYNPOSIS

 LedgerSMB::Scripts::transtemplate::view($request);

=cut 

package LedgerSMB::Scripts::transtemplate;
use LedgerSMB::DBObject::TransTemplate;
use LedgerSMB::Report::Listings::TemplateTrans;
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
        ap         => {script => 'bin/ap.pl', function => sub {$lsmb_legacy::form->{title} = 'Add'; lsmb_legacy::update()}},
        ar         => {script => 'bin/ar.pl', function => sub {$lsmb_legacy::form->{title} = 'Add'; lsmb_legacy::update()}},
        gl         => {script => 'bin/gl.pl', function => sub {$lsmb_legacy::form->{title} = 'Add'; lsmb_legacy::update()}},
    };
  
    our $form = new Form;
    $form->open_form();
    $lsmb_legacy::form = $form;
    $lsmb_legacy::locale = LedgerSMB::App_State::Locale();
    $form->{dbh} = $request->{dbh};
    our $locale = $request->{_locale};
    our %myconfig = ();
    %myconfig = %{$request->{_user}};
    $form->{stylesheet} = $myconfig{stylesheet};
    $locale = $request->{_locale};
    my $transtemplate = LedgerSMB::DBObject::TransTemplate->new(base => $request);
    $transtemplate->get;
    my $script = $template_dispatch->{$request->{entry_type}}->{script};
    die "No dispatch entry for type $request->{entry_type}" unless $script;
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
    $form->{session_id} = $trans->{session_id};
    if ($type eq 'gl'){
        $form->{reference} = $trans->{reference};
        $form->{description} = $trans->{description};
        $form->{rowcount} = 0;
        if (!$form->{reference}){
             $form->{reference} = $form->update_defaults(\%myconfig,'glnumber');
        }
        for $row (@{$trans->{line_items}}){
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
        $form->{reverse} = 0;
        if ($type eq 'ar'){
            $form->{customer} = $meta_number;
        } else {
            $form->{vendor} = $meta_number; 
        }
        $form->{rowcount} = 1;
        for $row (@{$trans->{line_items}}){
            $form->{"amount_$form->{rowcount}"} = $row->{amount};
        }
    }
    delete $form->{id};
}

=item list

Lists all transaction templates

=cut

sub list {
    my ($request) = @_;
    LedgerSMB::Report::Listings::TemplateTrans->new(%$request)->render($request);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
