#!/usr/bin/perl
#########################################################################
# Copyright (C) 2017 Claus Schrammel <claus@f05fk.net>                  #
#                                                                       #
# This program is free software: you can redistribute it and/or modify  #
# it under the terms of the GNU General Public License as published by  #
# the Free Software Foundation, either version 3 of the License, or     #
# (at your option) any later version.                                   #
#                                                                       #
# This program is distributed in the hope that it will be useful,       #
# but WITHOUT ANY WARRANTY; without even the implied warranty of        #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
# GNU General Public License for more details.                          #
#                                                                       #
# You should have received a copy of the GNU General Public License     #
# along with this program.  If not, see <http://www.gnu.org/licenses/>. #
#########################################################################

use strict;
use warnings;

use MFRC522;

my $run = 1;
$SIG{INT}  = sub { $run = 0 };
$SIG{TERM} = sub { $run = 0 };

my $mfrc522 = MFRC522->new();
$mfrc522->pcd_setReceiverGain(MFRC522::RECEIVER_GAIN_MAX);

while ($run)
{
    my ($status, @uid) = $mfrc522->picc_selectTag();

    my $uidhex = join(':', map {sprintf "%02x", $_} @uid);
    print "found PICC: status [$status] UID [$uidhex]\n";

    sleep(1);
}

$mfrc522->close();
exit 0;
