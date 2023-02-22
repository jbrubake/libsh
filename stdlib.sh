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
# @file stdlib.sh
# @brief stdlib.sh
#
# @description
#   stdlib.sh description
#
# Initialization {{{1
#
__stdlib__="option_on_off is_set sanitize"

# @section Exported functions {{{1
# stdlib_option_on_off {{{2
#
# @description Test if a string is set to Yes or No
#
# @arg $1 string Value to test
# @arg $2 bool   Default value (true or false)
#
# @exitcode True if value is 1|y|Y|yes|YES|Yes
# @exitcode False if value is 0|n|N|no|NO|No
# @exitcode $2 if value is anything else
# @exitcode True if $2 is neither True or False
#
stdlib_option_on_off() (
    case "$1" in
        1 | y | Y | yes | YES | Yes) return 0 ;;
        0 | n | N | no  | NO  | No)  return 1 ;;
        *)
            case "$2" in
                t | true  | T | TRUE  | True)  return 0 ;;
                f | false | F | FALSE | False) return 1 ;;
                *) return 0 ;;
            esac
    esac
)

# stdlib_is_set {{{2
#
# @description Test if a variable is set or not
#
# @arg $1 string Name of variable to check
#
# @exitcode True if variable is set to anything but ""
# @exitcode False if variable is unset or set to ""
#
stdlib_is_set() ( eval "test \$$(stdlib_sanitize "$1")"; )

# stdlib_sanitize {{{2
#
# @description Sanitize input
#
# @arg $1 string String to sanitize
# @arg $2 string Allowed characters (see tr(1))
#
# @stdout Sanitized string
#
stdlib_sanitize() (
    if [ -z "$2" ]; then
        allowed="a-zA-Z0-9_"
    fi
    printf "%s" "$1" | tr -cd "$allowed"
)

