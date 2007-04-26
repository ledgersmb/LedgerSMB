use Data::UUID;
$ug   = new Data::UUID;
$uuid = $ug->create();
print $ug->to_string($uuid);
print "\n";
