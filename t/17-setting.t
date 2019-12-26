
use Test2::V0;
use LedgerSMB::Setting;
use LedgerSMB::App_State;

{
  no strict 'refs'; # avoiding addming more dependencies
                    # so doing mocking by hand

  no warnings 'redefine';


  # LedgerSMB::Setting->get always uses LedgerSMB::App_State::DBH
  # as a datbase handle, regardless of any other initialisation.
  my $got_dbh = sub { ok(1, 'Got Database Handle'); return 'db' };
  local *{"LedgerSMB::App_State::DBH"} = $got_dbh;

  # Check that it uses that database handle to run the query
  local *{"PGObject::call_procedure"} = sub {
    my ($self, %args) = @_;
    ok(1, 'Called "call_procedure"');
    is($args{dbh}, 'db', 'Mocked dbh in use');
    return ({setting_key => 'database', value => '123'})
  };

  use strict 'refs';
  use warnings 'redefine';

  is(LedgerSMB::Setting->new({base => {dbh => 'db'}})->get('database'), '123', 'got mocked value back');
}





done_testing;