#!/bin/sh
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

if [ "x$1" = "xplay" ]
then
    mpc random off >/dev/null 2>&1
    curl https://static.orf.at/podcast/oe1/oe1_rudi.xml 2>/dev/null \
        | perl -ne 'while (m/<enclosure url="(.*?)"/g) { print "$1\n"; }' \
        | mpc add >/dev/null 2>&1
    mpc play >/dev/null 2>&1
fi

if [ "x$1" = "xpause" ]
then
    mpc pause >/dev/null 2>&1
fi

if [ "x$1" = "xresume" ]
then
    mpc play >/dev/null 2>&1
fi

if [ "x$1" = "xstop" ]
then
    mpc stop >/dev/null 2>&1
    mpc clear >/dev/null 2>&1
    mpc random off >/dev/null 2>&1
fi

exit 0
