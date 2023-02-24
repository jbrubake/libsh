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
# @file error.sh
# @brief error.sh
#
# @description
#   error.sh description
#
# Initialization {{{1
#
__error__="perror strerror error error_at_line is_error set_error"

# @section Exported functions {{{1
#
# error_error {{{2
#
# @description Print an annotated error message and optionally exit
#
# @arg $1  int       Exit code (ignored if 0)
# @arg $2  string    errno value to print message (ignored if 0)
# @arg $3  string    printf(1) format string
# @arg ... printf(1) format string parameters
#
# @stderr $0: $3: $2
# @stderr $0: $3: <error message>
#
# @exitcode: $1 if nonzero
#
error_error() (
    status="$1"; shift
    errnum="$1"; shift
    fmt="$1"; shift
    msg=

    if [ "$errnum" != "0" ]; then
        msg=": $(error_strerror "$errnum")"
    fi

    _error_printf "$LIBSH_ERROR" "$0: $fmt$msg" "$@" >&2

    if [ "$status" -gt 0 ]; then
        exit "$status" || return "$status"
    fi
)

# error_error_at_line {{{2
#
# @description Print an annotated error message and optionally exit
#
# @arg $1  int       Exit code (ignored if 0)
# @arg $2  string    errno value to print message (ignored if 0)
# @arg $3  string    Filename (optional)
# @arg $4  int       Line number of error (optional)
# @arg $5  string    printf(1) format string
# @arg ... printf(1) format string parameters
#
# @stderr $0:$3:$4: $5: <error message>
#
# @exitcode: $1 if nonzero
#
error_error_at_line() {
    status="$1"; shift
    errnum="$1"; shift
    file="$1"; shift
    line="$1"; shift
    fmt="$1"; shift
    msg=

    if [ "$errnum" != "0" ]; then
        msg=": $(error_strerror "$errnum")"
    fi

    if [ -n "$file" ]; then
        file="$file:"
    fi

    _error_printf "$LIBSH_ERROR" "$0:$file$line: $fmt$msg" "$@" >&2

    if [ "$status" -gt 0 ]; then
        exit "$status" || return "$status"
    fi
}

# error_perror {{{2
#
# @description Print a message to stderr describing the last error
#
# @arg $1 string errno value to print message
# @arg $2 string Message to prefix the error message with (optional)
#
# @stderr $1:<error message> or <error message>
#
error_perror() (
    if [ -n "$2" ]; then
        printf "%s: %s\n" "$2" "$(_error_sys_errlist "$1")" >&2
    else
        printf "%s\n" "$(_error_sys_errlist "$1")" >&2
    fi
)

# error_strerror {{{2
#
# @description Return a string that describes the given error code
#
# @arg $1 string Error code to lookup
#
# @stdout A string describing the error code
#
# @exitcode EINVAL if $1 is not a valid error code
#
# NOTE: Cannot be a sub-shell function because it sets errno
#
error_strerror() {
    _error_sys_errlist "$1"

    if error_is_error NOTREAL; then
        error_set_error EINVAL
    fi
}

# error_is_error {{{2
#
# @description Check if the last error equals the argument
#
# @arg $1 string|int Error to check
#
# @exitcode 0: last error was $1
# @exitcode NOTREAL: last error was not actually an error
# @exitcode last error (in order to check multiple error codes
#
error_is_error() {
    last=$?
    if [ "$last" -eq 0 ]; then
        error_set_error NOTREAL
    else
        error_set_error "$1"
        if [ $? -eq "$last" ]; then
            return 0
        else
            return "$last"
        fi
    fi
}

# error_set_error {{{2
#
# @description Set $? equal to the integer associated with a requested error
#
# @arg string|int Requested error
#
# @exitcode error code associated with $1
#
error_set_error() { _error_sys_errlist "$1" >/dev/null; }

# @section Internal functions {{{1
#
# _error_printf {{{2
#
# @description
#
# @arg $1  string Color formatting (optional)
# @arg $2  string printf(1) format string
# @arg ... printf(1) format string parameters
#
# @stderr $fmt
#
_error_printf() (
    fmt="$1$2"; shift 2

    # Variable in printf format is OK
    # shellcheck disable=SC2059
    printf -- "$fmt[0m\n" "$@" # -- guards against fmt="--..."
)

# _error_sys_errlist {{{2
#
# @description Print the error message associated with a given error code and
#   set $? equal to its value
#
# @arg $1 string|int Error code to print message for
#
# @stdout Error message associated with $1
# @exitcode exit code associated with error; 255 on unknown error
#
_error_sys_errlist() {
    case $1 in
        # - Match both string and integer error code
        # - Print associated error message
        # - Return integer error code
        EPERM           | 1) echo "Operation not permitted";                            return 1   ;;
        ENOENT          | 2) echo "No such file or directory";                          return 2   ;;
        ESRCH           | 3) echo "No such process";                                    return 3   ;;
        EINTR           | 4) echo "Interrupted system call";                            return 4   ;;
        EIO             | 5) echo "Input/output error";                                 return 5   ;;
        ENXIO           | 6) echo "No such device or address";                          return 6   ;;
        E2BIG           | 7) echo "Argument list too long";                             return 7   ;;
        ENOEXEC         | 8) echo "Exec format error";                                  return 8   ;;
        EBADF           | 9) echo "Bad file descriptor";                                return 9   ;;
        ECHILD          | 10) echo "No child processes";                                return 10  ;;
        EAGAIN          | 11) echo "Resource temporarily unavailable";                  return 11  ;;
        ENOMEM          | 12) echo "Cannot allocate memory";                            return 12  ;;
        EACCES          | 13) echo "Permission denied";                                 return 13  ;;
        EFAULT          | 14) echo "Bad address";                                       return 14  ;;
        ENOTBLK         | 15) echo "Block device required";                             return 15  ;;
        EBUSY           | 16) echo "Device or resource busy";                           return 16  ;;
        EEXIST          | 17) echo "File exists";                                       return 17  ;;
        EXDEV           | 18) echo "Invalid cross-device link";                         return 18  ;;
        ENODEV          | 19) echo "No such device";                                    return 19  ;;
        ENOTDIR         | 20) echo "Not a directory";                                   return 20  ;;
        EISDIR          | 21) echo "Is a directory";                                    return 21  ;;
        EINVAL          | 22) echo "Invalid argument";                                  return 22  ;;
        ENFILE          | 23) echo "Too many open files in system";                     return 23  ;;
        EMFILE          | 24) echo "Too many open files";                               return 24  ;;
        ENOTTY          | 25) echo "Inappropriate ioctl for device";                    return 25  ;;
        ETXTBSY         | 26) echo "Text file busy";                                    return 26  ;;
        EFBIG           | 27) echo "File too large";                                    return 27  ;;
        ENOSPC          | 28) echo "No space left on device";                           return 28  ;;
        ESPIPE          | 29) echo "Illegal seek";                                      return 29  ;;
        EROFS           | 30) echo "Read-only file system";                             return 30  ;;
        EMLINK          | 31) echo "Too many links";                                    return 31  ;;
        EPIPE           | 32) echo "Broken pipe";                                       return 32  ;;
        EDOM            | 33) echo "Numerical argument out of domain";                  return 33  ;;
        ERANGE          | 34) echo "Numerical result out of range";                     return 34  ;;
        EDEADLK         | 35) echo "Resource deadlock avoided";                         return 35  ;;
        ENAMETOOLONG    | 36) echo "File name too long";                                return 36  ;;
        ENOLCK          | 37) echo "No locks available";                                return 37  ;;
        ENOSYS          | 38) echo "Function not implemented";                          return 38  ;;
        ENOTEMPTY       | 39) echo "Directory not empty";                               return 39  ;;
        ELOOP           | 40) echo "Too many levels of symbolic links";                 return 40  ;;
        EWOULDBLOCK     | 11) echo "Resource temporarily unavailable";                  return 11  ;;
        ENOMSG          | 42) echo "No message of desired type";                        return 42  ;;
        EIDRM           | 43) echo "Identifier removed";                                return 43  ;;
        ECHRNG          | 44) echo "Channel number out of range";                       return 44  ;;
        EL2NSYNC        | 45) echo "Level 2 not synchronized";                          return 45  ;;
        EL3HLT          | 46) echo "Level 3 halted";                                    return 46  ;;
        EL3RST          | 47) echo "Level 3 reset";                                     return 47  ;;
        ELNRNG          | 48) echo "Link number out of range";                          return 48  ;;
        EUNATCH         | 49) echo "Protocol driver not attached";                      return 49  ;;
        ENOCSI          | 50) echo "No CSI structure available";                        return 50  ;;
        EL2HLT          | 51) echo "Level 2 halted";                                    return 51  ;;
        EBADE           | 52) echo "Invalid exchange";                                  return 52  ;;
        EBADR           | 53) echo "Invalid request descriptor";                        return 53  ;;
        EXFULL          | 54) echo "Exchange full";                                     return 54  ;;
        ENOANO          | 55) echo "No anode";                                          return 55  ;;
        EBADRQC         | 56) echo "Invalid request code";                              return 56  ;;
        EBADSLT         | 57) echo "Invalid slot";                                      return 57  ;;
        EDEADLOCK       | 35) echo "Resource deadlock avoided";                         return 35  ;;
        EBFONT          | 59) echo "Bad font file format";                              return 59  ;;
        ENOSTR          | 60) echo "Device not a stream";                               return 60  ;;
        ENODATA         | 61) echo "No data available";                                 return 61  ;;
        ETIME           | 62) echo "Timer expired";                                     return 62  ;;
        ENOSR           | 63) echo "Out of streams resources";                          return 63  ;;
        ENONET          | 64) echo "Machine is not on the network";                     return 64  ;;
        ENOPKG          | 65) echo "Package not installed";                             return 65  ;;
        EREMOTE         | 66) echo "Object is remote";                                  return 66  ;;
        ENOLINK         | 67) echo "Link has been severed";                             return 67  ;;
        EADV            | 68) echo "Advertise error";                                   return 68  ;;
        ESRMNT          | 69) echo "Srmount error";                                     return 69  ;;
        ECOMM           | 70) echo "Communication error on send";                       return 70  ;;
        EPROTO          | 71) echo "Protocol error";                                    return 71  ;;
        EMULTIHOP       | 72) echo "Multihop attempted";                                return 72  ;;
        EDOTDOT         | 73) echo "RFS specific error";                                return 73  ;;
        EBADMSG         | 74) echo "Bad message";                                       return 74  ;;
        EOVERFLOW       | 75) echo "Value too large for defined data type";             return 75  ;;
        ENOTUNIQ        | 76) echo "Name not unique on network";                        return 76  ;;
        EBADFD          | 77) echo "File descriptor in bad state";                      return 77  ;;
        EREMCHG         | 78) echo "Remote address changed";                            return 78  ;;
        ELIBACC         | 79) echo "Can not access a needed shared library";            return 79  ;;
        ELIBBAD         | 80) echo "Accessing a corrupted shared library";              return 80  ;;
        ELIBSCN         | 81) echo ".lib section in a.out corrupted";                   return 81  ;;
        ELIBMAX         | 82) echo "Attempting to link in too many shared libraries";   return 82  ;;
        ELIBEXEC        | 83) echo "Cannot exec a shared library directly";             return 83  ;;
        EILSEQ          | 84) echo "Invalid or incomplete multibyte or wide character"; return 84  ;;
        ERESTART        | 85) echo "Interrupted system call should be restarted";       return 85  ;;
        ESTRPIPE        | 86) echo "Streams pipe error";                                return 86  ;;
        EUSERS          | 87) echo "Too many users";                                    return 87  ;;
        ENOTSOCK        | 88) echo "Socket operation on non-socket";                    return 88  ;;
        EDESTADDRREQ    | 89) echo "Destination address required";                      return 89  ;;
        EMSGSIZE        | 90) echo "Message too long";                                  return 90  ;;
        EPROTOTYPE      | 91) echo "Protocol wrong type for socket";                    return 91  ;;
        ENOPROTOOPT     | 92) echo "Protocol not available";                            return 92  ;;
        EPROTONOSUPPORT | 93) echo "Protocol not supported";                            return 93  ;;
        ESOCKTNOSUPPORT | 94) echo "Socket type not supported";                         return 94  ;;
        EOPNOTSUPP      | 95) echo "Operation not supported";                           return 95  ;;
        EPFNOSUPPORT    | 96) echo "Protocol family not supported";                     return 96  ;;
        EAFNOSUPPORT    | 97) echo "Address family not supported by protocol";          return 97  ;;
        EADDRINUSE      | 98) echo "Address already in use";                            return 98  ;;
        EADDRNOTAVAIL   | 99) echo "Cannot assign requested address";                   return 99  ;;
        ENETDOWN        | 100) echo "Network is down";                                  return 100 ;;
        ENETUNREACH     | 101) echo "Network is unreachable";                           return 101 ;;
        ENETRESET       | 102) echo "Network dropped connection on reset";              return 102 ;;
        ECONNABORTED    | 103) echo "Software caused connection abort";                 return 103 ;;
        ECONNRESET      | 104) echo "Connection reset by peer";                         return 104 ;;
        ENOBUFS         | 105) echo "No buffer space available";                        return 105 ;;
        EISCONN         | 106) echo "Transport endpoint is already connected";          return 106 ;;
        ENOTCONN        | 107) echo "Transport endpoint is not connected";              return 107 ;;
        ESHUTDOWN       | 108) echo "Cannot send after transport endpoint shutdown";    return 108 ;;
        ETOOMANYREFS    | 109) echo "Too many references: cannot splice";               return 109 ;;
        ETIMEDOUT       | 110) echo "Connection timed out";                             return 110 ;;
        ECONNREFUSED    | 111) echo "Connection refused";                               return 111 ;;
        EHOSTDOWN       | 112) echo "Host is down";                                     return 112 ;;
        EHOSTUNREACH    | 113) echo "No route to host";                                 return 113 ;;
        EALREADY        | 114) echo "Operation already in progress";                    return 114 ;;
        EINPROGRESS     | 115) echo "Operation now in progress";                        return 115 ;;
        ESTALE          | 116) echo "Stale file handle";                                return 116 ;;
        EUCLEAN         | 117) echo "Structure needs cleaning";                         return 117 ;;
        ENOTNAM         | 118) echo "Not a XENIX named type file";                      return 118 ;;
        ENAVAIL         | 119) echo "No XENIX semaphores available";                    return 119 ;;
        EISNAM          | 120) echo "Is a named type file";                             return 120 ;;
        EREMOTEIO       | 121) echo "Remote I/O error";                                 return 121 ;;
        EDQUOT          | 122) echo "Disk quota exceeded";                              return 122 ;;
        ENOMEDIUM       | 123) echo "No medium found";                                  return 123 ;;
        EMEDIUMTYPE     | 124) echo "Wrong medium type";                                return 124 ;;
        ECANCELED       | 125) echo "Operation canceled";                               return 125 ;;
        ENOKEY          | 126) echo "Required key not available";                       return 126 ;;
        EKEYEXPIRED     | 127) echo "Key has expired";                                  return 127 ;;
        EKEYREVOKED     | 128) echo "Key has been revoked";                             return 128 ;;
        EKEYREJECTED    | 129) echo "Key was rejected by service";                      return 129 ;;
        EOWNERDEAD      | 130) echo "Owner died";                                       return 130 ;;
        ENOTRECOVERABLE | 131) echo "State not recoverable";                            return 131 ;;
        ERFKILL         | 132) echo "Operation not possible due to RF-kill";            return 132 ;;
        EHWPOISON       | 133) echo "Memory page has hardware error";                   return 133 ;;
        ENOTSUP         | 95)  echo "Operation not supported";                          return 95  ;;

        ESYNTAX         | 134) echo "Syntax error";                                     return 134 ;;
        EFATAL          | 135) echo "Fatal error";                                      return 135 ;;

        # Everything else is not a real error
        ENOTREAL | *    | 255) echo "Unknown error: $1";                                return 255 ;;
    esac
}

