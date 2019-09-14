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

    print "PersistentStatus [$playlist] new\n";

    my $self = {};
    bless $self;

    $self->{playlist} = $playlist;
    $self->{file} = "$SCRIPT_DIR/$playlist";

    return $self;
}

sub save
{
    my $self = shift;

    print "PersistentStatus [$self->{playlist}] save\n";

    # get the status for current song number and time
    open MPCST, "mpc status |" || return 1;
    my $st = join '', <MPCST>;
    close MPCST || return 1;

    # can only persist a paused state
    return 2 if ($st !~ m/\[paused\]/);

    print "is paused...\n";

    # get the playlist to be persisted as well
    open MPCPL, "mpc playlist |" || return 3;
    my $pl = join '', <MPCPL>;
    close MPCPL || return 3;

    # cannot persist streams
    return 4 if ($pl =~ m/^https?:\/\//);

    print "is no stream...\n";

    # write the persistent state
    open STATUS, ">$self->{file}" || return 5;
    print STATUS $st;
    print STATUS $pl;
    close STATUS || return 5;

    # chown pi:pi file
    chown 1000, 1000, $self->{file} || return 6;

    print "PersistentStatus [$self->{playlist}] saved\n";

    return 0;
}

sub load
{
    my $self = shift;

    print "PersistentStatus [$self->{playlist}] load\n";

    # if file does not exist, then there is nothing to load and we are done
    -f $self->{file} || return 0;

    # calculate age of file
    my $modtime = (stat($self->{file}))[9];
    my $now = time();
    my $days = ($now - $modtime) / 24 / 60 / 60;
    if ($days > 7)
    {
	# delete and skip if file is too old
        print "PersistentStatus [$self->{playlist}] too old\n";
        unlink $self->{file} || return 2;
        return 0;
    }

    print "load...\n";

    # load file
    open STATUS, "<$self->{file}" || return 1;
    my $current = <STATUS>;
    my $status = <STATUS>;
    my $extra = <STATUS>;
    my @playlist = <STATUS>;
    close STATUS || return 1;

    # and delete it since it is no longer needed
    unlink $self->{file} || return 2;

    # load the current playlist (for comparison with the persisted playlist)
#    open MPCPL, "mpc playlist |" || return 3;
#    my $pl = join '', <MPCPL>;
#    close MPCPL || return 3;

    # parse song number and time for resuming at correct point
    $status =~ m/^\[paused\] +#(\d+)\/\d+ *(\d+:\d+)\/.*/ || return 4;
    my $song = $1;
    my $time = $2;

    # resume
    system("mpc play $song >/dev/null 2>&1") == 0 || return 5;
    system("mpc seek $time >/dev/null 2>&1") == 0 || return 5;

    print "PersistentStatus [$self->{playlist}] loaded\n";

    return 0;
}

sub clean
{
    my $self = shift;

    print "PersistentStatus [$self->{playlist}] clean\n";

    unlink $self->{file};

    return 0;
}

1;

__END__
