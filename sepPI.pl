#!/usr/bin/perl -I /home/pi/sepPI
#########################################################################
# Copyright (C) 2017-2018 Claus Schrammel <claus@f05fk.net>             #
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
#                                                                       #
# SPDX-License-Identifier: GPL-3.0+                                     #
#########################################################################

use strict;
use warnings;

use MFRC522;

my $run = 1;
$SIG{INT}  = sub { $run = 0 };
$SIG{TERM} = sub { $run = 0 };

#print "reset\n";
command("mpc stop");
command("mpc clear");

my $mfrc522 = MFRC522->new();
$mfrc522->pcd_setReceiverGain(MFRC522::RECEIVER_GAIN_MAX);

my $uid1 = "";
my $uid2 = "";
my $uid3 = "";
while ($run)
{
    my ($status, @uid) = $mfrc522->picc_readUID();

    $uid1 = join('-', map {sprintf "%02x", $_} reverse @uid);
#    print "found PICC: status [$status] UID [$uid1]\n";
    if ($uid1 ne $uid2)
    {
        if ($uid1 eq "")
        {
            print "$uid3 went away\n";
            $uid3 = "";
            command("mpc pause");
        }
        elsif ($uid1 eq $uid3)
        {
            print "$uid3 came back\n";
            command("mpc play");
        }
        else
        {
            print "$uid3 went away\n" if ($uid3 ne "");
            $uid3 = $uid1;
            print "$uid3 is NEW!\n";
            command("mpc stop");
            command("mpc clear");
            command("mpc load $uid3");
            command("mpc play");
        }
        $uid2 = $uid1;
    }

    sleep 1;
}

$mfrc522->close();
exit 0;

sub command
{
    my $command = shift;

    system("$command >/dev/null 2>&1");
}
