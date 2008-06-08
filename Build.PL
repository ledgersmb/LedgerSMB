use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new (
	dist_name => 'LedgerSMB',
	dist_version => '1.2.14',
	license => 'GPL',
	requires => {
		'perl'				=> '>= 5.8.1',
		'Data::Dumper'			=> 0,
		'Locale::Maketext'		=> 0,
		'Locale::Maketext::Lexicon'	=> '>= 0.56',
		'MIME::Base64'			=> 0,
		'Digest::MD5'			=> 0,
		'HTML::Entities'		=> 0,
		'DBI'				=> '>= 1.00',
		'DBD::Pg'			=> 0,
		'Math::BigFloat'		=> 0,
		'IO::File'			=> 0,
		'Encode'			=> 0,
		'Locale::Country'		=> 0,
		'Locale::Language'		=> 0,
		'Time::Local'			=> 0,
		'Cwd'				=> 0,
		'Config::Std'			=> 0,
		'MIME::Lite'			=> 0,
		'Test::More'			=> 0,
		'Test::Trap'			=> 0,
		},
	recommends => {
		'HTML::LinkExtor'		=> 0,
		'FileHandle'			=> 0,
		'Getopt::Long'			=> 0,
		'Net::TCLink'			=> 0,
		'Parse::RecDescent'		=> 0,
		},
);

$build->create_build_script;
