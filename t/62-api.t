#!perl

BEGIN { 
	use LedgerSMB;
	use Test::More;
	use LedgerSMB::Template;
	use LedgerSMB::Sysconfig;
	use LedgerSMB::DBTest;
        use LedgerSMB::App_State;
        use LedgerSMB::Locale;
}

# TODO: FIXME
# This is a hack, and it's very bad!
# This is here because the subroutines _http_output,
# render, and error are redefined in here.
# This isn't ideal in the least. The subroutines should
# be refactored to provide different renderings based on
# whether or not they are being called in a test
# or regularly in the code.
# LedgerSMB::Template contains render and _http_output
# LedgerSMB contains error

LedgerSMB::App_State::set_Locale(LedgerSMB::Locale->get_handle('en'));

no warnings 'redefine';

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

@test_request_data = do { 't/data/62-request-data' } ; # Import test case hashes

for (qw(	drafts     login      payment      
		menu       contact
		inventory  vouchers recon)
    ){
	ok(eval { require "LedgerSMB/Scripts/$_.pm" }, "Importing $_");
	if ($@){
		print STDERR "Error:  $@\n";
	}
} # Import new code namespaces

my $dbh = LedgerSMB::DBTest->connect("dbi:Pg:dbname=$ENV{PGDATABASE}", undef, undef);
my $locale = LedgerSMB::Locale->get_handle( ${LedgerSMB::Sysconfig::language} );

for my $test (@$test_request_data){
    my $argstr="";
    my $module="";
        for my $key (keys %$test)
        {
            # scan both key and value for _$GLOBAL$.
            # replace _$GLOBAL$:varname with the value from the %GLOBAL{varname}
            if ( ( defined $key ) && ( $key =~ /_\$GLOBAL\$:(.*)$/ ) ) {
                my $newkey = $GLOBAL{$1};
                $key = $newkey;
            }   
            if ( ( defined $key ) &&  ( defined $test->{$key} ) && ( $test->{$key} =~ /_\$GLOBAL\$:(.*)$/ ) ) {
                my $val = $GLOBAL{$1};
                $test->{$key} = $val;
            }   
            if ( ( defined $key ) && ( $key eq 'module' ) ){
                $module = $test->{"$key"}
            }   
            elsif ( ( defined $test->{"$key"} ) && ( defined $key ) && ( $key !~ /^\_/ ) ){
                $argstr .= "&" . "$key=".$test->{"$key"};

            }   
        }  

        if (ref $test->{'_pre_test_sub'} eq 'CODE'){
		$test->{'_pre_test_sub'}();
	}
    my $request = LedgerSMB->new();
	if (lc $test->{_codebase} eq 'old'){
		next; # skip old codebase tests for now
		#old_code_test::_load_script($test->{module});
		#my $qstring = "$test->{module}?";
		#for $key (keys(%$test)){
			#if ($key !~ /^_/){
				#$qstring .= qq|$key=$test->{"$key"}&|;
			#}	
		#}
		#$qstring =~ s/&$//;
		#$old_code_test::form = Form->new($qstring);
		#for (keys (%$test)){
			#$form->{$_} = $test->{$_};
		#}
		#is('old_code_test'->can($test->{action}), 0,
			#"$test->{_test_id}: Action Successful");
	} else {
		$request->merge($test);
		$request->{_locale} = $locale;
		my $script = $test->{module};
		if (!$request->{action}){
			$request->{action} = '__default';
		}
		$request->{dbh} = $dbh;
		if (ref $test->{_api_test} eq 'CODE'){
			$request->{_test_cases} = $test->{_api_test};
		}
		$script =~ s/\.pl$//;
		is(ref "LedgerSMB::Scripts::$script"->can($request->{action}), 
			'CODE',
			"$test->{_test_id}: Action ($request->{action}) Defined");
		ok("LedgerSMB::Scripts::$script"->can($request->{action})->($request), "$test->{_test_id}: Action Successful");
	}

    if (ref $test->{_api_test} eq 'CODE'){
        $request->{_test_cases} = $test->{_api_test};
    }

	ok($dbh->rollback, "$test->{_test_id}: rollback");
}

package LedgerSMB::Template;
use Test::More;
# Don't render templates.  Just return so we can run tests on data structures.
sub render {
	my ($self, $data) = @_;

	if (ref $data->{_test_cases} eq 'CODE'){
		$data->{_test_cases}($data);
	}
	if ($data->{_error_test}){
		cmp_ok($data->{_died}, '==', '1', 
			"$data->{_test_id} died as expected");
	} else {
		ok(!defined $data->{_died}, 
			"$data->{_test_id} did not error");
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

package LedgerSMB;
sub error {
    my $self = shift;
    $self->{_error} = shift;
    $self->{_died} = 1;
}
