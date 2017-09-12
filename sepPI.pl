#!/usr/bin/perl

use strict;
use warnings;

use MFRC522;

my $mfrc522 = MFRC522->new();

my $gain = $mfrc522->pcd_read(MFRC522::RFCfgReg);
printf "Receiver Gain: %0x\n", $gain;
$gain = $mfrc522->pcd_setBitMask(MFRC522::RFCfgReg, 0x7 << 4);
printf "Receiver Gain: %0x\n", $gain;
$gain = $mfrc522->pcd_read(MFRC522::RFCfgReg);
printf "Receiver Gain: %0x\n", $gain;

$mfrc522->picc_wakeup();
$mfrc522->picc_anticoll();
