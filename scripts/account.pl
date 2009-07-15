use Template;
use LedgerSMB::DBObject::Account;
package LedgerSMB::Scripts::account;
use strict;

sub new {
    my ($request) = @_;
    $request->{title} = $request->{_locale}->text('Add Account');
    $request->{charttype} = 'A';
    _display_account_screen($request);     
}

sub edit {
    my ($request) = @_;
    $request->{chart_id} = $request->{id};
    my $account = LedgerSMB::DBObject::Account->new(base => $request);
    my @accounts = $account->get();
    my $a = shift @accounts;
    $a->debug({file => '/tmp/account'});
    $a->{title} = $request->{_locale}->text('Edit Account');
    _display_account_screen($a);
}

sub save {
    my ($request) = @_;
    my $account = LedgerSMB::DBObject::Account->new(base => $request);
    $account->save;
    edit($request); 
}

sub save_new {
    my ($request) = @_;
    delete $request->{id};
    save($request);
}

# copied from AM.pm.  To be refactored.
sub _display_account_screen {
    my ($form) = @_;
    my $locale = $form->{_locale};
    my $buttons = [];
    my $checked;
    my $hiddens;

    foreach my $item ( split( /:/, $form->{link} ) ) {
        $form->{$item} = "checked";
    }
 
    $hiddens->{type} = 'account';
    $hiddens->{$_} = $form->{$_} foreach qw(id inventory_accno_id income_accno_id expense_accno_id fxgain_accno_id fxloss_accno_id);
    $checked->{ $form->{charttype} } = "checked";

    for my $ct (qw(A E I Q L)){
        $checked->{"${ct}_"} = "checked" if $form->{category} eq $ct;
    } 

    for my $cb (qw(contra)){
        $checked->{$cb} = "checked" if $form->{$cb};
    }
    my %button = ();

    if ( $form->{id} ) {
        $button{'save'} =
          { ndx => 3, key => 'S', value => $locale->text('Save') };
        $button{'save_as_new'} =
          { ndx => 7, key => 'N', value => $locale->text('Save as new') };

        if ( $form->{orphaned} ) {
            $button{'delete'} =
              { ndx => 16, key => 'D', value => $locale->text('Delete') };
        }
    }
    else {
        $button{'save'} =
          { ndx => 3, key => 'S', value => $locale->text('Save') };
    }

    for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button ) {
        push @{$buttons}, {
            name => 'action',
            value => $_,
            accesskey => $button{$_}{key},
            title => "$button{$_}{value} [Alt-$button{$_}{key}]",
            text => $button{$_}{value},
            };
    }
    my $template = LedgerSMB::Template->new_UI(
        user => $form->{_user}, 
        locale => $locale,
        template => 'accounts/edit');
    $template->render({
        form => $form,
        checked => $checked,
        buttons => $buttons,
        hiddens => $hiddens,
    });

}

sub yearend_info {
    use LedgerSMB::DBObject::EOY;
    my ($request) = @_;
    my $eoy =  LedgerSMB::DBObject::EOY->new(base => $request);
    $eoy->list_earnings_accounts;
    $eoy->{user} = $request->{_user};    
    my $template = LedgerSMB::Template->new_UI(
        user => $request->{_user}, 
        locale => $request->{_locale},
        template => 'accounts/yearend'
    );
    $template->render($eoy);
}

sub post_yearend {
    use LedgerSMB::DBObject::EOY;
    my ($request) = @_;
    my $eoy =  LedgerSMB::DBObject::EOY->new(base => $request);
    $eoy->close_books;
    my $template = LedgerSMB::Template->new_UI(
        user => $request->{_user},
        locale => $request->{_locale},
        template => 'accounts/yearend_complete'
    );
    $template->render($eoy);
    
}

# From AM.pm, modified for better API.

1;
