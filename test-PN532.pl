#!/usr/bin/perl
#########################################################################
# Copyright (C) Claus Schrammel <claus@f05fk.net>                       #
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

use Find::Lib ".";

use SepPI::PN532;

$|=1;

my $pn532 = SepPI::PN532->new(debug => 1);

my $uid1 = "";
my $uid2 = "";
my $uid3 = "";

while (1)
{
    print "================================================================================\n";
    &readRFID();
    print "================================================================================\n";
    sleep 3;
}

$pn532->close();
exit 0;

sub readRFID
{
    my ($status, @uid) = $pn532->picc_readUID();

    $uid1 = join('-', map {sprintf "%02x", $_} reverse @uid);
    print "found PICC: status [$status] UID [$uid1]\n";
    if ($uid1 ne $uid2)
    {
        if ($uid1 eq "")
        {
            print "$uid3 went away\n";
        }
        elsif ($uid1 eq $uid3)
        {
            print "$uid3 came back\n";
        }
        else
        {
            print "$uid3 went away\n" if ($uid2 ne "");
            $uid3 = $uid1;
            print "$uid3 is NEW!\n";
        }
        $uid2 = $uid1;
    }
}
