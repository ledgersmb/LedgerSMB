=head1 NAME

LedgerSMB::ScriptLib::Common_Search - Common Search Routines for LedgerSMB

=head1 SYNOPSIS

TODO

=cut

package LedgerSMB::ScriptLib::Common_Search;
use strict;
use warnings;
use LedgerSMB::Template;

=head1 RESERVED ATTRIBUTES

These attributes will be overwritten in the process of using this module.
Please plan for this before rendering the form.

=over

=item columns

=item rows

=back

=head1 ROUTINES

=over

=item extract($request)

This takes a $request object and checks to see if a search_select option is set.
If one is, it returns a single hashref of the data submitted back with prefixes
removed.  If not, it runs through 1 .. $request->{search_rowcount} and checks
for submitted items.  It assembles these into a list and returns the list as a
list of hashrefs.

=cut

sub extract {
    my ($request) = @_;
    if ($request->{search_select}){
        my $id = $request->{search_select};
        my $retval = {};
        for my $key (keys %$request){
            if ($key =~ /^search\_.*\_$id$/){
               my $rkey = $key;
               $rkey =~ s/^search\_//;
               $rkey =~ s/\_$id$//;
               $retval->{$rkey} = $request->{$key};
            }
        }
        return $retval;
    } else {
        my @retval;
        for $row (1 .. $form->{search_rowcount}){
            next unless $form->{"search_select_$row"};
            my $id = $form->{"search_select_$row"};
            my $item = {};
            for my $key (keys %$request){
                if ($key =~ /^search\_.*\_$id$/){
                    my $rkey = $key;
                    $rkey =~ s/^search\_//;
                    $rkey =~ s/\_$id$//;
                    $item->{$rkey} = $request->{$key};
                }
            }
            push @retval, $item;
        }
        return @retval;
    }
}

=item render($request)

This renders the search screen.

=cut

sub render {
    my ($self, $request) = @_;
    $request->{columns} = $self->columns;
    $request->{rows} = $self->results;
    my $template = LedgerSMB::Template->new(
       user => $request->{_user},
       locale => $request->{_locale},
       path => 'UI',
       template => 'search_results',
       format => 'HTML',
    );
    $template->render($request);
}
    

=back

=head2 Child Classes Must Implement the Following

=item columns

Returns a list of columns as expected for Dynatable.

=item results

Returns a list of results, becomes the rows for the table.

=back

=head1 COPYRIGHT

Copyright (C) 2012 LedgerSMB Core Team.  This file may be re-used under the terms of the GNU General Public License version 2 or at your option any later version.

=cut

return 1;
