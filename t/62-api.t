BEGIN { 
	use LedgerSMB;
	use Test::More;
	use LedgerSMB::Template;
	use LedgerSMB::DBTest;
}

our $api_test_cases = {
};

if (defined $ENV{LSMB_TEST_DB}){
	if (defined $ENV{LSMB_NEW_DB}){
		$ENV{PGDATABASE} = $ENV{LSMB_NEW_DB};
	}
	if (!defined $ENV{PGDATABASE}){
		die "Oops...  LSMB_TEST_DB set but no db selected!";
	}
	plan 'no_plan';
} else {
	plan skip_all => 'Skipping, LSMB_TEST_DB environment variable not set.';
}

do 't/data/62-request-data'; # Import test case hashes

for (qw(	admin.pl     drafts.pl     login.pl      payment.pl      
		report.pl    employee.pl   menu.pl       vendor.pl
		customer.pl  inventory.pl  migration.pl  recon.pl        
		vouchers.pl)){

	do "$_";
} # Import new code namespaces

my $dbh = LedgerSMB::DBTest->connect("dbi:Pg:dbname=$ENV{PGDATABASE}", undef, undef);

print scalar @$test_request_data ." test case scenarios defined";

for my $test (@$test_request_data){
	if (lc $test->{_codebase} eq 'old'){
		old_code_test::_load_script($test->{module});
		$old_code_test::form = new Form();
		for (keys (%$test)){
			$form->{$_} = $test->{$_};
		}
		ok(eval ("old_code_test::$test->{action}()"), 
			"$test->{_test_id}: Action Successful");
	} else {
		my $request = LedgerSMB->new();
		$request->merge($test);
		my $script = $test->{module};
		$script =~ s/\.pl$//;
		ok(eval "LedgerSMB::Scripts::$script::$request->{action}(\$request)");
	}
	for (@{$api_test_cases->{"$test->{_test_id}"}}){
		&$_;
	}
	ok($dbh->rollback, "$test->{_test_id}: rollback");
}

package LedgerSMB::Template;

# Don't render templates.  Just return so we can run tests on data structures.
sub render {
	return 1;
}

package old_code_test;
# Keeps old code isolated in a different namespace, and provides for reasonable 
# reload facilities.
our $form;

sub _load_script {
	do "bin/arapprn.pl";
	do "bin/arap.pl";
	do "bin/io.pl";
	do "bin/$1[0]";
}
