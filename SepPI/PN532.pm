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

package SepPI::PN532;

use strict;
use warnings;

sub new
{
    my $class = shift;
    my %options = @_;

    my $self = {};
    bless $self;

    $self->{debug} = 1 if ($options{debug});
    print "MFRC522::new\n" if ($self->{debug});

    # nothing to do in new/init

    return $self;
}

sub close
{
    my $self = shift;

    print "MFRC522::close\n" if ($self->{debug});

    # nothing to do in close

    return;
}

sub picc_readUID
{
    my $self = shift;

    print "MFRC522::picc_readUID\n" if ($self->{debug});

    # read the UID from the output of the command line tool nfc-list

    my @uid;

    open CMD, "nfc-list -t 1 |";
    while (<CMD>)
    {
        next if (!m/UID (.*): (.*)/);
        @uid = map { hex $_ } m/\s([0-9a-f]{2})\s/g;
    }
    close CMD;

    return (0, @uid);
#    return (MI_OK, @uid);
}

1;

__END__
