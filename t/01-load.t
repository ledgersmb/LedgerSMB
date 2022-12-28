#!/usr/bin/perl

use strict;
use warnings;

use File::Find;

use Test2::V0;
use Test2::Tools::Spec;


####### Test setup

my @on_disk;
sub collect {
    return if $File::Find::name !~ m/\.pm$/;

    my $module = $File::Find::name;
    $module =~ s#^old/##g;
    $module =~ s#^lib/##g;
    $module =~ s#/#::#g;
    $module =~ s#\.pm$##g;
    push @on_disk, $module
}
find(\&collect, 'lib/LedgerSMB/', 'old/lib/LedgerSMB/');

my %tested = ( 'LedgerSMB::Sysconfig' => 1 );
sub module_loads {
    my ($module, @required_modules) = @_;

    return if $tested{$module}; # don't test twice
    $tested{$module} = 1;

    tests modules_loadable => { iso => 1, async => (! $ENV{COVERAGE}) }, sub {
        for (@required_modules) {
            eval "require $_"
                or skip_all "Test missing required module '$_'";
        }

        ok eval("require $module"), $@;
    };
}



########### The actual tests


use Test2::Require::Module 'LedgerSMB::Sysconfig';

module_loads
    'LedgerSMB::Template::Plugin::ODS' => qw( XML::Twig OpenOffice::OODoc );

module_loads
    'LedgerSMB::Template::Plugin::LaTeX' =>
    qw( Template::Plugin::Latex Template::Latex );

module_loads
    'LedgerSMB::Template::Plugin::XLSX' =>
    qw( Excel::Writer::XLSX Spreadsheet::WriteExcel );

for ('LedgerSMB::X12', 'LedgerSMB::X12::EDI850', 'LedgerSMB::X12::EDI894') {
    module_loads $_ => qw( X12::Parser );
}

for my $module (sort @on_disk) {
    module_loads $module;
}

done_testing;
