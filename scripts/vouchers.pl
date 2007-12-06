#!/usr/bin/perl

# This file is copyright (C) 2007the LedgerSMB core team and licensed under 
# the GNU General Public License.  For more information please see the included
# LICENSE and COPYRIGHT files

package LedgerSMB::Scripts::vouchers;
our $VERSION = '0.1';

$menufile = "menu.ini";
use LedgerSMB::Batch;
use LedgerSMB::Voucher;
use LedgerSMB::Template;
use strict;

sub create_batch {
    my ($request) = @_;
    $request->{hidden} = [
        {name => "batch_type", value => $request->{batch_type}},
    ];
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user}, 
        locale => $request->{_locale},
        path => 'UI',
        template => 'create_batch',
        format => 'HTML'
    );
    $template->render($request);
}

sub create_vouchers {
    #  This function is not safe for caching as long as the scripts are in bin.
    #  This is because these scripts import all functions into the *current*
    #  namespace.  People using fastcgi and modperl should *not* cache this 
    #  module at the moment. -- CT
    #  Also-- request is in 'our' scope here due to the redirect logic.
    our ($request) = shift @_;
    use LedgerSMB::Form;

    my $batch = LedgerSMB::Batch->new({base => $request});
    $batch->{batch_class} = $request->{batch_type};
    $batch->create;

    our $vouchers_dispatch = 
    {
        payable    => {script => 'bin/ap.pl', function => sub {add()}},
        receivable => {script => 'bin/ar.pl', function => sub {add()}},
        gl         => {script => 'bin/gl.pl', function => sub {add()}},
        receipt   => {script => 'scripts/payment.pl', 
	             function => sub {
				my ($request) = @_;
				$request->{account_class} = 2;
				LedgerSMB::Scripts::payment::payments($request);
				}},
        payment   => {script => 'scripts/payment.pl', 
	             function => sub {
				my ($request) = @_;
				$request->{account_class} = 1;
				LedgerSMB::Scripts::payment::payments($request);
				}},
	
    };

    # Note that the line below is generally considered incredibly bad form. 
    # However, the code we are including is going to require it for now. -- CT
    our $form = new Form;
    our $locale = $request->{_locale};

    for (keys %$request){
        $form->{$_} = $request->{$_};
    }

    $form->{batch_id} = $batch->{id};
    $form->{approved} = 0;
    $form->{transdate} = $request->{batch_date};

    $request->{batch_id} = $batch->{id};
    $request->{approved} = 0;
    $request->{transdate} = $request->{batch_date};


    my $script = $vouchers_dispatch->{$request->{batch_type}}{script};
    $form->{script} = $script;
    $form->{script} =~ s|.*/||;
    if ($script =~ /^bin/){

        { no strict; no warnings 'redefine'; do $script; }

    } elsif ($script =~ /scripts/) {

         { do $script } 

    }

    $vouchers_dispatch->{$request->{batch_type}}{function}($request);
}

sub get_batch {
}

sub list_vouchers {
}

sub add_vouchers {
}

sub approve_batch {
}

sub delete_batch {
}

eval { do "scripts/custom/Voucher.pl"};
1;
