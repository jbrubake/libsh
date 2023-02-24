#!/bin/dash

LIBSH=/home/jbrubake/src/libsh/libsh.sh
. "$LIBSH" || true

Describe 'libsh.sh' # {{{1
    # Describe '_libsh_debug' # {{{2
    #     It 'tests for output to stderr when LIBSH_DEBUG_ON is set'
    #         LIBSH_DEBUG_ON="y"
    #         When call _libsh_debug "foobar"
    #         The stderr should include "foobar"
    #         The status should be success
    #     End
    #     It 'tests for no output to stderr when LIBSH_DEBUG_ON is not set'
    #         LIBSH_DEBUG_ON="n"
    #         When call _libsh_debug "foobar"
    #         The stderr should equal ""
    #         The status should be success
    #     End
    # End
    # Describe '_libsh_error' # {{{2
    #     Parameters
    #         EFATAL  1
    #         ESYNTAX 2
    #     End
    #     It 'tests proper exit code'
    #         When run _libsh_error "$1" 0 msg
    #         The status should equal "$2"
    #         The lines of stderr should not equal 0
    #     End
    # End
    # Describe '_libsh_alias' # {{{2
    #     alias() { echo alias $1; }

    #     Parameters
    #         ns "::"
    #         "" ""
    #     End
    #     It 'tests _libsh_alias'
    #         When call _libsh_alias "$1" "module" "function"
    #         The stdout should equal "alias $1$2function=module_function"
    #     End
    # End
    # Describe '_libsh_register' # {{{2
    #     _libsh_alias() {
    #         echo "$1 $2 $3"
    #     }

    #     It 'tests registering one function'
    #         When call _libsh_register ns module foo foo bar baz
    #         The lines of stdout should equal 1
    #         The stdout should equal "ns module foo"
    #     End
    #     It 'tests failure when registering a non-existent function'
    #         _libsh_error() { test "$1" = EFATAL && true; }
    #         When run _libsh_register ns module foo bar baz
    #         The status should be successful
    #     End
    #     It 'tests loading multiple functions'
    #         When run _libsh_register ns module "" foo bar baz
    #         The lines of stdout should equal 3
    #         The line 1 of stdout should equal "ns module foo"
    #         The line 2 of stdout should equal "ns module bar"
    #         The line 3 of stdout should equal "ns module baz"
    #     End
    # End
    Describe '_libsh_import' # {{{2
        # TODO: Put the fake module in a test directory
        _libsh_register() { echo "$1 $2 $3 $4"; }

        It 'tests exit if LIBSH not defined'
            _libsh_is_set() { false; }
            _libsh_error() { test "$1" = EFATAL; exit $?; }
            When run _libsh_import 0 0 0 0
            The status should be success
        End
        It 'tests sourcing a module and loading exported functions'
            When call _libsh_import 0 module ns func
            The stdout should equal "ns module func $__module__"
            The variable sourced should be defined
        End
        It 'tests failure on non-existent module'
            _libsh_error() { test "$1" = EFATAL; exit $?; }
            When run _libsh_import 0 NOTAREALMODULE ns func
            The status should be success
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
    # Describe '_libsh_parse @import' # {{{2
    #     _libsh_import () { printf "line=%s module=%s ns=%s func=%s" "$1" "$2" "$3" "$4"; }

    #     It 'tests parsing `@import foo`'
    #         When call _libsh_parse 0 import "foo"
    #         The stdout should equal "line=0 module=foo ns=foo func="
    #     End
    #     It 'tests parsing `@import foo as FOO`'
    #         When call _libsh_parse 0 import foo as FOO
    #         The stdout should equal "line=0 module=foo ns=FOO func="
    #     End
    #     It 'tests parsing `@import foo as ""`'
    #         When call _libsh_parse 0 import foo as ""
    #         The stdout should equal "line=0 module=foo ns= func="
    #     End
    #     It 'tests parsing `@import bar from foo`'
    #         When call _libsh_parse 0 import bar from foo
    #         The stdout should equal "line=0 module=foo ns= func=bar"
    #     End
    #     It 'tests syntax errors in @import'
    #         _libsh_error() { test "$1" = ESYNTAX; exit $?; }
    #         When run _libsh_parse 10 import foo ERROR
    #         The status should be success
    #     End
    #     It 'tests syntax errors in @import'
    #         _libsh_error() { test "$1" = ESYNTAX; exit $?; }
    #         When run _libsh_parse 10 import foo ERROR ERROR
    #         The status should be success
    #     End
    #     It 'tests syntax errors in @import'
    #         _libsh_error() { test "$1" = ESYNTAX; exit $?; }
    #         When run _libsh_parse 10 import foo AS bar
    #         The status should be success
    #     End
    # End
    # Describe '_libsh_parse invalid @keyword' # {{{2
    #     It 'tests an invalid @keyword'
    #         _libsh_error() { test "$1" = ESYNTAX; exit $?; }
    #         When run _libsh_parse 10 INVALID arg1 arg2
    #         The status should be success
    #     End
    # End
End

