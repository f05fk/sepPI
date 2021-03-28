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
# SPDX-License-Identifier: GPL-3.0+                                     #
#########################################################################

use strict;
use warnings;

use Find::Lib ".";

use Term::ReadKey;

use SepPI::MFRC522;

my $PLAYLISTS_DIRECTORY = "/home/pi/playlists";
my $run = 1;
$SIG{INT}  = sub { $run = 0 };
$SIG{TERM} = sub { $run = 0 };

chdir $PLAYLISTS_DIRECTORY || die "cannot go into playlists directory";

ReadMode 4;

my $mfrc522 = SepPI::MFRC522->new();

my @playlists = ();
loadPlaylists();

my $uid1 = "";
my $uid2 = "";
my $uid3 = "";
my $searchString = "";
my $index = 0;
my $selected = undef;

&display();
while ($run)
{
    &readRFID();
    &readKey();

#    sleep 1;
}

$mfrc522->close();
ReadMode 0;
exit 0;

sub readRFID
{
    my ($status, @uid) = $mfrc522->picc_readUID();

    $uid1 = join('-', map {sprintf "%02x", $_} reverse @uid);
#    print "found PICC: status [$status] UID [$uid1]\n";
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
            if (defined $selected)
            {
                &link();
            }
        }
        $uid2 = $uid1;
    }
}

sub readKey
{
    my $key = ReadKey(-1);
    return if (!defined $key);

    $searchString .= $key if ($key =~ m/^[-a-z0-9_.*+?]$/);
    $searchString .= ".*" if ($key eq " ");
    $searchString = substr($searchString, 0, -1) if ($key eq "\x7f");
    $run = 0 if ($key eq "\cc");

    if ($key eq "\x1b") # "Esc"
    {
        $key = ReadKey(-1);
        if (defined $key && $key eq "\x5b") # intermediate
        {
            $key = ReadKey(-1);
            if ($key eq "\x41") # up
            {
                $index--;
            }
            if ($key eq "\x42") # down
            {
                $index++;
            }
        }
        if (!defined $key) # only "Esc"
        {
            $searchString = "";
        }
    }

    &display();
}

sub display
{
    system("clear");

    my @found = grep { m/$searchString/i } @playlists;
    print "========================================================================\n";
    print "searchString: [$searchString] matches: [" . scalar(@found) . "]\n";
    print "========================================================================\n";
    $selected = undef;

    $index = 0 if ($index < 0);
    $index = 9 if ($index > 9);
    $index = scalar(@found) - 1 if ($index >= scalar(@found));
    for (my $i = 0; $i < 10; $i++)
    {
        if ($i == $index)
        {
            print("-> $i: $found[$i]\n");
            $selected = $found[$i];
        }
        elsif ($i < scalar(@found))
        {
            print("   $i: $found[$i]\n");
        }
        else
        {
            print("   $i: -\n");
        }
    }
    print "========================================================================\n";
    print "selected: " . ($selected ? $selected : "-") . "\n";
    print "========================================================================\n";
}

sub loadPlaylists
{
    opendir DIR, "." || die "cannot open playlists directory";
    @playlists = sort grep { -f $_ && !-l $_ } readdir DIR;
    closedir DIR;
}

sub link
{
    print "link [$uid3] to [$selected]\n";

    unlink "$uid3.m3u";
    symlink $selected, "$uid3.m3u";
    # Perl's built-in chown cannot chown symlinks
    system("chown -h pi:pi $uid3.m3u");
}
