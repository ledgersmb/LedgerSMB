#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Math::BigFloat;

use LedgerSMB;
use LedgerSMB::Form;

my $form = new Form;
my %myconfig;
ok(defined $form);
isa_ok($form, 'Form');
my $lsmb = new LedgerSMB;
ok(defined $lsmb);
isa_ok($lsmb, 'LedgerSMB');

my $expected;
foreach my $value ('0.01', '0.05', '0.015', '0.025', '1.1', '1.5', '1.9', 
		'10.01', '4', '5', '5.1', '5.4', '5.5', '5.6', '6', '0', 
		'0.000', '10.155', '55', '0.001', '14.5', '15.5', '4.5') {
	foreach my $places ('3', '2', '1', '0') {
		Math::BigFloat->round_mode('+inf');
		$expected = Math::BigFloat->new($value)->ffround(-$places);
		$expected->precision(undef);
		is($form->round_amount($value, $places), $expected,
			"form: $value to $places decimal places - $expected");
		is($lsmb->round_amount($value, $places), $expected,
			"lsmb: $value to $places decimal places - $expected");

		Math::BigFloat->round_mode('-inf');
		$expected = Math::BigFloat->new(-$value)->ffround(-$places);
		$expected->precision(undef);
		is($form->round_amount(-$value, $places), $expected,
			"form: -$value to $places decimal places - $expected");
		is($lsmb->round_amount(-$value, $places), $expected,
			"lsmb: -$value to $places decimal places - $expected");
	}
	foreach my $places ('-1', '-2') {
		Math::BigFloat->round_mode('+inf');
		$expected = Math::BigFloat->new($value)->ffround(-($places-1));
		is($form->round_amount($value, $places), $expected,
			"form: $value to $places decimal places - $expected");
		is($lsmb->round_amount($value, $places), $expected,
			"lsmb: $value to $places decimal places - $expected");

		Math::BigFloat->round_mode('-inf');
		$expected = Math::BigFloat->new(-$value)->ffround(-($places-1));
		is($form->round_amount(-$value, $places), $expected,
			"form: -$value to $places decimal places - $expected");
		is($lsmb->round_amount(-$value, $places), $expected,
			"lsmb: -$value to $places decimal places - $expected");
	}
}

# TODO Number formatting still needs work for l10n
my @formats = (['1,000.00', ',', '.'], ["1'000.00", "'", '.'], 
		['1.000,00', '.', ','], ['1000,00', '', ','], 
		['1000.00', '', '.'], ['1 000.00', ' ', '.']);
my %myfooconfig = (numberformat => '1000.00');
foreach my $format (0 .. $#formats) {
	%myconfig = (numberformat => $formats[$format][0]);
	my $thou = $formats[$format][1];
	my $dec = $formats[$format][2];
	foreach my $rawValue ('10t000d00', '9t999d99', '333d33', 
			'7t777t777d77', '-12d34', '0d00') {
		$expected = $rawValue;
		$expected =~ s/t/$thou/gx;
		$expected =~ s/d/$dec/gx;
		my $value = $rawValue;
		$value =~ s/t//gx;
		$value =~ s/d/\./gx;
		##$value = Math::BigFloat->new($value);
		$value = $form->parse_amount(\%myfooconfig,$value);
		is($form->format_amount(\%myconfig, $value, 2, '0'), $expected,
			"form: $value formatted as $formats[$format][0] - $expected");
		is($lsmb->format_amount('user' => \%myconfig, 
			'amount' => $value, 'precision' => 2, 
			'neg_format' => '0'), $expected,
			"lsmb: $value formatted as $formats[$format][0] - $expected");
	}
}

$expected = $form->parse_amount({'numberformat' => '1000.00'}, '0.00');
is($form->format_amount({'numberformat' => '1000.00'} , $expected, 2, 'x'), 'x',
	"form: 0.00 with dash x");
is($lsmb->format_amount('user' => {'numberformat' => '1000.00'}, 
	'amount' => $expected, 'precision' => 2, 
	'neg_format' => 'x'), 'x',
	"lsmb: 0.00 with dash x");

foreach my $format (0 .. $#formats) {
	%myconfig = (numberformat => $formats[$format][0]);
	my $thou = $formats[$format][1];
	my $dec = $formats[$format][2];
	foreach my $rawValue ('10t000d00', '9t999d99', '333d33', 
			'7t777t777d77', '-12d34') {
		$expected = $rawValue;
		$expected =~ s/t/$thou/gx;
		$expected =~ s/d/$dec/gx;
		my $value = $rawValue;
		$value =~ s/t//gx;
		$value =~ s/d/\./gx;
		#my $ovalue = $value;
		$value = $form->parse_amount(\%myfooconfig,$value);
		#$value = $form->parse_amount(\%myconfig,$value);
		is($form->format_amount(\%myconfig, 
			$form->format_amount(\%myconfig, $value, 2, 'x'), 
			2, 'x'), $expected, 
			"form: Double formatting of $value as $formats[$format][0] - $expected");
		is($lsmb->format_amount('user' => \%myconfig, 
			'amount' => 
				$lsmb->format_amount('user' => \%myconfig, 
				'amount' => $value, 
				'precision' => 2, 
				'neg_format' => 'x'), 
			'precision' => 2, 'neg_format' => 'x'), $expected, 
			"lsmb: Double formatting of $value as $formats[$format][0] - $expected");
	}
}

foreach my $format (0 .. $#formats) {
	%myconfig = ('numberformat' => $formats[$format][0]);
	my $thou = $formats[$format][1];
	my $dec = $formats[$format][2];
	foreach my $rawValue ('10t000d00', '9t999d99', '333d33', 
			'7t777t777d77', '-12d34', '(76t543d21)') {
		$expected = $rawValue;
		$expected =~ s/t/$thou/gx;
		$expected =~ s/d/$dec/gx;
		my $value = $rawValue;
		$value =~ s/t//gx;
		$value =~ s/d/\./gx;
		if ($value =~ m/^\(/gx) {
			$value = Math::BigFloat->new('-'.substr($value, 1, -1));
		} else {
			$value = Math::BigFloat->new($value);
		}
		cmp_ok($form->parse_amount(\%myconfig, $expected), '==',  $value,
			"form: $expected parsed as $formats[$format][0] - $value");
		cmp_ok($lsmb->parse_amount('user' => \%myconfig, 
			'amount' => $expected), '==',  $value,
			"lsmb: $expected parsed as $formats[$format][0] - $value");
	}
	$expected = '12 CR';
	my $value = Math::BigFloat->new('12');
	cmp_ok($form->parse_amount(\%myconfig, $expected), '==',  $value,
		"form: $expected parsed as $formats[$format][0] - $value");
	cmp_ok($lsmb->parse_amount('user' => \%myconfig, 'amount' => $expected),
		'==',  $value,
		"lsmb: $expected parsed as $formats[$format][0] - $value");
	$expected = '21 DR';
	$value = Math::BigFloat->new('-21');
	cmp_ok($form->parse_amount(\%myconfig, $expected), '==',  $value,
		"form: $expected parsed as $formats[$format][0] - $value");
	cmp_ok($lsmb->parse_amount('user' => \%myconfig, 'amount' => $expected),
		'==',  $value,
		"lsmb: $expected parsed as $formats[$format][0] - $value");
	
	cmp_ok($form->parse_amount(\%myconfig, ''), '==', 0,
		"form: Empty string returns 0");
	cmp_ok($form->parse_amount(\%myconfig, 'foo'), 'eq',
		Math::BigFloat->bnan(), "form: Invalid string returns NaN");
	cmp_ok($lsmb->parse_amount('user' => \%myconfig, 'amount' => ''), '==', 0,
		"lsmb: Empty string returns 0");
	cmp_ok($lsmb->parse_amount('user' => \%myconfig, 'amount' => 'foo'), 'eq',
		Math::BigFloat->bnan(), "lsmb: Invalid string returns NaN");
}

foreach my $format (0 .. $#formats) {
	%myconfig = ('numberformat' => $formats[$format][0]);
	my $thou = $formats[$format][1];
	my $dec = $formats[$format][2];
	foreach my $rawValue ('10t000d00', '9t999d99', '333d33', 
			'7t777t777d77', '-12d34', '(76t543d21)') {
		$expected = $rawValue;
		$expected =~ s/t/$thou/gx;
		$expected =~ s/d/$dec/gx;
		my $value = $rawValue;
		$value =~ s/t//gx;
		$value =~ s/d/\./gx;
		if ($value =~ m/^\(/gx) {
			$value = Math::BigFloat->new('-'.substr($value, 1, -1));
		} else {
			$value = Math::BigFloat->new($value);
		}
		cmp_ok($form->parse_amount(\%myconfig, 
			$form->parse_amount(\%myconfig, $expected)),
			'==',  $value,
			"form: $expected parsed as $formats[$format][0] - $value");
		cmp_ok($lsmb->parse_amount('user' => \%myconfig, 
			'amount' => $lsmb->parse_amount('user' => \%myconfig, 
				'amount' => $expected)),
			'==',  $value,
			"lsmb: $expected parsed as $formats[$format][0] - $value");
	}
	$expected = '12 CR';
	my $value = Math::BigFloat->new('12');
	cmp_ok($form->parse_amount(\%myconfig, 
		$form->parse_amount(\%myconfig, $expected)),
		'==',  $value,
		"form: $expected parsed as $formats[$format][0] - $value");
	cmp_ok($lsmb->parse_amount('user' => \%myconfig, 
		'amount' => $lsmb->parse_amount('user' => \%myconfig, 
			'amount' => $expected)),
		'==',  $value,
		"lsmb: $expected parsed as $formats[$format][0] - $value");
	$expected = '21 DR';
	$value = Math::BigFloat->new('-21');
	cmp_ok($form->parse_amount(\%myconfig, 
		$form->parse_amount(\%myconfig, $expected)),
		'==',  $value,
		"form: $expected parsed as $formats[$format][0] - $value");
	cmp_ok($lsmb->parse_amount('user' => \%myconfig, 
		'amount' => $lsmb->parse_amount('user' => \%myconfig, 
			'amount' => $expected)),
		'==',  $value,
		"lsmb: $expected parsed as $formats[$format][0] - $value");

	cmp_ok($form->parse_amount(\%myconfig, ''), '==', 0,
		"form: Empty string returns 0");
	cmp_ok($form->parse_amount(\%myconfig, 'foo'), 'eq',
		Math::BigFloat->bnan(), "form: Invalid string returns NaN");
	cmp_ok($lsmb->parse_amount('user' => \%myconfig, 'amount' => ''), '==', 0,
		"lsmb: Empty string returns 0");
	cmp_ok($lsmb->parse_amount('user' => \%myconfig, 'amount' => 'foo'), 'eq',
		Math::BigFloat->bnan(), "lsmb: Invalid string returns NaN");
}
