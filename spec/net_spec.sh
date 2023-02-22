#!/bin/dash

LIBSH=/home/jbrubake/src/libsh/libsh.sh
. "$LIBSH" || true

Describe 'net.sh' # {{{1
    Include './net.sh'
    Describe 'has_inernet' # {{{2
        It 'tests proper wget call' # {{{
            type() {
                case "$1" in
                    wget) return true ;;
                    *) return false ;;
                esac
            }
            wget() {
                test "$@" = "-q http://detectportal.firefox.com/success.txt --timeout=1 -O -" &&
                    echo "success"
            }
            When call net_has_internet
            The status should be successful
        End # }}}
        It 'tests proper curl call' # {{{
            type() {
                case "$1" in
                    curl) return true ;;
                    *) return false ;;
                esac
            }
            curl() {
                test "$@" = "-s http://detectportal.firefox.com/success.txt" &&
                    echo "success"
            }
            When call net_has_internet
            The status should be successful
        End # }}}
        It 'tests wget call that fails' # {{{
            type() {
                case "$1" in
                    wget) return true ;;
                    *) return false ;;
                esac
            }
            wget() { echo "fail"; }
            When call net_has_internet
            The status should be failure
        End
        It 'tests curl call that fails' # {{{
            type() {
                case "$1" in
                    curl) return true ;;
                    *) return false ;;
                esac
            }
            curl() { echo "fail"; }
            When call net_has_internet
            The status should be failure
        End
        It 'tests error if wget and curl do not exist' # {{{
            type() { return false; }
            When call net_has_internet
            The status should equal 2
            The variable errno should equal ENOENT
        End # }}}
    End
End

