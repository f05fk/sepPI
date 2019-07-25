#!/usr/bin/perl
#########################################################################
# Copyright (C) 2017-2019 Claus Schrammel <claus@f05fk.net>             #
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
# SPDX-License-Identifier: GPL-3.0-or-later                             #
#########################################################################

use strict;
use warnings;

use Find::Lib ".";

use MFRC522;
use WorkerMPD;
use WorkerNOP;
use WorkerScript;

my $run = 1;
$SIG{INT}  = sub { $run = 0 };
$SIG{TERM} = sub { $run = 0 };

my $workerMPD = WorkerMPD->new();
my $workerNOP = WorkerNOP->new();
my $workerScript = WorkerScript->new();
my $worker = $workerNOP;

#print "reset\n";
$workerMPD->reset();
$workerNOP->reset();
$workerScript->reset();

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
            $worker->pause($uid3);
        }
        elsif ($uid1 eq $uid3)
        {
            print "$uid3 came back\n";
            $worker->resume($uid3);
        }
        else
        {
            print "$uid3 went away\n" if ($uid2 ne "");
            $worker->stop($uid3);
            $uid3 = $uid1;
            print "$uid3 is NEW!\n";
            $worker = ($workerScript->play($uid3) == 0) ? $workerScript :
                      ($workerMPD->play($uid3) == 0) ? $workerMPD :
                      ($workerMPD->play("unknown") == 0) ? $workerMPD :
                       $workerNOP;
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
