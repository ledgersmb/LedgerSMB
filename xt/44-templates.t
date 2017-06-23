#!perl

=head1 UNIT TESTS FOR

LedgerSMB::Template::DBProvider

=cut

use Template;
use LedgerSMB::Database;
use LedgerSMB::Template::DBProvider;
use Test::More;

use Log::Log4perl;
use Log::Log4perl::Level ();

Log::Log4perl->easy_init( Log::Log4perl::Level::to_priority( 'OFF' ) );

my @missing = grep { ! $ENV{$_} } (qw(LSMB_NEW_DB LSMB_TEST_DB));
plan skip_all => (join ', ', @missing) . ' not set' if @missing;

plan tests => 14;

=head1 TEST PLAN

=head2 Object instantiation test

=cut

my $provider = LedgerSMB::Template::DBProvider->new;
ok($provider, 'provider instantiated');
is(ref $provider, 'LedgerSMB::Template::DBProvider',
   'instance of correct type');
ok($provider->isa('Template::Provider'),
   'instance is a subclass of Template::Provider');


=head2 Template retrieval

=cut

my $dbh = LedgerSMB::Database->new(
    dbname => $ENV{LSMB_NEW_DB},
    username => $ENV{PGUSER},
    password => $ENV{PGPASSWORD},
    host => $ENV{PGHOST})
    ->connect({ AutoCommit => 0, PrintError => 0, RaiseError => 1 });

$dbh->do(qq|
INSERT INTO template (template_name, language_code, template, format,
                      last_modified)
VALUES ('provider-test1', NULL, 'The NULL language template', 'html', 'epoch')
|);
$dbh->do(qq|
INSERT INTO template (template_name, language_code, template, format,
                      last_modified)
VALUES ('provider-test1', 'en_US', 'The en_US language template',
        'html', 'epoch')
|);

$provider = LedgerSMB::Template::DBProvider->new({
    _dbh => $dbh,
    language_code => undef,
    format => 'html',
});

is($provider->_template_content('provider-test1'),
  'The NULL language template', 'Template lookup in scalar context');
is($provider->_template_modified('provider-test1'), 0,
   'Template modification date (integer secs since epoch)');

$dbh->do(qq|
UPDATE template
   SET last_modified = (('epoch'::timestamp with time zone) + '1.12 seconds'::interval)
 WHERE template_name='provider-test1'
|);
is($provider->_template_modified('provider-test1'), 1,
   'Template modification date (integer secs since epoch)');



my @rv = $provider->_template_content('provider-test1');
is(scalar(@rv), 3, '_template_content returns 3 values');
is($rv[0], 'The NULL language template',
           'array context returns the correct template content');
ok(! $rv[1], 'In case of success, the error is undef or an empty string');
is($rv[2], 1, 'Array context: Template modification == 0 secs since epoch');



=head2 Template engine execution

=cut

$dbh->do(qq|
UPDATE template
   SET last_modified = now()
 WHERE template_name='provider-test1'
|);


my $template = Template->new({
   LOAD_TEMPLATES => [ $provider ],
});

ok($template, 'Correctly instantiated Template object');

my $output = '';
$template->process('provider-test1', {}, \$output)
  || die $template->error();
is($output, 'The NULL language template', "Template.pm retrieved the template");


=head2 Template INCLUDE processing

=cut

$dbh->do(qq|
INSERT INTO template (template_name, language_code, template, format,
                      last_modified)
VALUES ('provider-test2', NULL, '[% INCLUDE "provider-test2-include" %]',
        'html', now())
|);
$dbh->do(qq|
INSERT INTO template (template_name, language_code, template, format,
                      last_modified)
VALUES ('provider-test2-include', NULL, 'INCLUDEd text',
        'html', now())
|);

$output = '';
$template->process('provider-test2', {}, \$output) || die $template->error();
is($output, 'INCLUDEd text', 'Template include loaded and processed');


=head2 Template variable processing

=cut

$dbh->do(qq|
INSERT INTO template (template_name, language_code, template, format,
                      last_modified)
VALUES ('provider-test3', NULL, 'Hello <?lsmb name ?>, ....',
        'html', now())
|);

$output = '';
$provider = LedgerSMB::Template::DBProvider->new({
    _dbh => $dbh,
    language_code => undef,
    format => 'html',
    PARSER => Template::Parser->new({
       START_TAG => quotemeta('<?lsmb'),
       END_TAG => quotemeta('?>'),
    }),
});
$template = Template->new({
   LOAD_TEMPLATES => [ $provider ],
});
$template->process('provider-test3', {
   name => 'yo' }, \$output) || die $template->error();
is($output, 'Hello yo, ....', 'Template include loaded and processed');



$dbh->rollback;
$dbh->disconnect;
