=head1 NAME

LedgerSMB::REST_Class::Contact - Customer/vendor web servicesA

=head1 SYNOPSIS

 my $obj = LedgerSMB::REST_Class::Contact->new(%$payload);
 $obj->GET; # or PUT or POST.  DELETE not implemented for this class

=head1 DESCRIPTION

This module contains the basic  handlers

=head1 PROPERTIES

=head1 METHODS

=over

=item GET

Searches or retrieves one or more records.

=item POST

Determines of record exists and if not creates it.  If so, throws a 400 error

=item PUT

Saves record, overwriting any record that was there before.

=item DELETE not implemented.

=back

=head1 COPYRIGHT

Copyright (C) 2012, the LedgerSMB Core Team.  This file may be re-used under 
the GNU GPL version 2 or at your option any future version.  Please see the 
accompanying LICENSE file for details.

=cut

