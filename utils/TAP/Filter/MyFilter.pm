package TAP::Filter::MyFilter;

use strict;
use warnings;
use base qw( TAP::Filter::Iterator );

sub inspect {
    my ( $self, $result ) = @_;
    if ( $result->is_test ) {
        my $description = $result->description;
        if ( defined $description && $description =~ /- Test skipped due to failure in previous step/ ) {
            return (
                $result,
                TAP::Filter->ok(
                    ok => 1,
                    description =>
                      '- Test skipped due to failure in previous step',
                    directive => 'SKIP'
                )
            );
        }
    }
    return $result;
}

1;
