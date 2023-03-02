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
# @file stdio.sh
# @brief stdio.sh
#
# @description
#   stdio.sh description
#
# Initialization {{{1
#
@import stdlib

__stdio__="warn mesg die debug"

# Color support by default
#
if stdlib::option_on_off "$LIBSH_COLOR" true; then
    @import color
fi
if stdlib::option_on_off "$LIBSH_COLOR" true; then
    LIBSH_DEBUG="$(color::FX dim)"
    LIBSH_MESG=
    LIBSH_WARN="$(color::FG 220)"
    LIBSH_ERROR="$(color::FG 160)"
fi

# @section Exported functions {{{1
#
# stdio_mesg {{{2
#
# @description Print a message
#
# @global LIBSH_MESG specifies optional coloring
#
# @arg $1  int       Verbosity level
# @arg $2  string    printf(1) format string
# @arg ... printf(1) format string parameters
#
# @stderr $1
#
stdio_mesg() (
    ASSERT $# -ge 1
    v="$1"; shift
    test "$v" -gt "${LIBSH_VERBOSE_LVL:-0}" && return
    _stdio_printf "$LIBSH_MESG" "$@"
)

# stdio_warn {{{2
#
# @description Print a warning message
#
# @global LIBSH_WARN specifies optional coloring
#
# @arg $1  string    printf(1) format string
# @arg ... printf(1) format string parameters
#
# @stderr $1
#
stdio_warn() (
    ASSERT $# -ge 1
    fmt="$1"; shift

    _stdio_printf "$LIBSH_WARN" "$fmt" "$@" >&2
)

# stdio_die {{{2
#
# @description Print an error message and exit
#
# @global LIBSH_ERROR specifies optional coloring
#
# @arg $1  int       Exit code
# @arg $2  string    printf(1) format string
# @arg ... printf(1) format string parameters
#
# @stderr $1
#
stdio_die() {
    ASSERT $# -ge 2
    rc="$1"; shift
    fmt="$1"; shift

    _stdio_printf "$LIBSH_ERROR" "$fmt" "$@" >&2
    exit "$rc" || return "$rc"
}

# stdio_debug {{{2
#
# @description Print a debugging message
#
# @global LIBSH_DEBUG specifies optional coloring
# @global LIBSH_DEBUG_LVL suppress output if $1 is > LIBSH_DEBUG_LVL
#
# @arg $1  int       Debug level
# @arg $2  string    printf(1) format string
# @arg ... printf(1) format string parameters
#
# @stderr $1
#
stdio_debug() (
    ASSERT $# -ge 2
    d="$1"; shift
    fmt="$1"; shift

    test "$d" -gt "${LIBSH_DEBUG_LVL:-0}" && return

    _stdio_printf "$LIBSH_DEBUG" "$fmt" "$@" >&2

    return 0
)

# @section Internal functions {{{1
#
# _stdio_printf {{{2
#
# @description
#
# @arg $1  string Color formatting (optional)
# @arg $2  string printf(1) format string
# @arg ... printf(1) format string parameters
#
# @stderr $fmt
#
_stdio_printf() (
    ASSERT $# -ge 2
    fmt="$1$2"; shift 2

    # Variable in printf format is OK
    # shellcheck disable=SC2059
    printf -- "$fmt[0m\n" "$@" # -- guards against fmt="--..."
)

