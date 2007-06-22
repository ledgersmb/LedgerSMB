#=====================================================================
# LedgerSMB Small Medium Business Accounting
# http://www.ledgersmb.org/
#

# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.
#
# This file contains source code included with or based on SQL-Ledger which
# is Copyright Dieter Simader and DWS Systems Inc. 2000-2005 and licensed
# under the GNU General Public License version 2 or, at your option, any later
# version.  For a full list including contact information of contributors,
# maintainers, and copyright holders, see the CONTRIBUTORS file.
#
# Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
# Copyright (c) 2004
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#======================================================================

use LedgerSMB::Template;

1;

# end of main

sub getpassword {
    $form->{sessionexpired} = shift @_;
    @{$form->{hidden}};
    for (keys %$form){
        next if $_ =~ /(^script$|^endsession$|^password$)/;
        my $attr = {};
        $attr->{name} = $_;
        $attr->{value} = $form->{$_};
        push @{$form->{hidden}}, $attr;
    }
    my $template = LedgerSMB::Template->new(
        user => \%myconfig, 
        locale => $locale,
        path => 'UI',
        template => 'get_password',
        format => 'HTML'
    );
    $template->render($form);
    $template->output('http');
    exit;
}

