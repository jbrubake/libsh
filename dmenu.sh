# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Copyright 2022 Jeremy Brubaker <jbru362@gmail.com>
#
# @file dmenu.sh
# @brief dmenu.sh
#
# @description dmenu shell routines
#
# Initialization {{{1
__dmenu__="make_args getxres"

# @section Exported functions {{{1
#
dmenu_getxres() ( # {{{2
    prog="$(basename $0)"
    xrdb -query \
        | grep $prog \
        | awk "/$prog.*$1/ {print \$2}"
)

dmenu_get_args() ( # {{{2
    resources="font
               background
               foreground
               selbackground
               selforeground
               hibackground
               hiforeground
               hiselbackground
               hiselforeground
               outforeground
               outbackground
               borderwidth"

    args=
    r=

    for r in $resources; do
        val=$(dmenu_getxres "$r")
        test -z "$val" && continue

        case $r in
            background)    args="-nb  $val $args" ;;
            foreground)    args="-nf  $val $args" ;;
            selbackground) args="-sb  $val $args" ;;
            selforeground) args="-sf  $val $args" ;;
            hibackground)  args="-nhb $val $args" ;;
            hiforeground)  args="-nhf $val $args" ;;
            outbackground) args="-shb $val $args" ;;
            outforeground) args="-shf $val $args" ;;
            font)          args="-fn  $val $args" ;;
            borderwidth)   args="-bw  $val $args" ;;
        esac

    done

    echo "$args" | tr -s ' '
)

