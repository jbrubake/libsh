# Initialization {{{1
#
__net__="has_internet"

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
net_has_internet() {
    url="http://detectportal.firefox.com/success.txt"

    if type wget >/dev/null 2>&1; then
        test "$(wget -q $url --timeout=1 -O -)" = "success"
    elif type curl >/dev/null 2>&1; then
        test "$(curl -s $url)" = "success"
    else
        # $errno looks like it is unused
        # shellcheck disable=SC2034
        errno="ENOENT"
        return 2
    fi

    return $?
}

