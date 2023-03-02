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
__stdlib__="have option_on_off is_set sanitize random_str random realpath"

@import error

# @section Exported functions {{{1
# stdlib_have {{{2
#
# @description Check if a program is in PATH
#
# @arg $1 string Program to look for
#
# @exitcode True if program is in PATH
# @exitcode False if program is not in PATH
#
stdlib_have() ( command -v "$1" >/dev/null 2>&1;)

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

# stdlib_random_str {{{2
#
# @description: Generate a random string
#
# @arg $1 int    Number of characters to generate
# @arg $2 string Allowed characters
#
# @stdout Generated string
#
# TODO: fallback to awk (only once per second) if /dev/random not available
stdlib_random_str() (
    ASSERT $# -ge 1
    </dev/random tr -cd "${2:-[:alpha:]}" \
        | head -c"$1" 
)

# stdlib_random {{{2
#
# @description Generate a random number within a range
#
# @arg $1 int Minimum number
# @arg $2 int Maximum number
#
# @stdout Random number bewteen $1 and $2 (inclusive)
#
stdlib_random() (
    ASSERT $# -eq 1 -o $# -eq 2

    # Pass in a seed, otherwise awk won't generate a
    # new number for one second
    awk -v seed="$(date +%N)" -v min="$1" -v max="$2" \
        'BEGIN {
            srand(seed)
            print int(min + rand() * (max - min + 1))
        }'
)

# stdlib_realpath {{{2
#
# @description expand all symbolic links and resolve references to /./, /../ and
# extra '/' characters to produce a canonicalized path
#
# @arg $1 string Path to canonicalize
#
# @errors
#   EINVAL: Path is null
#   EACESS: Path prefix could not be found or read
#   ENOENT: The path does not exist
#
# @stdout Canonicalized path
#
stdlib_realpath() {
      if   [ -z "$1" ]; then
        error::set_error EINVAL # 22
        return
    elif ! [ -r "$(dirname "$1")" ]; then
        error::set_error EACCES # 13
        return
    elif ! [ -r "$1" ]; then
        error::set_error ENOENT # 2
        return
    fi

    dir=$(dirname "$1")
    file=$(basename "$1")

    # If the path is a link, get its target
    if [ -h "$1" ]; then
        file=$(find "$dir" -maxdepth 1 -name "$file" -exec ls -ld {} \; |
            rev | cut -d' ' -f1 | rev)
    fi

    # Just print absolute paths, otherwise canonicalize
    # relative paths
    case $file in
        /*) printf "%s\n" "$file" ;;
        *)  dir="$dir/$(dirname "$file")"
            if ! [ -d "$dir" ]; then
                error:set_error EACCES
                return
            fi
            # We can ignore failing to cd as we already
            # verified that the directory does actually exist
            # shellcheck disable=SC2164
            dir=$(cd "$dir"; pwd)
            printf "%s\n" "$dir/$(basename "$file")" 
            ;;
    esac
}

