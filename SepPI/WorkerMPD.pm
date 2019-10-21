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

package SepPI::WorkerMPD;

use strict;
use warnings;

use SepPI::PersistentStatus;

sub new
{
    my $class = shift;

    print "WorkerMPD new\n";

    my $self = {};
    bless $self;

    return $self;
}

sub reset
{
    my $self = shift;

    print "WorkerMPD reset\n";

    _command("mpc stop");
    _command("mpc clear");
    _command("mpc random off");
    return 0;
}

sub play
{
    my $self = shift;
    my $uid = shift;

    print "WorkerMPD [$uid] play\n";

    _command("mpc load $uid") == 0 || return 1;
    _command("mpc random off");
    SepPI::PersistentStatus->new($uid)->load();
    _command("mpc play");
    return 0;
}

sub pause
{
    my $self = shift;
    my $uid = shift;

    print "WorkerMPD [$uid] pause\n";

    _command("mpc pause");
    SepPI::PersistentStatus->new($uid)->save();
    return 0;
}

sub resume
{
    my $self = shift;
    my $uid = shift;

    print "WorkerMPD [$uid] resume\n";

    SepPI::PersistentStatus->new($uid)->clean();
    _command("mpc play");
    return 0;
}

sub stop
{
    my $self = shift;
    my $uid = shift;

    print "WorkerMPD [$uid] stop\n";

    _command("mpc pause");
    SepPI::PersistentStatus->new($uid)->save();

    _command("mpc stop");
    _command("mpc clear");
    _command("mpc random off");
    return 0;
}

sub _command
{
    my $command = shift;

    return system("$command >/dev/null 2>&1");
}

1;

__END__
