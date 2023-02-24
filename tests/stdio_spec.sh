#!/bin/dash

LIBSH=/home/jbrubake/src/libsh/libsh.sh
. "$LIBSH" || true

Describe 'stdio.sh' # {{{1
    Include './stdio.sh'
    Describe 'stdio_debug' # {{{2
        It 'tests for output on stderr if level <= LIBSH_DEBUG_LEVEL'
            LIBSH_DEBUG_LVL=1
            When call stdio_debug 1 msg
            The lines of stderr should equal 1
        End
        It 'tests for output on stderr if level > LIBSH_DEBUG_LEVEL'
            LIBSH_DEBUG_LVL=0
            When call stdio_debug 1 msg
            The lines of stderr should equal 0
        End
    End
    Describe 'stdio_die' # {{{2
        It 'tests that exit code is correct'
            When run stdio_die 10 msg
            The status should equal 10
            The lines of stderr should not equal 0
        End
    End
End

