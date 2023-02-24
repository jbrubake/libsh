#!/bin/dash

LIBSH=/home/jbrubake/src/libsh/libsh.sh
. "$LIBSH" || true

Describe 'stdlib.sh' # {{{1
    Include './stdlib.sh'
    Describe 'stdlib_sanitize' # {{{2
        It 'sanitizes input'
            When call stdlib_sanitize "foobar" ""
            The stdout should equal "foobar"
        End
    End
    Describe 'stdlib_is_set' # {{{2
        Parameters
            TEST_FOO 1  success
            TEST_FOO "" failure
        End
        It 'tests that $1=$1 gives $3'
            eval "$1=$2"
            When call stdlib_is_set "$1"
            The status should be "$3"
        End
    End
    Describe 'stdlib_option_on_off' # {{{2
        Parameters
            # Value is truthy
            1   0     success
            y   0     success
            Y   0     success
            yes 0     success
            Yes 0     success
            YES 0     success
            # Value is falsey
            0   0     failure
            n   0     failure
            N   0     failure
            no  0     failure
            No  0     failure
            NO  0     failure
            # Value is bad and default is True
            foo t     success
            foo true  success
            foo T     success
            foo True  success
            foo TRUE  success
            # Value is bad and default is False
            foo f     failure
            foo false failure
            foo F     failure
            foo False failure
            foo FALSE failure
            # Value is bad and default is bad
            foo foo   success
        End
        It 'tests if $1 is on or off (default of $2)'
            When call stdlib_option_on_off "$1" "$2"
            The status should be "$3"
        End
    End
End

