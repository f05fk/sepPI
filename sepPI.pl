#!/usr/bin/perl

use strict;
use warnings;

use MFRC522;

my $mfrc522 = MFRC522->new();

$mfrc522->pcd_setReceiverGain(MFRC522::RECEIVER_GAIN_MAX);

$mfrc522->picc_selectTag();
