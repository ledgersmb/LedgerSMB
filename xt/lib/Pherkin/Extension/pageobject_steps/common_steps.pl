#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;


Transform qr/^table:/, sub {
    my ($c, $data) = @_;

    for my $row (@$data) {
        for my $col (sort keys %$row) {

            if (defined $row->{$col}) {
                if ($row->{$col} =~ m/^\$\$(.*)$/) {
                    if (exists S->{$1}) {
                        $row->{$col} =  S->{$1};
                    }
                    else {
                        warn "Substitution \$\$$1 not available in stash";
                    }
                }
            }
        }
    }
};


1;
