######################################################################
# LedgerSMB Small Medium Business Accounting
# Copyright (c) 2000
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://sourceforge.net/projects/ledger-smb/
#
#  Contributors: Christopher Browne <cbrowne@acm.org>
#                Tony Fraser <tony@sybaspace.com>
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
#######################################################################
#
# menu for text based browsers (lynx)
#
#######################################################################

$menufile = "menu.ini";
use SL::Menu;


1;
# end of main



sub display {

  $menu = new Menu "$menufile";
  $menu->add_file("custom_$menufile") if -f "custom_$menufile";
  $menu->add_file("$form->{login}_$menufile") if -f "$form->{login}_$menufile";
  
  @menuorder = $menu->access_control(\%myconfig);

  $form->{title} = "LedgerSMB $form->{version}";
  
  $form->header(1);

  $offset = int (21 - $#menuorder)/2;

  print "<pre>";
  print "\n" x $offset;
  print "</pre>";

  print qq|<center><table>|;

  map { print "<tr><td>".$menu->menuitem(\%myconfig, \%$form, $_).$locale->text($_).qq|</a></td></tr>|; } @menuorder;

  print qq'
</table>

</body>
</html>
';

}


sub section_menu {

  $menu = new Menu "$menufile", $form->{level};
  
  $menu->add_file("custom_$menufile") if -f "custom_$menufile";
  $menu->add_file("$form->{login}_$menufile") if -f "$form->{login}_$menufile";
  
  # build tiered menus
  @menuorder = $menu->access_control(\%myconfig, $form->{level});

  foreach $item (@menuorder) {
    $a = $item;
    $item =~ s/^$form->{level}--//;
    push @neworder, $a unless ($item =~ /--/);
  }
  @menuorder = @neworder;
 
  $level = $form->{level};
  $level =~ s/--/ /g;

  $form->{title} = $locale->text($level);
  
  $form->header;

  $offset = int (21 - $#menuorder)/2;
  print "<pre>";
  print "\n" x $offset;
  print "</pre>";
  
  print qq|<center><table>|;

  foreach $item (@menuorder) {
    $label = $item;
    $label =~ s/$form->{level}--//g;

    # remove target
    $menu->{$item}{target} = "";

    print "<tr><td>".$menu->menuitem(\%myconfig, \%$form, $item, $form->{level}).$locale->text($label)."</a></td></tr>";
  }
  
  print qq'</table>

</body>
</html>
';

}


sub acc_menu {
  
  &section_menu;
  
}


sub menubar {
  $menu = new Menu "$menufile", "";
  
  # build menubar
  @menuorder = $menu->access_control(\%myconfig, "");

  @neworder = ();
  map { push @neworder, $_ unless ($_ =~ /--/) } @menuorder;
  @menuorder = @neworder;

  print "<p>";
  $form->{script} = "menu.pl";

  print "| ";
  foreach $item (@menuorder) {
    $label = $item;

    # remove target
    $menu->{$item}{target} = "";

    print $menu->menuitem(\%myconfig, \%$form, $item, "").$locale->text($label)."</a> | ";
  }
  
}


