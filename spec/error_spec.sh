#!/bin/dash

LIBSH=/home/jbrubake/src/libsh/libsh.sh
. "$LIBSH" || true

Describe 'error.sh' # {{{1
    Include './error.sh'
    Describe '_libsh_printf' # {{{2
        It 'tests for ability for format string to start with --'
            When call _error_printf "--%s" "foo"
            The lines of stderr should equal 0
            The stdout should include foo
        End
    End
    Describe '_error_sys_errlist' # {{{2
        Parameters
            EINVAL  0
            FAKEERR 1
        End
        It 'tests for return value of real and unknown errors'
            When call _error_sys_errlist "$1"
            The status should equal "$2"
            The lines of stdout should equal 1
        End
    End
    Describe 'error_strerror' # {{{2
        Parameters
            EINVAL  0 ""
            FAKEERR 1 EINVAL
        End
        errno=""
        It 'tests that strerror properly sets errno'
            When call error_strerror "$1"
            The status should equal "$2"
            The lines of stdout should equal 1
            The variable errno should equal "$3"
        End
    End
    Describe 'error_debug' # {{{2
        It 'tests for output on stderr if DEBUG=y'
            DEBUG=y
            When call error_debug msg
            The lines of stderr should equal 1
        End
        It 'tests for no stderr if DEBUG=n'
            DEBUG=n
            When call error_debug msg
            The lines of stderr should equal 0
        End
    End
    Describe 'error_die' # {{{2
        It 'tests that exit code is correct'
            When run error_die 10
            The status should equal 10
            The lines of stderr should not equal 0
        End
    End
End

