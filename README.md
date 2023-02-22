# Usage

To use `libsh`, you must define the location of the library and load it.  The
location of the library should, ideally be set in your shell startup files:

    LIBSH=<path/to/lib.sh>

Then, place the following at the beginning of any script which is to use
`libsh`:

    . "$LIBSH"

To import a library module, use any of the following *after* the library is
loaded:

```sh
    # Import 'module' into the 'module::' namespace
    @import <module>

    # Import 'module' into the '<namespace>::' namespace
    @import <module> as <namespace>

    # Import 'module' into the default namespace
    @import <module> as ""

    # Import 'module::function' into the default namespace
    @import <function> from <module>
```

## Limitations

Due to how shell scripts are parsed and interpreted, exported functions cannot
be called in the same 'block' as their associated `@import`. As an example, see
the following (slightly modified) from the `error` module:

```sh
    # error.sh
    if [ "$COLOR" = "yes" ]; then
        @import color
    fi
    if [ "$COLOR" = "yes" ]; then
        LIBSH_DEBUG="$(color::FX dim)"
        LIBSH_WARN="$(color::FG 220)"
        ...
    fi
```

The calls to `color::FX` and `color::FG` do not work properly if they are
contained within the first `if` block where the `color` module is imported. In
general, just don't call `@import` anywhere but at the outer-level of a file. If
you do anything else, be prepared for a little weirdness.

# Development

## Module design

- Named `<module>`.sh
- Exported functions must be named `_<module>_<name>` and be listed in
    the variable `__<module>__` without the `_<module>` prefix. This variable
    must be defined in the module *outside* of any function (i.e., it must be
    set when the module is imported
- `foo` module example:

```sh
    # foo.sh
    __foo_="bar baz"

    _foo_bar () {
        ...
    }

    _foo_baz () {
        ...
    }
```

## Style Guide

Item             | Format
----             | ------
Public function  | module_<funcname>
Private function | \_module_<funcname>
Global variables | LIBSH_<name>

