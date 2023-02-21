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
# __libsh_parse {{{2
#
# @description Get arguments for each keyword, place them in the
# proper order and call the correct __libsh_<keyword> function
#
# @arg $1 int    Current line number
# @arg $2 string Keyword to parse
#
__libsh_parse() {
    _line="$1"; shift
    _keyword="$1"; shift
    _error=0

    __libsh_debug "parsing '@$_keyword $*'"

    case "$_keyword" in
        import) # {{{
            case $# in
                # @import <module>
                1) set "$1" "$1" "" ;;
                # @import <module>   as   <namespace>
                # @import <function> from <module>
                3) case "$2" in
                        as)   set "$1" "$3" "" ;;
                        from) set "$3" "" "$1" ;;
                        *)    _error=1 ;;
                    esac ;;
                *) _error=1 ;;
            esac
            ;; # }}}
        keyword) # {{{
            ;; # }}}
        *) _error=1 ;;
    esac

    if [ $_error -eq 1 ]; then
        __libsh_error "$_line" "$LIBSH_ERR_SYNTAX" "@import $*"
    else
        "__libsh_$_keyword" "$_line" "$@"
    fi
}

# __libsh_import {{{2
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
#       __libsh_import <line> foo
#
#   Import foo into bar namespace:
#       __libsh_import <line> foo bar
#
#   Import baz from foo (namespace is ignored)
#       __libsh_import <line> foo "" baz
#
# @global LIBSH Location of 'lib.sh'
#
# @stderr Error messages
#
# @exitcode LIBSH_ERR_FATAL  if requested module is not found
#
__libsh_import() {
    _libsh_is_set LIBSH ||
        __libsh_error 0 "$LIBSH_ERR_FATAL" "LIBSH is not defined"

    # TODO: Can I work around needing local?
    local _line="$1"; shift
    local _module="$1"; shift
    local _ns="$1"; shift
    local _func="$1"

    __libsh_debug "importing '$_module' ($_func) as '$_ns'"

    # Check if module has already been sourced
    if [ -z "$(eval echo \$__libsh_"$(_libsh_sanitize "$_module")"__)" ]; then
        # Set "include guard"
        eval __libsh_"$(_libsh_sanitize "$_module")"__=1

        # Load the module
        if [ -r "$(dirname "$LIBSH")/$_module.sh" ]; then
            __libsh_debug "sourcing '$_module'"
            # shellcheck source=/dev/null
            . "$(dirname "$LIBSH")/$_module.sh"
        else
            __libsh_error "$_line" "$LIBSH_ERR_FATAL" "could not import '$_module'"
        fi
    fi
    # (Re-)load exported functions (to apply proper namespace)
    __libsh_register "$_ns" "$_module" "$_func" "$(eval "echo \$__${_module}__")"
}

# __libsh_register {{{2
#
# @description Create namespaced aliases for a list of functions
#
# @arg $1      string Namespace to use
# @arg $2      string Module name
# @arg $3...$n string List of functions to alias
#
__libsh_register() {
    _ns="$1"; shift
    _module="$1"; shift
    _func="$1"; shift
    _functions="$*"

    # Registering a single function with no namepace
    if [ -n "$_func" ]; then
        __libsh_debug "register $_module::$_func"
        if [ "${_functions#*"$_func"}" != "$_functions" ]; then
            # shellcheck disable=SC2139
            alias "$_func=_${_module}_$_func"
        else
            __libsh_error 0 "$LIBSH_ERR_FATAL" "$_func not found in $_module module"
        fi
    # Registering one or more functions with an optional namespace
    else
        # shellcheck disable=SC2068
        for f in $@; do
            __libsh_debug "register $_module::$f into ns $_ns"
            if [ -n "$_ns" ]; then
                # shellcheck disable=SC2139
                alias "$_ns::$f=_${_module}_$f"
            else
                # shellcheck disable=SC2139
                alias "$f=_${_module}_$f"
            fi
        done
    fi
}

# __libsh_error {{{2
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
__libsh_error() {
    _lines=$1; shift
    _rc=$1; shift
    _msg=$1; shift

    if [ "$_lines" -eq 0 ]; then
        _lines=""
    else
        _lines="$_lines:"
    fi

    case "$_rc" in
        "$LIBSH_ERR_FATAL")
            printf "%s:%s fatal error: %s\n" "$0" "$_lines" "$_msg"
            ;;
        "$LIBSH_ERR_SYNTAX")
            printf "%s:%s syntax error: %s\n" "$0" "$_lines" "$_msg"
            ;;
        *)
            printf "%s:%s unknown error: %s\n" "$0" "$_lines" "$_msg"
            ;;
    esac

    if [ "$_rc" -eq "$_rc" ] 2>/dev/null; then
        exit "$_rc"
    else
        exit "$LIBSH_ERR_FATAL"
    fi
} >&2

# __libsh_debug {{{2
#
# @description Output debug messages
#
# @arg $1 string Message to print
#
# @global LIBSH_DEBUG_ON
#
__libsh_debug() {
    _libsh_option_on_off "$LIBSH_DEBUG_ON" false &&
        printf "DEBUG: %s\n" "$1"
} >&2

# @section Exported functions {{{1
# _libsh_option_on_off {{{2
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
_libsh_option_on_off() {
    case "$1" in
        1 | y | Y | yes | YES | Yes) return 0 ;;
        0 | n | N | no  | NO  | No)  return 1 ;;
        *)
            case "$2" in
                f | false | F | FALSE | False) return 1 ;;
                t | true  | T | TRUE  | True)  return 0 ;;
                *) return 0 ;;
            esac
    esac
}

# _libsh_is_set {{{2
#
# @description Test if a variable is set or not
#
# @arg $1 string Name of variable to check
#
# @exitcode True if variable is set
# @exitcode False if variable is not set
#
_libsh_is_set() { eval "test \$$(_libsh_sanitize "$1")"; }

# _libsh_sanitize {{{2
#
# @description Sanitize input
#
# @arg $1 string String to sanitize
# @arg $2 string Allowed characters (see tr(1))
#
# @stdout Sanitized string
#
_libsh_sanitize() {
    if [ -z "$2" ]; then
        _allowed="a-zA-Z0-9_"
    fi
    printf "%s" "$1" | tr -cd "$_allowed"
}

# Initialization {{{1
#
LIBSH_ERR_FATAL=1
LIBSH_ERR_SYNTAX=2
export LIBSH_ERR_SYNTAX
export LIBSH_ERR_FATAL

__libsh_debug "initialize libsh"

_libsh_is_set LIBSH || 
    __libsh_error 0 "$LIBSH_ERR_FATAL" "LIBSH is not defined"

# Register keywords
#
alias @import="__libsh_parse \$LINENO import"

# Exported functions
#
__libsh__="option_on_off is_set sanitize"

