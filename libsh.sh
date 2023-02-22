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
# @file lib.sh
# @brief lib.sh setup
#
# @description
#   lib.sh description
#
# TODO: sanitize print statements
# @section Internal functions {{{1
#
# _libsh_parse {{{2
#
# @description Get arguments for each keyword, place them in the
# proper order and call the correct _libsh_<keyword> function
#
# @arg $1 int    Current line number
# @arg $2 string Keyword to parse
#
_libsh_parse() {
    line="$1"; shift
    keyword="$1"; shift
    error=0

    _libsh_debug "parsing '@$keyword $*'"

    case "$keyword" in
        import) # {{{
            case $# in
                # @import <module>
                1) set "$1" "$1" "" ;;
                # @import <module>   as   <namespace>
                # @import <function> from <module>
                3) case "$2" in
                        as)   set "$1" "$3" "" ;;
                        from) set "$3" "" "$1" ;;
                        *)    error=1 ;;
                    esac ;;
                *) error=1 ;;
            esac
            ;; # }}}
        *) error=1 ;;
    esac

    if [ $error -eq 1 ]; then
        _libsh_error "$line" "$LIBSH_ERR_SYNTAX" "@import $*"
    else
        "_libsh_$keyword" "$line" "$@"
    fi
}

# _libsh_import {{{2
#
# @description Wrapper to easily import lib.sh modules
#
# @arg $1 int    Line number of @import
# @arg $2 string Module to import
# @arg $3 string Namespace to use (optional)
# @arg $4 string Function to import (optional)
#
# @example
#   Import foo into default namespace:
#       _libsh_import <line> foo
#
#   Import foo into bar namespace:
#       _libsh_import <line> foo bar
#
#   Import baz from foo (namespace is ignored)
#       _libsh_import <line> foo "" baz
#
# @global LIBSH Location of 'lib.sh'
#
# @stderr Error messages
#
# @exitcode LIBSH_ERR_FATAL  if requested module is not found
#
_libsh_import() {
    libsh_is_set LIBSH ||
        _libsh_error 0 "$LIBSH_ERR_FATAL" "LIBSH is not defined"

    # TODO: Can I work around needing local?
    local line="$1"; shift
    local module="$1"; shift
    local ns="$1"; shift
    local func="$1"

    if [ -n "$func" ]; then
        _libsh_debug "importing '$func' from '$module'"
    else
        _libsh_debug "importing '$module' into '$ns'"
    fi

    # Check if module has already been sourced
    if [ -z "$(eval echo \$__libsh_"$(libsh_sanitize "$module")"__)" ]; then
        # Set "include guard"
        eval __libsh_"$(libsh_sanitize "$module")"__=1

        # Load the module
        if [ -r "$(dirname "$LIBSH")/$module.sh" ]; then
            _libsh_debug "sourcing '$module'"
            # Sourced file cannot be found by shellcheck
            # shellcheck source=/dev/null
            . "$(dirname "$LIBSH")/$module.sh"
        else
            _libsh_error "$line" "$LIBSH_ERR_FATAL" "could not import '$module'"
        fi
    fi
    # (Re-)load exported functions (to apply proper namespace)
    _libsh_register "$ns" "$module" "$func" "$(eval "echo \$__${module}__")"
}

# _libsh_register {{{2
#
# @description Create namespaced aliases for a list of functions
#
# @arg $1      string Namespace to use
# @arg $2      string Module name
# @arg $3...$n string List of functions to alias
#
_libsh_register() {
    local ns="$1"; shift
    local module="$1"; shift
    local func="$1"; shift
    local functions="$*"

    if [ -n "$func" ]; then
        _libsh_debug "registering '$func' from '$module'"
    else
        _libsh_debug "registering '$module' into '$ns'"
    fi

    # Registering a single function with no namepace
    if [ -n "$func" ]; then
        if [ "${functions#*"$func"}" != "$functions" ]; then
            _libsh_alias "$ns" "$module" "$func"
        else
            _libsh_error 0 "$LIBSH_ERR_FATAL" "$func not found in $module module"
        fi
    # Registering one or more functions with an optional namespace
    else
        # $functions is unquoted in order to properly split by word
        # shellcheck disable=SC2068
        for f in $functions; do
            _libsh_alias "$ns" "$module" "$f"
        done
    fi
}

# _libsh_alias {{{2
#
# @description Create a namespaced alias
#
# @arg $1 string Namespace
# @arg $2 string Module name
# @arg $3 string Alias name
#
_libsh_alias() {
    if [ -n "$1" ]; then
        _libsh_debug "register $1::$3"
        # Unquoted variables in alias are OK
        # shellcheck disable=SC2139
        alias "$1::$3=$2_$3"
    else
        _libsh_debug "register $3"
        # Unquoted variables in alias are OK
        # shellcheck disable=SC2139
        alias "$3=$2_$3"
    fi
}

# _libsh_error {{{2
#
# @description Print lib.sh errors
#
# @arg $1 int    Line number from caller (0 suppresses line number output)
# @arg $2 int    Type of error (see LIBSH_ERR_*)
# @arg $3 string Message to print
#
# @stderr Error messages
#
# @exitcode $2
#
# @see LIBSH_ERR_*
#
_libsh_error() {
    lines=$1; shift
    rc=$1; shift
    msg=$1; shift

    if [ "$lines" = "0" ]; then
        lines=""
    else
        lines="$lines:"
    fi

    case "$rc" in
        "$LIBSH_ERR_FATAL")
            printf "%s:%s fatal error: %s\n" "$0" "$lines" "$msg"
            ;;
        "$LIBSH_ERR_SYNTAX")
            printf "%s:%s syntax error: %s\n" "$0" "$lines" "$msg"
            ;;
        *)
            printf "%s:%s unknown error: %s\n" "$0" "$lines" "$msg"
            ;;
    esac

    if [ "$rc" -eq "$rc" ] 2>/dev/null; then
        exit "$rc"
    else
        exit "$LIBSH_ERR_FATAL"
    fi
} >&2

# _libsh_debug {{{2
#
# @description Output debug messages
#
# @arg $1 string Message to print
#
# @global LIBSH_DEBUG_ON
#
_libsh_debug() {
    libsh_option_on_off "$LIBSH_DEBUG_ON" false &&
        printf "DEBUG: %s\n" "$1"
    return 0
} >&2

# @section Exported functions {{{1
# libsh_option_on_off {{{2
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
libsh_option_on_off() {
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
}

# libsh_is_set {{{2
#
# @description Test if a variable is set or not
#
# @arg $1 string Name of variable to check
#
# @exitcode True if variable is set to anything but ""
# @exitcode False if variable is unset or set to ""
#
libsh_is_set() { eval "test \$$(libsh_sanitize "$1")"; }

# libsh_sanitize {{{2
#
# @description Sanitize input
#
# @arg $1 string String to sanitize
# @arg $2 string Allowed characters (see tr(1))
#
# @stdout Sanitized string
#
libsh_sanitize() {
    if [ -z "$2" ]; then
        allowed="a-zA-Z0-9_"
    fi
    printf "%s" "$1" | tr -cd "$allowed"
}

# Initialization {{{1
#
LIBSH_ERR_FATAL=1
LIBSH_ERR_SYNTAX=2
export LIBSH_ERR_SYNTAX
export LIBSH_ERR_FATAL

_libsh_debug "initialize libsh"

libsh_is_set LIBSH || 
    _libsh_error 0 "$LIBSH_ERR_FATAL" "LIBSH is not defined"

# Bash doesn't expand aliases in non-interactive scripts
if [ -n "$BASH_VERSION" ]; then
    # shopt is only available in Bash
    # shellcheck disable=SC3044
    shopt -qs expand_aliases
fi

# Set "include guard"
__libsh_sourced__=1

# Register keywords
#
if [ -n "$LINENO" ]; then
    alias @import="_libsh_parse \$LINENO import"
else
    alias @import="_libsh_parse ? import"
fi

# Exported functions
#
__libsh__="option_on_off is_set sanitize"

