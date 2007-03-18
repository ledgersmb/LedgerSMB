#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
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
# Copyright (C) 2002
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors: Tony Fraser <tony@sybaspace.com>
#
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# routines for menu items
#
#=====================================================================

package Menu;

use LedgerSMB::Inifile;
@ISA = qw/Inifile/;


sub menuitem {
	my ($self, $myconfig, $form, $item) = @_;

	my $module = ($self->{$item}{module}) 
		? $self->{$item}{module} : $form->{script};
	my $action = ($self->{$item}{action}) 
		? $self->{$item}{action} : "section_menu";
	my $target = ($self->{$item}{target}) 
		? $self->{$item}{target} : "";

	my $level = $form->escape($item);
	my $style;
	if ($form->{menubar}){
		$style = "";
	} else {
		$style = "display:block;";
	}
	my $str = qq|<a style="$style"|. 
		qq|href="$module?path=$form->{path}&amp;action=$action&amp;|.
		qq|level=$level&amp;login=$form->{login}&amp;|.
		qq|timeout=$form->{timeout}&amp;sessionid=$form->{sessionid}|.
		qq|&amp;js=$form->{js}|;

	my @vars = qw(module action target href);
  
	if ($self->{$item}{href}) {
		$str = qq|<a href="$self->{$item}{href}|;
		@vars = qw(module target href);
	}

	for (@vars) { delete $self->{$item}{$_} }
  
	delete $self->{$item}{submenu};
 
	# add other params
	foreach my $key (keys %{ $self->{$item} }) {
		$str .= "&amp;".$form->escape($key)."=";
		($value, $conf) = split /=/, $self->{$item}{$key}, 2;
		$value = "$myconfig->{$value}$conf" 
			if $self->{$item}{$key} =~ /=/;
    
		$str .= $form->escape($value);
	}

	$str .= qq|#id$form->{tag}| if $target eq 'acc_menu';
  
	if ($target) {
	  $str .= qq|" target="$target"|;
	}
	else{
		$str .= '"';
	}
  
	$str .= qq|>|;
  
}


sub access_control {
	my ($self, $myconfig, $menulevel) = @_;
  
	my @menu = ();

	if ($menulevel eq "") {
		@menu = grep { !/--/ } @{ $self->{ORDER} };
	} else {
		@menu = grep { /^${menulevel}--/; } @{ $self->{ORDER} };
	}

	my @a = split /;/, $myconfig->{acs};
	my $excl = ();

	# remove --AR, --AP from array
	grep { ($a, $b) = split /--/; s/--$a$//; } @a;

	for (@a) { $excl{$_} = 1 }

	@a = ();
	for (@menu) { push @a, $_ unless $excl{$_} }

	@a;

}


1;

