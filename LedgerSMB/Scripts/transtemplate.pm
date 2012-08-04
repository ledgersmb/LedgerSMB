
package LedgerSMB::Scripts::transtemplate;
use LedgerSMB::DBObject::TransTemplate;
use LedgerSMB::Template;
our $VERSION = '0.1';

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
    our $locale = $request->{_locale};
    my $transtemplate = LedgerSMB::DBObject::TransTemplate->new(base => $request);
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

sub convert_to_form{
    my ($trans, $form, $type) = @_;
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
}
   
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

sub display_results {
    my ($request) = @_;
    my $transtemplate = LedgerSMB::DBObject::TransTemplate->new(base => $request);
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI',
        template => 'form-dynatable',
        format   => 'HTML', 
   );
   my @cols = qw(id entry_type source description meta_number entity_name entity_class);
   my $column_headers = {
      id          => 'ID',
      source      => 'Reference',
      description => 'Description',
      meta_number => 'Account Number',
      entity_name => 'Name',
      entity_class       => 'Type of Account',
   };
   my $rows = [];
   $base_url = $request->{script} . "?action=view";
    $transtemplate->search;
   for my $line (@{$transtemplate->{search_results}}){
       if (!$line->{source}){
           $line->{source} = '[none]';
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
       $line->{source} = {
            text => $line->{source}, 
	    href => "$base_url&entry_type=$line->{entry_type}&id=$line->{id}",
       };
       push @$rows, $line;
       print STDERR "row added \n";
   }
   $template->render({
      columns => \@cols,
      heading => $column_headers,
      title   => $request->{_locale}->text('Memorized Transaction List'),
      rows    => $rows,
      form    => $request,
   });
}
1;
