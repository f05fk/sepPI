#!/usr/bin/perl
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

use Device::BCM2835;
use Time::HiRes qw(usleep);

my $run = 1;
$SIG{INT}  = sub { $run = 0 };
$SIG{TERM} = sub { $run = 0 };

Device::BCM2835::init();

&initialize();

my @buttons =
(
    {gpio => 23, value => 1, action => \&buttonVolumePlus},
    {gpio => 24, value => 1, action => \&buttonVolumeMinus},
    {gpio => 12, value => 1, action => \&buttonNext},
    {gpio => 16, value => 1, action => \&buttonPrev},
);

foreach my $button (@buttons)
{
    Device::BCM2835::gpio_fsel($button->{gpio}, &Device::BCM2835::BCM2835_GPIO_FSEL_INPT);
    Device::BCM2835::gpio_set_pud($button->{gpio}, &Device::BCM2835::BCM2835_GPIO_PUD_UP);
}

while ($run)
{
    foreach my $button (@buttons)
    {
        my $lev = Device::BCM2835::gpio_lev($button->{gpio});
        &{$button->{action}} if ($lev == 0 && $button->{value} == 1);
        $button->{value} = $lev;
    }
    usleep 50000;
}

exit 0;

sub initialize
{
#    print "initialize\n";
    system("mpc volume 60 >/dev/null 2>&1");
}

sub buttonVolumePlus
{
#    print "button [+] pressed\n";
    system("mpc volume +5 >/dev/null 2>&1");
}

sub buttonVolumeMinus
{
#    print "button [-] pressed\n";
    system("mpc volume -5 >/dev/null 2>&1");
}

sub buttonNext
{
#    print "button [>] pressed\n";
    system("mpc next >/dev/null 2>&1");
}

sub buttonPrev
{
#    print "button [<] pressed\n";
    system("mpc cdprev >/dev/null 2>&1");
}
