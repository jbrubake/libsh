# Usage

To use `lib.sh`, you must define the location of the library, load it and
initialize it. The location of the library should, ideally be set in your shell
startup files:

    LIBSH=<path/to/lib.sh>

Then, place the following at the beginning of any script which is to use
`lib.sh`:

    . "$LIBSH"
    libsh_init [namespace]

If `namespace` is empty, all library-level functions will be imported into the
`libsh::` namespace. If `namespace` is the empty string, all library-level
functions will be imported into the default namespace.

To import a library module, use the following *after* the call to `libsh_init`:

    @import <module> # Import 'module' into the 'module::' namespace
    @import <module> as <namespace> # Import 'module' into the '<namespace>::'
                                    # namespace
    @import <module> as "" # Import 'module' into the default namespace
    @import <function> from <module> # Import 'module::function' into the
                                     # default namespace

# New Keywords

- Import module: `@import <module>`
- Import module into different namespace: `@import <module> as <namespace>`
- Import function from module without namespace: `@import <function> from <module>`

# Module design

- Named `<module>`.sh
- Exported functions must be named `_<module>_<name>` and be listed in
    the variable `__<module>__` without the `_<module>` prefix. This variable
    must be defined in the module *outside* of any function (i.e., it must be
    set when the module is imported

# Style Guide

Item             | Format
----             | ------
Public function  | \_module_<funcname>
Private function | \_\_module_<funcname>
Local variables  | \_<name>
Global variables | LIBSH_<name>

