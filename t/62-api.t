BEGIN { 
	use LedgerSMB;
	use Test::More;
	use LedgerSMB::Template;
	use LedgerSMB::Sysconfig;
	use LedgerSMB::DBTest;
}


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

for (qw(	drafts.pl     login.pl      payment.pl      
		report.pl    employee.pl   menu.pl       vendor.pl
		customer.pl  inventory.pl  vouchers.pl)
    ){
	ok(eval { require "scripts/$_" }, "Importing $_");
	if ($@){
		print STDERR "Error:  $@\n";
	}
} # Import new code namespaces

my $dbh = LedgerSMB::DBTest->connect("dbi:Pg:dbname=$ENV{PGDATABASE}", undef, undef);
my $locale = LedgerSMB::Locale->get_handle( ${LedgerSMB::Sysconfig::language} );

for my $test (@$test_request_data){
	if (lc $test->{_codebase} eq 'old'){
		next; # skip old codebase tests for now
		old_code_test::_load_script($test->{module});
		my $qtring = "$test->{module}?";
		for $key (keys(%$test)){
			if ($key !~ /^_/){
				$qstring .= qq|$key=$test->{"$key"}&|;
			}	
		}
		$qstring =~ s/&$//;
		$old_code_test::form = Form->new($qstring);
		for (keys (%$test)){
			$form->{$_} = $test->{$_};
		}
		is('old_code_test'->can($test->{action}), 0,
			"$test->{_test_id}: Action Successful");
	} else {
		my $request = LedgerSMB->new();
		$request->merge($test);
		$request->{_locale} = $locale;
		my $script = $test->{module};
		$request->{dbh} = $dbh;
		if (ref $api_test_cases->{"$test->{_test_id}"} eq 'CODE'){
			$request->{_test_cases} = 
				$api_test_cases->{"$test->{_test_id}"};
		}
		delete $api_test_cases->{"$test->{_test_id}"};
		$script =~ s/\.pl$//;
		is(ref "LedgerSMB::Scripts::$script"->can($request->{action}), 
			'CODE',
			"$test->{_test_id}: Action ($request->{action}) Defined");
		ok("LedgerSMB::Scripts::$script"->can($request->{action})->($request), "$test->{_test_id}: Action Successful");
	}
	if (ref $api_test_cases->{"$test->{_test_id}"} eq 'CODE'){
		$request->{_test_cases} = 
			$api_test_cases->{"$test->{_test_id}"};
	}
	ok($dbh->rollback, "$test->{_test_id}: rollback");
}

package LedgerSMB::Template;

# Don't render templates.  Just return so we can run tests on data structures.
sub render {
	my ($self, $data) = @_;
	if (ref $data->{_test_cases} eq 'CODE'){
		$data->{_test_cases}($data);
	}
	return 1;
}

sub _http_output {
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
