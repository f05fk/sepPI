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

use Device::BCM2835;
use Time::HiRes qw(usleep);

my $run = 1;
$SIG{INT}  = sub { $run = 0 };
$SIG{TERM} = sub { $run = 0 };

Device::BCM2835::init();

&initialize();

# each button gets a bit assigned and is initialized with level 1 (pull up)
my @buttons =
(
    {gpio => 12, level => 1, value => 0b0001},
    {gpio => 16, level => 1, value => 0b0010},
    {gpio => 23, level => 1, value => 0b0100},
    {gpio => 24, level => 1, value => 0b1000},
);

# various bit patterns, i.e. buttons pressed together, can trigger actions
my %actions =
(
    0b0001 => \&actionNext,
    0b0010 => \&actionPrev,
    0b0011 => \&actionRandom,
    0b0100 => \&actionVolumePlus,
    0b1000 => \&actionVolumeMinus,
    0b1100 => \&actionReset,
    0b1111 => \&actionShutdown,
);

# initialize buttons as input and pull up
foreach my $button (@buttons)
{
    Device::BCM2835::gpio_fsel($button->{gpio}, &Device::BCM2835::BCM2835_GPIO_FSEL_INPT);
    Device::BCM2835::gpio_set_pud($button->{gpio}, &Device::BCM2835::BCM2835_GPIO_PUD_UP);
}

# the event loop
my $canFireAction = 0;
while ($run)
{
    foreach my $button (@buttons)
    {
        my $level = Device::BCM2835::gpio_lev($button->{gpio});

        # if button is pressed (level == 0)
        # and do not do calculations if already can fire action
        if ($level == 0 && $button->{level} == 1 && $canFireAction == 0)
        {
            my $combinedState = &calculateCombinedState();
            $canFireAction = 1 if ($combinedState == 0);
        }

        # if button is released (level == 1)
        # and only do calculations if can fire action
        if ($level == 1 && $button->{level} == 0 && $canFireAction == 1)
        {
            my $combinedState = &calculateCombinedState();
            my $action = $actions{$combinedState};
            &$action() if ($action);
            $canFireAction = 0;
        }

        $button->{level} = $level;
    }
    usleep 50000;
}

exit 0;

sub calculateCombinedState
{
    my $combinedState = 0;
    foreach my $button (@buttons)
    {
        $combinedState |= $button->{value} if ($button->{level} == 0);
    }
    return $combinedState;
}

sub initialize
{
    print "initialize\n";
    system("mpc volume 50 >/dev/null 2>&1");
}

sub actionNext
{
    print "next track: button [>] pressed\n";
    system("mpc next >/dev/null 2>&1");
}

sub actionPrev
{
    print "previous track: button [<] pressed\n";
    system("mpc cdprev >/dev/null 2>&1");
}

sub actionRandom
{
    print "random: buttons [<>] pressed\n";
    system("mpc stop >/dev/null 2>&1");
    system("mpc shuffle >/dev/null 2>&1");
    system("mpc play >/dev/null 2>&1");
}

sub actionVolumePlus
{
    print "volume up: button [+] pressed\n";
    system("mpc volume +5 >/dev/null 2>&1");
}

sub actionVolumeMinus
{
    print "volume down: button [-] pressed\n";
    system("mpc volume -5 >/dev/null 2>&1");
}

sub actionReset
{
    print "reset: buttons [+-] pressed\n";
    system("mpc play 1 >/dev/null 2>&1");
}

sub actionShutdown
{
    print "shutdown: buttons [-+<>] pressed\n";
    system("init 0 >/dev/null 2>&1");
}
