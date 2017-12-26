use Test::More tests => 5;
use LedgerSMB::Setting;
use LedgerSMB::App_State;
use strict;

use warnings;

{
  no strict 'refs'; # avoiding addming more dependencies
                    # so doing mocking by hand

  no warnings 'redefine';
  my $got_dbh = sub { ok(1, 'Got Database Handle'); return 'db' };
  local *{"LedgerSMB::App_State::DBH"} = $got_dbh;

  local *{"PGObject::call_procedure"} = sub { ok(1, 'Called "call_procedure"'); return ({setting_key => 'database', value => '123'}) };

  use strict 'refs';
  use warnings 'redefine';

  is(LedgerSMB::Setting->dbh(), 'db', 'got mocked db return');
  is(LedgerSMB::Setting->get('database'), '123', 'got mocked value back');

}
