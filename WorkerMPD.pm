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

package WorkerMPD;

use strict;
use warnings;

use PersistentStatus;

sub new
{
    my $class = shift;

    my $self = {};
    bless $self;

    return $self;
}

sub reset
{
    my $self = shift;

    _command("mpc stop");
    _command("mpc clear");
    _command("mpc random off");
    return 0;
}

sub play
{
    my $self = shift;
    my $uid = shift;

    _command("mpc load $uid") == 0 || return 1;
    _command("mpc random off");
    PersistentStatus->new($uid)->load();
    _command("mpc play");
    return 0;
}

sub pause
{
    my $self = shift;
    my $uid = shift;

    _command("mpc pause");
    PersistentStatus->new($uid)->save();
    return 0;
}

sub resume
{
    my $self = shift;
    my $uid = shift;

    PersistentStatus->new($uid)->clean();
    _command("mpc play");
    return 0;
}

sub stop
{
    my $self = shift;
    my $uid = shift;

    _command("mpc pause");
    PersistentStatus->new($uid)->save();

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
