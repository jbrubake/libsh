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
# Import necessary modules {{{1
#
# Import them manually to limit namespace pollution
# (obviously the functions themselves will be there, but they won't be exported
# in the same way as if @import were used)
#
# Sourced file cannot be found by shellcheck
# shellcheck source=/dev/null
. "$(dirname "$LIBSH")/stdlib.sh"
__stdlib_sourced__=1

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
# NOTE: cannot be a sub-shell function because it calls a non-sub-shell function
# NOTE: 'local' is not needed because there are no function calls until this
# function is ready to exit
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
# NOTE: cannot be a sub-shell function because it calls a non-sub-shell function
#
_libsh_import() {
    stdlib_is_set LIBSH ||
        _libsh_error 0 "$LIBSH_ERR_FATAL" "LIBSH is not defined"

    # TODO: Can I work around needing local?
    line="$1"; shift
    module="$1"; shift
    ns="$1"; shift
    func="$1"

    if [ -n "$func" ]; then
        _libsh_debug "importing '$func' from '$module'"
    else
        _libsh_debug "importing '$module' into '$ns'"
    fi

    # Check if module has already been sourced
    if [ -z "$(eval echo \$__"$(stdlib_sanitize "$module")"_sourced__)" ]; then
        # Set "include guard"
        eval __"$(stdlib_sanitize "$module")"_sourced__=1

        # Load the module
        if [ -r "$(dirname "$LIBSH")/$module.sh" ]; then
            _libsh_debug "sourcing '$module'"
            _libsh_var_push line
            _libsh_var_push module
            _libsh_var_push ns
            _libsh_var_push func
            # Sourced file cannot be found by shellcheck
            # shellcheck source=/dev/null
            . "$(dirname "$LIBSH")/$module.sh"
            _libsh_var_pop func
            _libsh_var_pop ns
            _libsh_var_pop module
            _libsh_var_pop line
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
# NOTE: cannot be a sub-shell function because it calls a non-sub-shell function
# NOTE: 'local' is not needed because this function only calls _libsh_alias
# which does not declare variables
#
_libsh_register() {
    ns="$1"; shift
    module="$1"; shift
    func="$1"; shift
    functions="$*"

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
# NOTE: cannot be a sub-shell function because it calls 'alias'
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
_libsh_error() (
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
) >&2

# _libsh_debug {{{2
#
# @description Output debug messages
#
# @arg $1 string Message to print
#
# @global LIBSH_DEBUG_ON
#
_libsh_debug() (
    stdlib_option_on_off "$LIBSH_DEBUG_ON" false &&
        printf "DEBUG: %s\n" "$1"
    return 0
) >&2

# Implement 'local' {{{2
#
# This should not be used unless you *really* need it (which libsh.sh does in
# order to be POSIX compliant)
#
_LIBSH_VARIABLE_STACK_SEP=""
_LIBSH_VARIABLE_STACK=

# Usage: {{{3
#
# - When declaring a variable to be 'local', it *cannot* be combined with
# assignment:
#
#     # OK
#     foo=foo
#     local foo
#
#     # Not OK
#     local foo=foo
#
# - Calls to 'local' **must** be balanced by mirrored calls to '_libsh_var_pop':
#
#     # OK
#     foo=foo
#     bar=bar
#     local foo
#     local bar
#
#     other_func
#
#     _libsh_var_pop bar
#     _libsh_var_pop foo
#
# func_a() {
#   foo=foo
#   bar=bar
#   local foo
#   local bar
#
#   func_b
#
#   _libsh_var_pop bar
#   _libsh_var_pop foo
#
#   echo "foo final = $foo"
#   echo "bar final = $bar"
# }
#
# func_b() {
#   local foo
#   local bar
#   foo=FOO
#   bar=BAR
#
#   echo "foo in func_b = $foo"
#   echo "bar in func_b = $bar"
# }
#
# $ func_a
#   FOO
#   BAR
#   foo
#   bar
#
# _libsh_var_push {{{3
#
# @description Add the value of a variable onto a stack
# The variable can contain any character except for ASCII 0x1F (US)
#
# @arg $1 string Name of variable to push onto the stack
#
# @global _LIBSH_VARIABLE_STACK
# @global _LIBSH_VARIABLE_STACK_SEP
#
_libsh_var_push() {
    eval "v=\$$1"
    _LIBSH_VARIABLE_STACK="$v$_LIBSH_VARIABLE_STACK_SEP$_LIBSH_VARIABLE_STACK"
}

# _libsh_var_pop {{{3
#
# @description Pop a value off the stack and set a variable equal to that value
#
# @arg $1 string Name of variable to pop the value to
#
# @global _LIBSH_VARIABLE_STACK
# @global _LIBSH_VARIABLE_STACK_SEP
#
_libsh_var_pop() {
    v="${_LIBSH_VARIABLE_STACK%%"$_LIBSH_VARIABLE_STACK_SEP"*}"
    _LIBSH_VARIABLE_STACK="${_LIBSH_VARIABLE_STACK#"$v$_LIBSH_VARIABLE_STACK_SEP"}"
    eval "$1=$v"
}

# Initialization {{{1
#
LIBSH_ERR_FATAL=1
LIBSH_ERR_SYNTAX=2
export LIBSH_ERR_SYNTAX
export LIBSH_ERR_FATAL

_libsh_debug "initialize libsh"

stdlib_is_set LIBSH || 
    _libsh_error 0 "$LIBSH_ERR_FATAL" "LIBSH is not defined"

# Bash doesn't expand aliases in non-interactive scripts
if [ -n "$BASH_VERSION" ]; then
    # shopt is only available in Bash
    # shellcheck disable=SC3044
    shopt -qs expand_aliases
fi

# Register keywords
#
if [ -n "$LINENO" ]; then
    alias @import="_libsh_parse \$LINENO import"
else
    alias @import="_libsh_parse ? import"
fi

