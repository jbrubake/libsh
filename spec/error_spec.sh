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
        It 'tests for proper return value for an unknown error'
            When call _error_sys_errlist ENOTREAL
            The status should equal 255
            The lines of stdout should equal 1
        End
    End
    Describe 'error_strerror' # {{{2
        It 'tests that strerror returns EINVAL on an unknown error'
            When call error_strerror ENOTREAL
            The status should equal 22
            The lines of stdout should equal 1
        End
    End
End

