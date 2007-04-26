#
######################################################################
# LedgerSMB Accounting and ERP
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
# Driver for Logic Controls PD-3000 Pole Display.
# As with all pole display drivers, the control codes are contained in a hash
# array called $pd_control.

# THis pole display uses separate meanings for LF and CR.  Both are included.
# LF moves the cursor to the other line (same position), while CR moves the
# cursor to the left-most spot (same line).  Assume most PD's do this.
# Most of this is simple ASCII, but what to make things clear.

# This first part is straight from the manual.
# Not including the bit about installing fonts.

%pd_control = (
    'mode_vscroll'   => pack( 'C',  18 ),
    'mode_normal'    => pack( 'C',  17 ),
    'bright_full'    => pack( 'CC', 4, 0xFF ),
    'bright_high'    => pack( 'CC', 4, 0x60 ),
    'bright_med'     => pack( 'CC', 4, 0x40 ),
    'bright_low'     => pack( 'CC', 4, 0x20 ),
    'backspace'      => pack( 'C',  8 ),
    'htab'           => pack( 'C',  9 ),        # Functions like cursor movement
    'lf'             => pack( 'C',  0x0A ),
    'cr'             => pack( 'C',  0x0D ),
    'digit_select'   => pack( 'C',  0x10 ),     # Pack followed by a number 0-39
    'cursor_on'      => pack( 'C',  0x13 ),
    'cursor_off'     => pack( 'C',  0x14 ),
    'reset'          => pack( 'C',  0x1F ),
    'scroll_message' => pack( 'C',  0x05 ),     # Followed by up to 45 chars.
);

# A few more useful control sequences:
$pd_control{'new_line'} = $pd_control{'cr'} . $pd_control{'lf'};

