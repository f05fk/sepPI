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

package PersistentStatus;

use strict;
use warnings;

my $SCRIPT_DIR = "/home/pi/status";

sub new
{
    my $class = shift;
    my $playlist = shift;

    my $self = {};
    bless $self;

    $self->{playlist} = $playlist;
    $self->{file} = "$SCRIPT_DIR/$playlist";

    return $self;
}

sub save
{
    my $self = shift;

    open MPCST, "mpc status |" || return 1;
    my $st = join '', <MPCST>;
    close MPCST || return 1;

    return 2 if ($st !~ m/\[paused\]/);

    open MPCPL, "mpc playlist |" || return 3;
    my $pl = join '', <MPCPL>;
    close MPCPL || return 3;

    return 4 if ($pl =~ m/^https?:\/\//);

    open STATUS, ">$self->{file}" || return 5;
    print STATUS $st;
    print STATUS $pl;
    close STATUS || return 5;

    chown 1000, 1000, $self->{file} || return 6;

    return 0;
}

sub load
{
    my $self = shift;

    -f $self->{file} || return 0;

    print "load...\n";

    open STATUS, "<$self->{file}" || return 1;
    my $current = <STATUS>;
    my $status = <STATUS>;
    my $extra = <STATUS>;
    my @playlist = <STATUS>;
    close STATUS || return 1;

    unlink $self->{file} || return 2;

#    open MPCPL, "mpc playlist |" || return 3;
#    my $pl = join '', <MPCPL>;
#    close MPCPL || return 3;

    $status =~ m/^\[paused\] +#(\d+)\/\d+ *(\d+:\d+)\/.*/ || return 4;
    my $song = $1;
    my $time = $2;

    system("mpc play $song >/dev/null 2>&1") == 0 || return 5;
    system("mpc seek $time >/dev/null 2>&1") == 0 || return 5;

    return 0;
}

sub clean
{
    my $self = shift;

    unlink $self->{file};

    return 0;
}

1;

__END__
