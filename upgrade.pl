#!/usr/bin/perl

`perl -ibak -pe 's|<\%(\.)\%>|<?lsmb $1 ?>|g' templates/*`
