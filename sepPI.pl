#!/usr/bin/perl

use strict;
use warnings;

use MFRC522;

my $mfrc522 = MFRC522->new();
$mfrc522->pcd_setReceiverGain(MFRC522::RECEIVER_GAIN_MAX);

my ($status, @uid) = $mfrc522->picc_selectTag();

my $uidhex = join(':', map {sprintf "%02x", $_} @uid);
print "found PICC: status [$status] UID [$uidhex]\n";
