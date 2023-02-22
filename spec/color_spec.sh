#!/bin/dash

LIBSH=/home/jbrubake/src/libsh/libsh.sh
. "$LIBSH" || true

Describe 'color.sh' # {{{1
    Describe 'terminal does not support color' # {{{2
        tput() { false; }
        Include './color.sh'
        It 'tests that FG does nothing if there is no color support' # {{{
            When call color_FG 1
            The lines of stdout should equal 0
        End # }}}
        It 'tests that BG does nothing if there is no color support' # {{{
            When call color_BG 1
            The lines of stdout should equal 0
        End # }}}
    End
    Describe 'FG and BG handle different number of args properly' # {{{2
        tput() { true; }
        Include './color.sh'
        Parameters
            0 0
            1 1
            2 0
            3 1
            4 0
        End
        It 'tests FG has output or no output depending on number of args'
            When call color_FG $(seq $1)
            The lines of stdout should equal $2
        End
        It 'tests BG has output or no output depending on number of args'
            When call color_BG $(seq $1)
            The lines of stdout should equal $2
        End
    End
End

