#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
# 
# See COPYRIGHT file for copyright information
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# two frame layout with refractured menu
#
#######################################################################

$menufile = "menu.ini";
use LedgerSMB::Menu;

1;
# end of main


sub display {

	$menuwidth = ($ENV{HTTP_USER_AGENT} =~ /links/i) ? "240" : "155";
	$menuwidth = $myconfig{menuwidth} if $myconfig{menuwidth};

	$form->header(!$form->{duplicate});

	print qq|
	<frameset cols="$menuwidth,*" border="1">
		<frame name="acc_menu" src="$form->{script}?login=$form->{login}&amp;sessionid=$form->{sessionid}&amp;action=acc_menu&amp;path=$form->{path}&amp;js=$form->{js}" />
		<frame name="main_window" src="am.pl?login=$form->{login}&amp;sessionid=$form->{sessionid}&amp;action=$form->{main}&amp;path=$form->{path}" />
	</frameset>
	</html>
	|;

}



sub acc_menu {

	my $menu = new Menu "$menufile";
	$menu->add_file("custom_$menufile") if -f "custom_$menufile";
	$menu->add_file("$form->{login}_$menufile") if -f "$form->{login}_$menufile";

	$form->{title} = $locale->text('Accounting Menu');

	my $headeradd = q|
	<script type="text/javascript">

		function SwitchMenu(obj) {
			if (document.getElementById) {
				var el = document.getElementById(obj);

				if (el.style.display == "none") {
					el.style.display = "block"; //display the block of info
				} else {
					el.style.display = "none";
				}
			}		
		}

		function ChangeClass(menu, newClass) {
			if (document.getElementById) {
				document.getElementById(menu).className = newClass;
			}
		}

		document.onselectstart = new Function("return false");
	</script>|;
	$form->header(undef, $headeradd);
	print q|

	<body class="menu">
	<img class="cornderlogo" src="ledger-smb_small.png" width="100" height="50" border="1" alt="ledger-smb" />
	|;

	if ($form->{js}) {
		&js_menu($menu);
	} else {
		&section_menu($menu);
	}

	print q|
	</body>
	</html>
	|;

}


sub section_menu {

	my ($menu, $level) = @_;

	# build tiered menus
	my @menuorder = $menu->access_control(\%myconfig, $level);

	while (@menuorder) {
		$item = shift @menuorder;
		$label = $item;
		$label =~ s/$level--//g;

		my $spacer = "&nbsp;" x (($item =~ s/--/--/g) * 2);

		$label =~ s/.*--//g;
		$label = $locale->text($label);
		$label =~ s/ /&nbsp;/g if $label !~ /<img /i;

		$menu->{$item}{target} = "main_window" unless $menu->{$item}{target};

		if ($menu->{$item}{submenu}) {

			$menu->{$item}{$item} = !$form->{$item};

			if ($form->{level} && $item =~ $form->{level}) {

				# expand menu
				print qq|<br />\n$spacer|.$menu->menuitem(\%myconfig, \%$form, $item, $level).qq|$label</a>|;

				# remove same level items
				map { shift @menuorder } grep /^$item/, @menuorder;

				&section_menu($menu, $item);

				print qq|<br />\n|;

			} else {

			print qq|<br />\n$spacer|.$menu->menuitem(\%myconfig, \%$form, $item, $level).qq|$label&nbsp;...</a>|;

			# remove same level items
			map { shift @menuorder } grep /^$item/, @menuorder;

			}

		} else {

			if ($menu->{$item}{module}) {

				print qq|<br />\n$spacer|.$menu->menuitem(\%myconfig, \%$form, $item, $level).qq|$label</a>|;

			} else {

				$form->{tag}++;
				print qq|<a name="id$form->{tag}"></a><p><b>$label</b></p>|;

				&section_menu($menu, $item);

				print qq|<br />\n|;

			}
		}
	}
}


sub js_menu {

	my ($menu, $level) = @_;

	print qq| <div id="div_$menu_$level"> |;

	# build tiered menus
	my @menuorder = $menu->access_control(\%myconfig, $level);

	while (@menuorder){
		$i++;
		$item = shift @menuorder;
		$label = $item;
		$label =~ s/.*--//g;
		$label = $locale->text($label);

		$menu->{$item}{target} = "main_window" unless $menu->{$item}{target};

		if ($menu->{$item}{submenu}) {

			$display = "display: none;" unless $level eq ' ';

			print qq|
			<div id="menu$i" class="menuOut" onclick="SwitchMenu('sub$i')" onmouseover="ChangeClass('menu$i','menuOver')" onmouseout="ChangeClass('menu$i','menuOut')">$label</div>
			<div class="submenu" id="sub$i" style="$display">|;

			# remove same level items
			map { shift @menuorder } grep /^$item/, @menuorder;

			&js_menu($menu, $item);

			print qq|

			</div>
			|;

		} else {

			if ($menu->{$item}{module}) {

				if ($level eq "") {
					print qq|<div id="menu$i" class="menuOut" onmouseover="ChangeClass('menu$i','menuOver')" onmouseout="ChangeClass('menu$i','menuOut')"> |. 
							 $menu->menuitem(\%myconfig, \%$form, $item, $level).qq|$label</a></div>|;

					# remove same level items
					map { shift @menuorder } grep /^$item/, @menuorder;

					&js_menu($menu, $item);

				} else {

					print qq|<div class="submenu"> |.
							$menu->menuitem(\%myconfig, \%$form, $item, $level).qq|$label</a></div>|;
				}

			} else {

				$display = "display: none;" unless $item eq ' ';

				print qq|
					<div id="menu$i" class="menuOut" onclick="SwitchMenu('sub$i')" onmouseover="ChangeClass('menu$i','menuOver')" onmouseout="ChangeClass('menu$i','menuOut')">$label</div>
					<div class="submenu" id="sub$i" style="$display">|;

				&js_menu($menu, $item);

				print qq| </div> |;

			}

		}

	}

	print qq| </div> |;
}


sub menubar {

1;

}


