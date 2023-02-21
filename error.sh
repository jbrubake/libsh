@import libsh

# Initialization {{{1
#
# Error codes {{{
#
export EPERM=1
export ENOENT=2
export ESRCH=3
export EINTR=4
export EIO=5
export ENXIO=6
export E2BIG=7
export ENOEXEC=8
export EBADF=9
export ECHILD=10
export EAGAIN=11
export ENOMEM=12
export EACCES=13
export EFAULT=14
export ENOTBLK=15
export EBUSY=16
export EEXIST=17
export EXDEV=18
export ENODEV=19
export ENOTDIR=20
export EISDIR=21
export EINVAL=22
export ENFILE=23
export EMFILE=24
export ENOTTY=25
export ETXTBSY=26
export EFBIG=27
export ENOSPC=28
export ESPIPE=29
export EROFS=30
export EMLINK=31
export EPIPE=32
export EDOM=33
export ERANGE=34
export EDEADLK=35
export ENAMETOOLONG=36
export ENOLCK=37
export ENOSYS=38
export ENOTEMPTY=39
export ELOOP=40
export EWOULDBLOCK=11
export ENOMSG=42
export EIDRM=43
export ECHRNG=44
export EL2NSYNC=45
export EL3HLT=46
export EL3RST=47
export ELNRNG=48
export EUNATCH=49
export ENOCSI=50
export EL2HLT=51
export EBADE=52
export EBADR=53
export EXFULL=54
export ENOANO=55
export EBADRQC=56
export EBADSLT=57
export EDEADLOCK=35
export EBFONT=59
export ENOSTR=60
export ENODATA=61
export ETIME=62
export ENOSR=63
export ENONET=64
export ENOPKG=65
export EREMOTE=66
export ENOLINK=67
export EADV=68
export ESRMNT=69
export ECOMM=70
export EPROTO=71
export EMULTIHOP=72
export EDOTDOT=73
export EBADMSG=74
export EOVERFLOW=75
export ENOTUNIQ=76
export EBADFD=77
export EREMCHG=78
export ELIBACC=79
export ELIBBAD=80
export ELIBSCN=81
export ELIBMAX=82
export ELIBEXEC=83
export EILSEQ=84
export ERESTART=85
export ESTRPIPE=86
export EUSERS=87
export ENOTSOCK=88
export EDESTADDRREQ=89
export EMSGSIZE=90
export EPROTOTYPE=91
export ENOPROTOOPT=92
export EPROTONOSUPPORT=93
export ESOCKTNOSUPPORT=94
export EOPNOTSUPP=95
export EPFNOSUPPORT=96
export EAFNOSUPPORT=97
export EADDRINUSE=98
export EADDRNOTAVAIL=99
export ENETDOWN=100
export ENETUNREACH=101
export ENETRESET=102
export ECONNABORTED=103
export ECONNRESET=104
export ENOBUFS=105
export EISCONN=106
export ENOTCONN=107
export ESHUTDOWN=108
export ETOOMANYREFS=109
export ETIMEDOUT=110
export ECONNREFUSED=111
export EHOSTDOWN=112
export EHOSTUNREACH=113
export EALREADY=114
export EINPROGRESS=115
export ESTALE=116
export EUCLEAN=117
export ENOTNAM=118
export ENAVAIL=119
export EISNAM=120
export EREMOTEIO=121
export EDQUOT=122
export ENOMEDIUM=123
export EMEDIUMTYPE=124
export ECANCELED=125
export ENOKEY=126
export EKEYEXPIRED=127
export EKEYREVOKED=128
export EKEYREJECTED=129
export EOWNERDEAD=130
export ENOTRECOVERABLE=131
export ERFKILL=132
export EHWPOISON=133
# }}}

__error__="perror strerror error error_at_line warn mesg die debug"

# Color support by default
#
# if _libsh_option_on_off "$LIBSH_COLOR" true; then
if libsh::option_on_off "$LIBSH_COLOR" true; then
    @import color
    LIBSH_DEBUG="$(_color_fx dim)"
    LIBSH_MESG=
    LIBSH_WARN="$(_color_fg 220)"
    LIBSH_ERROR="$(_color_fg 160)"
fi

# @section Exported functions {{{1
#
# _error_mesg {{{2
#
# @description Print a message
#
# @global LIBSH_MESG specifies optional coloring
#
# @arg $1  string    printf(1) format string
# @arg ... printf(1) format string parameters
#
# @stderr $1
#
_error_mesg() {
    __error_printf "$LIBSH_MESG" "$@"
}

# _error_warn {{{2
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
_error_warn() {
    fmt="$1"; shift

    __error_printf "$LIBSH_WARN" "$fmt" "$@" >&2
}

# _error_die {{{2
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
_error_die() {
    rc="$1"; shift
    fmt="$1"; shift

    __error_printf "$LIBSH_ERROR" "$fmt" "$@" >&2
    exit "$rc" || return "$rc"
}

# _error_debug {{{2
#
# @description Print a debugging message
#
# @global LIBSH_DEBUG specifies optional coloring
#
# @arg $1  string    printf(1) format string
# @arg ... printf(1) format string parameters
#
# @stderr $1
#
_error_debug() {
    fmt="$1"; shift
    # TODO: Maybe use a _error_{en,dis}able_debug()?
    # if _libsh_option_on_off "$DEBUG" false; then
    if libsh::option_on_off "$DEBUG" false; then
        __error_printf "$LIBSH_DEBUG" "$fmt" "$@" >&2
    else
        :
    fi
}

# _error_error {{{2
#
# @description Print an annotated error message and optionally exit
#
# @arg $1  int       Exit code (ignored if 0)
# @arg $2  errnum    errno value to print message (ignored if 0)
# @arg $4  string    printf(1) format string
# @arg ... printf(1) format string parameters
#
# @stderr $0: $2
#
# @exitcode: $1 if nonzero
#
_error_error() {
    _status="$1"; shift
    _errnum="$1"; shift
    _fmt="$1"; shift
    _msg=

    if [ "$_errnum" -ne 0 ]; then
        _msg=": $(_error_strerror "$_errnum")"
    fi

    __error_printf "$LIBSH_ERROR" "$0: $_fmt$_msg" "$@" >&2

    if [ "$_status" -gt 0 ]; then
        exit "$_status" || return "$_status"
    fi
}

# _error_error_at_line {{{2
#
# @description Print an annotated error message and optionally exit
#
# @arg $1  int       Exit code (ignored if 0)
# @arg $2  errnum    errno value to print message (ignored if 0)
# @arg $2  string    Filename (optional)
# @arg $3  int       Line number of error (optional)
# @arg $4  string    printf(1) format string
# @arg ... printf(1) format string parameters
#
# @stderr $0: $2
#
# @exitcode: $1 if nonzero
#
_error_error_at_line() {
    _status="$1"; shift
    _errnum="$1"; shift
    _file="$1"; shift
    _line="$1"; shift
    _fmt="$1"; shift
    _msg=

    if [ "$_errnum" -ne 0 ]; then
        _msg=": $(_error_strerror "$_errnum")"
    fi

    __error_printf "$LIBSH_ERROR" "$0:$_line:$_file: $_fmt$_msg" "$@" >&2

    if [ "$_status" -gt 0 ]; then
        exit "$_status" || return "$_status"
    fi
}

# _error_perror {{{2
#
# @description Print a message to stderr describing the last error
#
# @arg $1 string Message to prefix the error message with (optional)
#
# @global $errno Current value assumed to describe last error
#
# @stderr $1:<error message> or <error message>
#
_error_perror() {
    if [ -n "$1" ]; then
        printf "%s: %s\n" "$1" "$(__sys_errlist "$errno")" >&2
    else
        printf "%s\n" "$(__sys_errlist "$errno")" >&2
    fi
}

# _error_strerror {{{2
#
# @description Return a string that describes the given error code
#
# @arg $1 int Error code to lookup
#
# @stdout A string describing the error code
#
# @exitcode 1 if $1 is not a valid error code (and set errno=$EINVAL)
#
_error_strerror() {
    if ! __sys_errlist "$1"; then
        errno="$EINVAL"
        return 1
    fi
}

# @section Internal functions {{{1
#
# __error_printf {{{2
#
# @description
#
# @arg $1  string Color formatting (optional)
# @arg $2  string printf(1) format string
# @arg ... printf(1) format string parameters
#
# @stderr $fmt
#
__error_printf() {
    fmt="$1$2"; shift 2

    # shellcheck disable=SC2059
    printf "$fmt[0m\n" "$@"
}

# __sys_errlist {{{2
#
# @description Print the error message associated with a given error code
#
# @arg $1 int Print error message associated with this error code
#
# @exitcode 1 if error code is invalid; 0 otherwise
#
__sys_errlist() {
    case $1 in
        "$EPERM")           echo "Operation not permitted" ;;
        "$ENOENT")          echo "No such file or directory" ;;
        "$ESRCH")           echo "No such process" ;;
        "$EINTR")           echo "Interrupted system call" ;;
        "$EIO")             echo "Input/output error" ;;
        "$ENXIO")           echo "No such device or address" ;;
        "$E2BIG")           echo "Argument list too long" ;;
        "$ENOEXEC")         echo "Exec format error" ;;
        "$EBADF")           echo "Bad file descriptor" ;;
        "$ECHILD")          echo "No child processes" ;;
        "$EAGAIN")          echo "Resource temporarily unavailable" ;;
        "$ENOMEM")          echo "Cannot allocate memory" ;;
        "$EACCES")          echo "Permission denied" ;;
        "$EFAULT")          echo "Bad address" ;;
        "$ENOTBLK")         echo "Block device required" ;;
        "$EBUSY")           echo "Device or resource busy" ;;
        "$EEXIST")          echo "File exists" ;;
        "$EXDEV")           echo "Invalid cross-device link" ;;
        "$ENODEV")          echo "No such device" ;;
        "$ENOTDIR")         echo "Not a directory" ;;
        "$EISDIR")          echo "Is a directory" ;;
        "$EINVAL")          echo "Invalid argument" ;;
        "$ENFILE")          echo "Too many open files in system" ;;
        "$EMFILE")          echo "Too many open files" ;;
        "$ENOTTY")          echo "Inappropriate ioctl for device" ;;
        "$ETXTBSY")         echo "Text file busy" ;;
        "$EFBIG")           echo "File too large" ;;
        "$ENOSPC")          echo "No space left on device" ;;
        "$ESPIPE")          echo "Illegal seek" ;;
        "$EROFS")           echo "Read-only file system" ;;
        "$EMLINK")          echo "Too many links" ;;
        "$EPIPE")           echo "Broken pipe" ;;
        "$EDOM")            echo "Numerical argument out of domain" ;;
        "$ERANGE")          echo "Numerical result out of range" ;;
        "$EDEADLK")         echo "Resource deadlock avoided" ;;
        "$ENAMETOOLONG")    echo "File name too long" ;;
        "$ENOLCK")          echo "No locks available" ;;
        "$ENOSYS")          echo "Function not implemented" ;;
        "$ENOTEMPTY")       echo "Directory not empty" ;;
        "$ELOOP")           echo "Too many levels of symbolic links" ;;
        "$EWOULDBLOCK")     echo "Resource temporarily unavailable" ;;
        "$ENOMSG")          echo "No message of desired type" ;;
        "$EIDRM")           echo "Identifier removed" ;;
        "$ECHRNG")          echo "Channel number out of range" ;;
        "$EL2NSYNC")        echo "Level 2 not synchronized" ;;
        "$EL3HLT")          echo "Level 3 halted" ;;
        "$EL3RST")          echo "Level 3 reset" ;;
        "$ELNRNG")          echo "Link number out of range" ;;
        "$EUNATCH")         echo "Protocol driver not attached" ;;
        "$ENOCSI")          echo "No CSI structure available" ;;
        "$EL2HLT")          echo "Level 2 halted" ;;
        "$EBADE")           echo "Invalid exchange" ;;
        "$EBADR")           echo "Invalid request descriptor" ;;
        "$EXFULL")          echo "Exchange full" ;;
        "$ENOANO")          echo "No anode" ;;
        "$EBADRQC")         echo "Invalid request code" ;;
        "$EBADSLT")         echo "Invalid slot" ;;
        "$EDEADLOCK")       echo "Resource deadlock avoided" ;;
        "$EBFONT")          echo "Bad font file format" ;;
        "$ENOSTR")          echo "Device not a stream" ;;
        "$ENODATA")         echo "No data available" ;;
        "$ETIME")           echo "Timer expired" ;;
        "$ENOSR")           echo "Out of streams resources" ;;
        "$ENONET")          echo "Machine is not on the network" ;;
        "$ENOPKG")          echo "Package not installed" ;;
        "$EREMOTE")         echo "Object is remote" ;;
        "$ENOLINK")         echo "Link has been severed" ;;
        "$EADV")            echo "Advertise error" ;;
        "$ESRMNT")          echo "Srmount error" ;;
        "$ECOMM")           echo "Communication error on send" ;;
        "$EPROTO")          echo "Protocol error" ;;
        "$EMULTIHOP")       echo "Multihop attempted" ;;
        "$EDOTDOT")         echo "RFS specific error" ;;
        "$EBADMSG")         echo "Bad message" ;;
        "$EOVERFLOW")       echo "Value too large for defined data type" ;;
        "$ENOTUNIQ")        echo "Name not unique on network" ;;
        "$EBADFD")          echo "File descriptor in bad state" ;;
        "$EREMCHG")         echo "Remote address changed" ;;
        "$ELIBACC")         echo "Can not access a needed shared library" ;;
        "$ELIBBAD")         echo "Accessing a corrupted shared library" ;;
        "$ELIBSCN")         echo ".lib section in a.out corrupted" ;;
        "$ELIBMAX")         echo "Attempting to link in too many shared libraries" ;;
        "$ELIBEXEC")        echo "Cannot exec a shared library directly" ;;
        "$EILSEQ")          echo "Invalid or incomplete multibyte or wide character" ;;
        "$ERESTART")        echo "Interrupted system call should be restarted" ;;
        "$ESTRPIPE")        echo "Streams pipe error" ;;
        "$EUSERS")          echo "Too many users" ;;
        "$ENOTSOCK")        echo "Socket operation on non-socket" ;;
        "$EDESTADDRREQ")    echo "Destination address required" ;;
        "$EMSGSIZE")        echo "Message too long" ;;
        "$EPROTOTYPE")      echo "Protocol wrong type for socket" ;;
        "$ENOPROTOOPT")     echo "Protocol not available" ;;
        "$EPROTONOSUPPORT") echo "Protocol not supported" ;;
        "$ESOCKTNOSUPPORT") echo "Socket type not supported" ;;
        "$EOPNOTSUPP" | \
        "$ENOTSUP")         echo "Operation not supported" ;;
        "$EPFNOSUPPORT")    echo "Protocol family not supported" ;;
        "$EAFNOSUPPORT")    echo "Address family not supported by protocol" ;;
        "$EADDRINUSE")      echo "Address already in use" ;;
        "$EADDRNOTAVAIL")   echo "Cannot assign requested address" ;;
        "$ENETDOWN")        echo "Network is down" ;;
        "$ENETUNREACH")     echo "Network is unreachable" ;;
        "$ENETRESET")       echo "Network dropped connection on reset" ;;
        "$ECONNABORTED")    echo "Software caused connection abort" ;;
        "$ECONNRESET")      echo "Connection reset by peer" ;;
        "$ENOBUFS")         echo "No buffer space available" ;;
        "$EISCONN")         echo "Transport endpoint is already connected" ;;
        "$ENOTCONN")        echo "Transport endpoint is not connected" ;;
        "$ESHUTDOWN")       echo "Cannot send after transport endpoint shutdown" ;;
        "$ETOOMANYREFS")    echo "Too many references: cannot splice" ;;
        "$ETIMEDOUT")       echo "Connection timed out" ;;
        "$ECONNREFUSED")    echo "Connection refused" ;;
        "$EHOSTDOWN")       echo "Host is down" ;;
        "$EHOSTUNREACH")    echo "No route to host" ;;
        "$EALREADY")        echo "Operation already in progress" ;;
        "$EINPROGRESS")     echo "Operation now in progress" ;;
        "$ESTALE")          echo "Stale file handle" ;;
        "$EUCLEAN")         echo "Structure needs cleaning" ;;
        "$ENOTNAM")         echo "Not a XENIX named type file" ;;
        "$ENAVAIL")         echo "No XENIX semaphores available" ;;
        "$EISNAM")          echo "Is a named type file" ;;
        "$EREMOTEIO")       echo "Remote I/O error" ;;
        "$EDQUOT")          echo "Disk quota exceeded" ;;
        "$ENOMEDIUM")       echo "No medium found" ;;
        "$EMEDIUMTYPE")     echo "Wrong medium type" ;;
        "$ECANCELED")       echo "Operation canceled" ;;
        "$ENOKEY")          echo "Required key not available" ;;
        "$EKEYEXPIRED")     echo "Key has expired" ;;
        "$EKEYREVOKED")     echo "Key has been revoked" ;;
        "$EKEYREJECTED")    echo "Key was rejected by service" ;;
        "$EOWNERDEAD")      echo "Owner died" ;;
        "$ENOTRECOVERABLE") echo "State not recoverable" ;;
        "$ERFKILL")         echo "Operation not possible due to RF-kill" ;;
        "$EHWPOISON")       echo "Memory page has hardware error" ;;
        *)                  echo "Unknown error: $1"; return 1 ;;
    esac
}

