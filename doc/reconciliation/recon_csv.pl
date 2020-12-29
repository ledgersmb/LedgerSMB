# This is a simple CSV parsing routine.  The API isn't perfect and is likely to
# change in the future.  Right now the function is parse_[dbname]_[account_id].
#
# COPYRIGHT (c) 2012 Chris Travers (chris.travers@gmail.com)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Place, relative to ledgersmb root: LedgerSMB/Reconciliation/CSV/Formats/
package LedgerSMB::Reconciliation::CSV;

use strict;

# The below routines are aliases for parse_n() which does the work.  This would
# be done if the parsing was all done in the same format, with no differences.
#
# Of course if there were formatting differences, each format could abstract
# this out or the like.
#
# Despite the namespace this doesn't have to handle CSV, though that is the most
# frequent use case.  Any other format could be used instead.

sub parse_mycompany_11 {
    parse_n(@_);
}

# In 1.3, the recon parsing used only the account_id which meant that this
# wasn't very friendly system-wide.  As of 1.4, we include the db name as part
# of the dispatch routine.  For compatibility, you may still end up with 
# non-overlapping ranges.

sub parse_mycompany_12345 {
    parse_n(@_);
}


# This is the main function.  It's pretty quick and dirty.  You might want to 
# replace some of the CSV parsing with a CPAN module of your choice.
#
sub parse_n {
    # Basic setup--  arguemnts and private variables
    my $self = shift @_;
    my ($contents) = @_;
    my @entries;
    my @columns;
    my $first = 1;

    # Simple (read quick/dirty) Parsing of file.  All kinds of things could be
    # improved on this but this is just sample code so....
    #
    for my $line (split /\n/, $contents){
        next if ($line =~ /^$/);
        if ($first){
            # field conversions go here.
            @columns = qw(cleared_date amount scn type);
            $first = 0;
        } else {
            my @fields = split(/,/, $line);
            my $ref = {};
            for my $i(1 .. scalar @fields){
               $ref->{$columns[$i - 1]} = $fields[$i - 1]; 
            }
            push @entries, $ref;
        }
    }

    # The below logic might be helpful if a statement consisted of a mixture of
    # wire transfers and checks.  The major point is that we need lines back
    # from here in an order that makes it reasonable to make matches.  That
    # means we should return first the transactions which have a source control
    # number that is meaningful in LedgerSMB.  This means checks should be
    # returned first.
    #
    @entries = sort {($b->{type} eq 'CHECK') cmp  ($a->{type} eq 'CHECK')} @entries;
    return @entries;
}

1;
