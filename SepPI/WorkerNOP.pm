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
# SPDX-License-Identifier: GPL-3.0-or-later                             #
#########################################################################

package SepPI::WorkerNOP;

use strict;
use warnings;

sub new
{
    my $class = shift;

    print "WorkerNOP new\n";

    my $self = {};
    bless $self;

    return $self;
}

sub reset
{
    my $self = shift;

    print "WorkerNOP reset\n";

    # do nothing
    return 0;
}

sub play
{
    my $self = shift;
    my $uid = shift;

    print "WorkerNOP [$uid] play\n";

    # do nothing
    return 0;
}

sub pause
{
    my $self = shift;
    my $uid = shift;

    print "WorkerNOP [$uid] pause\n";

    # do nothing
    return 0;
}

sub resume
{
    my $self = shift;
    my $uid = shift;

    print "WorkerNOP [$uid] resume\n";

    # do nothing
    return 0;
}

sub stop
{
    my $self = shift;
    my $uid = shift;

    print "WorkerNOP [$uid] stop\n";

    # do nothing
    return 0;
}

1;

__END__
