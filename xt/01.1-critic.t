#!/usr/bin/perl

use strict;
use warnings;
use Test::More; # plan automatically generated below
use File::Find;
use Perl::Critic;

my @on_disk;


# LedgerSMB aims to comply with the Perl::Critic policies recommended
# by by CERT. See:
# https://gist.github.com/briandfoy/4525877
# https://www.securecoding.cert.org/confluence/display/perl/SEI+CERT+Perl+Coding+Standard
#
# Currently our code violates some of the recommended policies, so tests
# are being added to this list as violations are fixed.
my @cert_policies = qw(
    BuiltinFunctions::ProhibitUniversalCan
    ClassHierarchies::ProhibitExplicitISA
    ControlStructures::ProhibitMutatingListFunctions
    ControlStructures::ProhibitUnreachableCode
    InputOutput::ProhibitBarewordFileHandles
    InputOutput::ProhibitInteractiveTest
    InputOutput::ProhibitOneArgSelect
    InputOutput::ProhibitTwoArgOpen
    InputOutput::RequireCheckedOpen
    Miscellanea::ProhibitFormats
    Modules::ProhibitEvilModules
    Modules::RequireEndWithOne
    Subroutines::ProhibitReturnSort
    Subroutines::ProhibitSubroutinePrototypes
    TestingAndDebugging::ProhibitProlongedStrictureOverride
    TestingAndDebugging::RequireUseStrict
    TestingAndDebugging::RequireUseWarnings
    ValuesAndExpressions::ProhibitLeadingZeros
    Variables::ProhibitPerl4PackageNames
    Variables::ProhibitUnusedVariables
    Variables::ProtectPrivateVars
    Variables::RequireLexicalLoopIterators
);

# The CERT recommended policies yet to be applied are listed below. Some
# of these are explicitly excluded below, as they would otherwise be
# applied by the -severity option in use.
#    BuiltinFunctions::ProhibitBooleanGrep
#    BuiltinFunctions::ProhibitStringyEval      --explicitly excluded
#    BuiltinFunctions::ProhibitStringySplit
#    BuiltinFunctions::ProhibitUniversalIsa
#    InputOutput::RequireCheckedClose
#    InputOutput::RequireCheckedSyscalls
#    Objects::ProhibitIndirectSyntax
#    RegularExpressions::ProhibitCaptureWithoutTest
#    Subroutines::ProhibitBuiltinHomonyms
#    Subroutines::ProhibitExplicitReturnUndef   --explicitly excluded
#    Subroutines::ProhibitUnusedPrivateSubroutines
#    Subroutines::ProtectPrivateSubs
#    Subroutines::RequireFinalReturn
#    TestingAndDebugging::ProhibitNoStrict      --explicitly excluded
#    TestingAndDebugging:;ProhibitNoWarnings    --explicitly excluded
#    ValuesAndExpressions::ProhibitCommaSeparatedStatements
#    ValuesAndExpressions::ProhibitMagicNumbers
#    ValuesAndExpressions::ProhibitMismatchedOperators
#    ValuesAndExpressions::ProhibitMixedBooleanOperators
#    Variables::RequireInitializationForLocalVars
#    Variables::RequireLocalizedPunctuationVars

# The following CERT recommended policies will not be enforced:
#    ErrorHandling::RequireCarping
#      As per ledgerSMB coding guidelines, calling "die" is the preferred
#      way to signal an error. We can't stop die()ing, because that's how
#      our error handling is implemented.  See:
#      https://ledgersmb.org/community-guide/community-guide/development/coding-guidelines/perl-coding-guidelines
#      https://matrix.to/#/!qyoLumPqusaXqFJNyK:matrix.org/$1492804519389522uYnup:matrix.org

# LedgerSMB enforces some other Perl::Critic policies
my @lsmb_policies = qw(
    ProhibitTrailingWhitespace
    ProhibitHardTabs
    Modules
    Moose::RequireMakeImmutable
    Moose::RequireCleanNamespace
    TestingAndDebugging
    ProhibitPuncutationVars
);

# LedgerSMB explicitly excludes some policies which we currently violate
# and which would be applied automatically by the -severity option in use.
# As violations are fixed, we can gradually remove these exclusions.
my @exclude_policies = qw(
    Modules::RequireVersionVar
    Subroutines::ProhibitExplicitReturnUndef
    TestingAndDebugging::ProhibitNoWarnings
    TestingAndDebugging::ProhibitNoStrict
    InputOutput::RequireEncodingWithUTF8Layer
    BuiltinFunctions::ProhibitStringyEval
);
my @exclude_policies_oldcode = qw(
    BuiltinFunctions::ProhibitStringyEval
    InputOutput::RequireEncodingWithUTF8Layer
    Modules::ProhibitConditionalUseStatements
    Modules::ProhibitEvilModules
    Modules::ProhibitExcessMainComplexity
    Modules::ProhibitMultiplePackages
    Modules::RequireBarewordIncludes
    Modules::RequireEndWithOne
    Modules::RequireFilenameMatchesPackage
    Modules::RequireVersionVar
    Subroutines::ProhibitExplicitReturnUndef
    TestingAndDebugging::ProhibitNoStrict
    TestingAndDebugging::ProhibitNoWarnings
    TestingAndDebugging::RequireUseStrict
    TestingAndDebugging::RequireUseWarnings
);


sub test_files {
    my ($critic, $files) = @_;

    for my $file (@$files) {
        my @findings = $critic->critique($file);

        ok(scalar(@findings) == 0, "Critique for $file");
        for my $finding (@findings) {
            diag($finding->description);
        }
    }

    return;
}

sub collect {
    return if $File::Find::name !~ m/\.(pm|pl)$/;

    my $module = $File::Find::name;
    push @on_disk, $module
}
find(\&collect, 'lib/', 'old/');

my @on_disk_oldcode =
    grep { m#^old/#  }
    @on_disk;

@on_disk =
    grep { ! m#^old/# }
    grep { ! m#^lib/LedgerSMB/Auth/# }
    @on_disk;

plan tests => scalar(@on_disk) + scalar(@on_disk_oldcode);

&test_files(
    Perl::Critic->new(
        -profile => 'xt/perlcriticrc',
        -severity => 5,
        -theme => '',
        -exclude => [
            @exclude_policies,
        ],
        -include => [
            @cert_policies,
            @lsmb_policies,
        ],
    ),
    \@on_disk
);

&test_files(
    Perl::Critic->new(
        -profile => 'xt/perlcriticrc',
        -severity => 5,
        -theme => '',
        -exclude => [
            @exclude_policies_oldcode,
        ],
        -include => [
            @cert_policies,
            @lsmb_policies,
        ],
    ),
    \@on_disk_oldcode
);



