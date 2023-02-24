# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# Copyright 2023 Jeremy Brubaker <jbru362@gmail.com>
#
# @file net.sh
# @brief net.sh
#
# @description
#   net.sh description
#
# Initialization {{{1
#
__net__="has_internet"

@import error

# Functions {{{1
#
# net_has_internet {{{2
#
# @description Check for an internet connection. Based on
# https://github.com/libremesh/lime-packages/blob/master/packages/check-internet/files/usr/bin/check-internet
#
# @noargs
#
# @exitcode 0 if internet connection is up
# @exitcode 1 if internet connection is down
# @exitcode 2 on error
#
# @requires wget or curl
#
# NOTE: Cannot be a sub-shell function because it sets errno
#
net_has_internet() {
    url="http://detectportal.firefox.com/success.txt"

    if type wget >/dev/null 2>&1; then
        test "$(wget -q $url --timeout=1 -O -)" = "success"
    elif type curl >/dev/null 2>&1; then
        test "$(curl -s $url)" = "success"
    else
        error::set_error ENOENT
    fi
}

