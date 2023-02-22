#!/bin/dash

LIBSH=/home/jbrubake/src/libsh/libsh.sh
. "$LIBSH" || true

Describe 'libsh.sh' # {{{1
    Describe '_libsh_debug' # {{{2
        It 'tests for output to stderr when LIBSH_DEBUG_ON is set'
            LIBSH_DEBUG_ON="y"
            When call _libsh_debug "foobar"
            The stderr should include "foobar"
            The status should be success
        End
        It 'tests for no output to stderr when LIBSH_DEBUG_ON is not set'
            LIBSH_DEBUG_ON="n"
            When call _libsh_debug "foobar"
            The stderr should equal ""
            The status should be success
        End
    End
    Describe '_libsh_error' # {{{2
        Parameters
            "$LIBSH_ERR_FATAL"  "$LIBSH_ERR_FATAL"  "fatal error"
            "$LIBSH_ERR_SYNTAX" "$LIBSH_ERR_SYNTAX" "syntax error"
            10                  10                  "unknown error"
            foobar              "$LIBSH_ERR_FATAL"  "unknown error"
        End
        It 'tests proper exit code'
            When run _libsh_error 0 "$1" "msg"
            The status should equal "$2"
            The stderr should include "$3"
        End
    End
    Describe '_libsh_error' # {{{2
        Parameters
            0 ""
            1 "1:"
        End
        It 'tests line number supression'
            When run _libsh_error "$1" "$LIBSH_ERR_FATAL" "msg"
            The stderr should equal "$0:$2 fatal error: msg"
            The status should equal "$LIBSH_ERR_FATAL"
        End
    End
    Describe '_libsh_alias' # {{{2
        alias() { echo alias $1; }

        Parameters
            ns "::"
            "" ""
        End
        It 'tests _libsh_alias'
            When call _libsh_alias "$1" "module" "function"
            The stdout should equal "alias $1$2function=module_function"
        End
    End
    Describe '_libsh_register' # {{{2
        _libsh_alias() {
            echo "$1 $2 $3"
        }

        It 'tests registering one function'
            When call _libsh_register ns module foo foo bar baz
            The lines of stdout should equal 1
            The stdout should equal "ns module foo"
        End
        It 'tests failure when registering a non-existent function'
            When run _libsh_register ns module foo bar baz
            The status should equal "$LIBSH_ERR_FATAL"
            The stderr should include "fatal error"
        End
        It 'tests loading multiple functions'
            When run _libsh_register ns module "" foo bar baz
            The lines of stdout should equal 3
            The line 1 of stdout should equal "ns module foo"
            The line 2 of stdout should equal "ns module bar"
            The line 3 of stdout should equal "ns module baz"
        End
    End
    Describe '_libsh_import' # {{{2
        # TODO: Put the fake module in a test directory
        _libsh_register() { echo "$1 $2 $3 $4"; }

        _libsh_error() { exit $2; }

        It 'tests exit if LIBSH not defined'
            stdlib_is_set() { false; }
            When run _libsh_import 0 0 0 0
            The status should equal "$LIBSH_ERR_FATAL"
            The status should equal "$LIBSH_ERR_FATAL"
        End
        It 'tests failure on non-existent module'
            When run _libsh_import 0 NOT_A_REAL_MODULE ns func
            The status should equal "$LIBSH_ERR_FATAL"
        End
        It 'tests sourcing a module and loading exported functions'
            When call _libsh_import 0 module ns func
            The stdout should equal "ns module func $__module__"
            The variable sourced should be defined
        End

        double_source() {
            # import once and discard output
            _libsh_import "$1" "$2" "$3" "$4" >/dev/null
            # unset the sourcing flag variable
            unset sourced
            # import again which should *not* set the flag
            # variable. Keep the output to verify that
            # exported functions are re-loaded
            _libsh_import "$1" "$2" "$3" "$4"
        }

        It 'tests re-loading exported functions'
            When call double_source 0 module ns func
            The stdout should equal "ns module func $__module__"
            The variable sourced should be undefined
        End
    End
    Describe '_libsh_parse @import' # {{{2
        _libsh_import () { printf "line=%s module=%s ns=%s func=%s" "$1" "$2" "$3" "$4"; }

        It 'tests parsing `@import foo`'
            When call _libsh_parse 0 import "foo"
            The stdout should equal "line=0 module=foo ns=foo func="
        End
        It 'tests parsing `@import foo as FOO`'
            When call _libsh_parse 0 import foo as FOO
            The stdout should equal "line=0 module=foo ns=FOO func="
        End
        It 'tests parsing `@import foo as ""`'
            When call _libsh_parse 0 import foo as ""
            The stdout should equal "line=0 module=foo ns= func="
        End
        It 'tests parsing `@import bar from foo`'
            When call _libsh_parse 0 import bar from foo
            The stdout should equal "line=0 module=foo ns= func=bar"
        End
        It 'tests syntax errors in @import'
            When run _libsh_parse 10 import foo ERROR
            The status should equal "$LIBSH_ERR_SYNTAX"
            The stderr should include "syntax error"
        End
        It 'tests syntax errors in @import'
            When run _libsh_parse 10 import foo ERROR ERROR
            The status should equal "$LIBSH_ERR_SYNTAX"
            The stderr should include "syntax error"
        End
        It 'tests syntax errors in @import'
            When run _libsh_parse 10 import foo AS bar
            The status should equal "$LIBSH_ERR_SYNTAX"
            The stderr should include "syntax error"
        End
    End
    Describe '_libsh_parse invalid @keyword' # {{{2
        It 'tests an invalid @keyword'
            When run _libsh_parse 10 INVALID arg1 arg2
            The status should equal "$LIBSH_ERR_SYNTAX"
            The stderr should include "syntax error"
        End
    End
End

