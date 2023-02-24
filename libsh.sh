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
# @section Public functions {{{1
#
# ASSERT {{{2
#
# @description Exit if a test fails
#
# @args ... List of arguments to pass to test(1)
#
# @exitcode: Returns true if the test succeeds, otherwise exits
#
ASSERT() { test "$@" || _libsh_error EFATAL "$LINENO" "ASSERT $*"; }

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
    ASSERT $# -ge 2
    line="$1"; shift
    keyword="$1"; shift
    error=0

    _libsh_debug "parsing '@$keyword $*'"

    case "$keyword" in
        import) # {{{
            case $# in
                # @import <module>
                #  (use basename because <module> can be a path)
                1) set "$1" "$(basename $1)" "" ;;
                # @import <module>   as   <namespace>
                # @import <function> from <module>
                #  (use basename because <module> can be a path)
                3) case "$2" in
                        as)   set "$1" "$(basename $3)" "" ;;
                        from) set "$3" "" "$1" ;;
                        *)    error=1 ;;
                    esac ;;
                *) error=1 ;;
            esac
            ;; # }}}
        *) error=1 ;;
    esac

    if [ $error -eq 1 ]; then
        _libsh_error ESYNTAX "$line" "@import $*"

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
    _libsh_is_set LIBSH ||
        _libsh_error EFATAL "$line" "LIBSH is not defined"

    ASSERT $# -eq 4
    line="$1"; shift
    module="$(_libsh_sanitize "$1")"; shift
    ns="$1"; shift
    func="$1"

    if [ -n "$func" ]; then
        _libsh_debug "importing '$func' from '$module'"
    else
        _libsh_debug "importing '$module' into '$ns'"
    fi

    # Get module path and name
    case "$module" in
        /* | \.*) # Absolute or relative path
            path="$(dirname "$module")"
            module="$(basename "$module")"
            ;;
        *) # Paths that don't start with . or / are resolved
           # relative to the LIBSH install
            path="$(dirname "$LIBSH")/$(dirname "$module")"
            module="$(basename "$module")"
            ;;
    esac

    if [ -r "$path/$module.sh" ]; then
        # Check if module has already been sourced
        if [ -z "$(eval echo "\$__${module}_sourced__")" ]; then
            # Set "include guard"
            eval __${module}_sourced__=1

            # Load the module
            _libsh_debug "sourcing '$module'"
            _libsh_var_push line
            _libsh_var_push module
            _libsh_var_push ns
            _libsh_var_push func

            # Sourced file cannot be found by shellcheck
            # shellcheck source=/dev/null
            . "$path/$module.sh"

            _libsh_var_pop func
            _libsh_var_pop ns
            _libsh_var_pop module
            _libsh_var_pop line
        fi
    else
        _libsh_error EFATAL "$line" "could not import '$module'"
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
    ASSERT $# -ge 3
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
            _libsh_error EFATAL "$line" "'$func' not found in '$module'"
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
    ASSERT $# -eq 3
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


# _libsh_debug {{{2
#
# @description Output debug messages
#
# @arg $1 string Message to print
#
# @global LIBSH_DEBUG_ON
#
_libsh_debug() (
    _libsh_option_on_off "$LIBSH_DEBUG_ON" false &&
        printf "DEBUG: %s\n" "$1"
    return 0
) >&2

# _libsh_error {{{2
#
# @description Print an annotated error message and optionally exit
#
# @arg $1  string    Error code
# @arg $2  int       Line number of error (optional)
# @arg $3  string    Additional error message
#
# @stderr $0:$2: <error message>: $3
#
# @exitcode: $1 if nonzero
#
_libsh_error() {
    ASSERT $# -eq 3
    errnum="$1"; shift
    line="$1"; shift
    msg="$1"; shift

    case "$errnum" in
        EFATAL)  err="Fatal error";  rc=1 ;;
        ESYNTAX) err="Syntax error"; rc=2 ;;
    esac

    printf -- "$0:$line: %s: %s\n" "$err" "$msg" >&2

    exit "$rc" || return "$rc"
}

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
_libsh_option_on_off() (
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

# _libsh_is_set {{{2
#
# @description Test if a variable is set or not
#
# @arg $1 string Name of variable to check
#
# @exitcode True if variable is set to anything but ""
# @exitcode False if variable is unset or set to ""
#
_libsh_is_set() ( eval "test \$$(_libsh_sanitize "$1")"; )

# _libsh_sanitize {{{2
#
# @description Sanitize input. Allowed characters are those that can be in an
#  alphanumeric path
#
# @arg $1 string String to sanitize
#
# @stdout Sanitized string
#
_libsh_sanitize() ( printf "%s" "$1" | tr -cd "a-zA-Z0-9_/."; )
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
# assignment, and must be called *after* a variable has a value:
#
#     # OK
#     foo=foo
#     _libsh_var_push foo
#
#     # Not OK
#     _libsh_var_push foo=foo
#
#     # Not OK
#     _libsh_var_push foo
#     foo=foo
#
# - Calls to '_libsh_var_push' **must** be balanced by mirrored calls to '_libsh_var_pop':
#
#     # OK
#     foo=foo
#     bar=bar
#     _libsh_var_push foo
#     _libsh_var_push bar
#
#     other_func
#
#     _libsh_var_pop bar
#     _libsh_var_pop foo
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
    ASSERT -n "$1"
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
    ASSERT -n "$1"
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

_libsh_is_set LIBSH || 
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

