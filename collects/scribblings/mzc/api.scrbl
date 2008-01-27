#lang scribble/doc

@(require scribble/manual
          scribble/bnf
          (for-label scheme/gui
                     compiler/compiler
                     compiler/sig
                     compiler/compiler-unit
                     compiler/option-unit
                     compiler/comp-unit
                     launcher/launcher))

@title{Scheme API for Compilation}

@defmodule[compiler/compiler]{

The @schememodname[compiler/compiler] library provides the
functionality of @exec{mzc} for compilation to bytecode and via C, but
through a Scheme API.}

@; ----------------------------------------------------------------------

@section[#:tag "api:zo"]{Bytecode Compilation}

@defproc[((compile-zos [expr any/c]) 
          [scheme-files (listof path-string?)]
          [dest-dir (or/c path-string? false/c (one-of/c 'auto))])
         void?]{

Supplying just @scheme[expr] returns a compiler that is initialized
with the expression @scheme[expr], as described below.

The compiler takes a list of Scheme files and compiles each of them to
bytecode, placing the resulting bytecode in a @filepath{.zo} file
within the directory specified by @scheme[dest-dir].  If
@scheme[dest-dir] is @scheme[#f], each bytecode result is placed in
the same directory as its source file.  If @scheme[dest-dir] is
@scheme['auto], each bytecode file is placed in a @filepath{compiled}
subdirectory relative to the source; the directory is created if
necessary.

If @scheme[expr] is anything other than @scheme[#f], then a namespace
is created for compiling the files that are supplied later;
@scheme[expr] is evaluated to initialize the created namespace. For
example, @scheme[expr] might load a set of macros. In addition, the
expansion-time part of each expression later compiled is evaluated in
the namespace before being compiled, so that the effects are visible
when compiling later expressions.

If @scheme[expr] is @scheme[#f], then no compilation namespace is
created, and expressions in the files are assumed to compile
independently (so there's no need to evaluate the expansion-time part
of an expression to compile).

Typically, @scheme[expr] is @scheme[#f] for compiling @scheme[module]
files, and it is @scheme[(void)] for compiling files with top-level
definitions and expressions.}


@defproc[(compile-collection-zos [collection string?] ...+)
         void?]{

Compiles the specified collection's files to @filepath{.zo} files.
The @filepath{.zo} files are placed into the collection's
@filepath{compiled} directory.

The collection compiler reads the collection's @filepath{info.ss} file
(see @secref[#:doc '(lib "scribblings/reference/reference.scrbl")
"info.ss"]) to obtain information about compiling the collection.  The
following fields are used:

@itemize{

 @item{@scheme[name] : The name of the collection as a string.}

 @item{@scheme[compile-omit-files] : A list of filenames (without
       directory paths); all Scheme files in the collection are
       compiled except for the files in this list.  Files that are
       required by other files that are compiled, however, will get
       compiled in the process, even when listed with this field.}

 @item{@scheme[compile-zo-omit-files] - A List of filenames to extend
       the list for @scheme[compile-omit-files]. Historically, this
       list of files was not used for other compilation modes that are
       no longer supported.}

 @item{@scheme[compile-subcollections] : A list of collection paths,
       where each path is a list of
       strings. @scheme[compile-collection-extension] is applied to
       each of the collections.}
}

Only the @scheme[name] field is required from @filepath{info.ss},
since @exec{setup-plt} uses @scheme[name] as an indication that the
collection should be compiled.

The compilation process is driven by @scheme[managed-compile-zo] from
@schememodname[compiler/cm].}


@defproc[(compile-directory-zos [path path-string?] 
                                [info ()])
         void?]{

Like @scheme[compile-collection-zos], but compiles the given directory
rather than a collection. The @scheme[info] function behaves like the
result of @scheme[get-info] to supply @filepath{info.ss} fields,
instead of using an @filepath{info.ss} file (if any) in the directory.}

@; ----------------------------------------------------------------------

@section[#:tag "api:ext"]{Compilation via C}

@defproc[((compile-extensions [expr any/c]) 
          [scheme-files (listof path-string?)]
          [dest-dir (or/c path-string? false/c (one-of/c 'auto))])
         void?]{

Like @scheme[compile-zos], but the @scheme[scheme-files] are compiled
to native-code extensions via C. If @scheme[dest-dir] is
@scheme['auto], each extension file (@filepath{.dll}, @filepath{.so},
or @filepath{.dylib}) is placed in a subdirectory relative to the
source produced by @scheme[(build-path "compiled" "native"
(system-library-subpath))]; the directory is created if necessary.}


@defproc[((compile-extensions-to-c [expr any/c]) 
          [scheme-files (listof path-string?)]
          [dest-dir (or/c path-string? false/c (one-of/c 'auto))])
         void?]{

Like @scheme[compile-extensions], but only @filepath{.c} files are
produced, not extensions.}


@defproc[(compile-c-extensions
          [c-files (listof path-string?)]
          [dest-dir (or/c path-string? false/c (one-of/c 'auto))])
         void?]{

Compiles each @filepath{.c} file (usually produced with
@scheme[compile-extensions-to-c]) in @scheme[c-files] to an
extension. The @scheme[dest-dir] argument is handled as in
@scheme[compile-extensions]. }

@; ----------------------------------------------------------------------

@section[#:tag "api:loading"]{Loading compiler support}

The compiler unit loads certain tools on demand via @scheme[dynamic-require]
and @scheme[get-info]. If the namespace used during compilation is different
from the namespace used to load the compiler, or if other load-related
parameters are set, then the following parameter can be used to
restore settings for @scheme[dynamic-require].

@defparam[current-compiler-dynamic-require-wrapper
          proc 
          ((-> any) . -> . any)]{

A parameter whose value is a procedure that takes a thunk to
apply. The default wrapper sets the current namespace (via
@scheme[parameterize]) before calling the thunk, using the namespace
in which the @scheme[compiler/compiler] library was originally
instantiated.}

@; ----------------------------------------------------------------------

@section[#:tag "api:options"]{Options for the Compiler}

@defmodule[compiler/option]{

The @schememodname[compiler/option] module provides options (in the
form of parameters) that control the compiler's behaviors.}

More options are defined by the @schememodname[dynext/compile] and
@schememodname[dynext/link] libraries, which control the actual C
compiler and linker that are used for compilation via C.

@defboolparam[verbose on?]{

A @scheme[#t] value for the parameter causes the compiler to print
verbose messages about its operations. The default is @scheme[#f].}

@defparam[setup-prefix str string?]{

A parameter that specifies a string to embed in public function names
when compiling via C.  This is used mainly for compiling extensions
with the collection name so that cross-extension conflicts are less
likely in architectures that expose the public names of loaded
extensions. The default is @scheme[""].}

@defboolparam[clean-intermediate-files clean?]{

A @scheme[#f] value for the parameter keeps intermediate @filepath{.c}
and @filepath{.o} files generated during compilation via C. The
default is @scheme[#t].}


@defparam[compile-subcollections cols (or/c (listof (listof string?)) (one-of/c #t))]{

A parameter that specifies sub-collections for
@scheme[compile-collection-zos] to compile. A @scheme[#t] value
indicates that the collection's @filepath{info.ss} should be used, or
that sub-collections should be determined automatically by looking for
sub-directories that contain @filepath{info.ss} files. The default is
@scheme[#t].}


@defboolparam[compile-for-embedded embed?]{

A @scheme[#t] values for this parameter creates @filepath{.c} files
and object files to be linked directly with an embedded PLT Scheme
run-time system, instead of @filepath{.c} files and object files to be
dynamically loaded into PLT Scheme as an extension. The default is
@scheme[#f].}


@defboolparam[propagate-constants prop?]{

A parameter to control the compiler's constant propagating when
compiling via C. The default is @scheme[#t].}


@defboolparam[assume-primitives assume?]{

A @scheme[#t] parameter value effectively adds @scheme[(require
mzscheme)] to the beginning of the program. This parameter is useful
only when compiling non-@scheme[module] code.  The default is
@scheme[#f].}

@defboolparam[stupid allow?]{

A parameter that allow obvious non-syntactic errors, such as
@scheme[((lambda () 0) 1 2 3)], when compiling via C. The default is
@scheme[#f].}

@defparam[vehicles mode symbol?]{

A parameter that controls how closures are compiled via C.  The
possible values are: 

@itemize{

 @item{@scheme['vehicles:automatic] : automatic grouping}

 @item{@scheme['vehicles:functions] : groups within a procedure}

 @item{@scheme['vehicles:monolithic] : groups randomly}

}}

@defparam[vehicles:monoliths count exact-nonnegative-integer?]{

A parameter that determines the number of random
groups for @scheme['vehicles:monolithic] mode.}

@defparam[seed val exact-nonnegative-integer?]{

Sets the randomizer seed for @scheme['vehicles:monolithic] mode.}

@defparam[max-exprs-per-top-level-set n exact-nonnegative-integer?]{

A parameter that determines the number of top-level Scheme expressions
crammed into one C function when compiling via C.  The default is
@scheme[25].}

@defboolparam[unpack-environments unpack?]{

Setting this parameter to @scheme[#f] might help compilation via C
for register-poor architectures.  The default is @scheme[#t].}

@defboolparam[debug on?]{

A @scheme[#t] creates a @filepath{debug.txt} debugging file when
compiling via C.  The default is @scheme[#f].}

@defboolparam[test on?]{

A @scheme[#t] value for this parameter causes compilation via C to
ignore top-level expressions with syntax errors. The default is
@scheme[#f].}

@; ----------------------------------------------------------------------

@section[#:tag "api:unit"]{The Compiler as a Unit}

@; ----------------------------------------

@subsection{Signatures}

@defmodule[compiler/sig]

@defsignature/splice[compiler^ ()]{

Includes all of the names exported by
@schememodname[compiler/compiler].}

@defsignature/splice[compiler:option^ ()]{

Includes all of the names exported by
@schememodname[compiler/option].}


@defsignature[compiler:inner^ ()]{

@signature-desc{The high-level @schememodname[compiler/compiler]
interface relies on a low-level implementation of the extension
compiler, which is available from @schememodname[compiler/comp-unit]
as implementing the @scheme[compiler:inner^] signature.}

@defproc[(eval-compile-prefix [expr any/c]) void?]{

Evaluates @scheme[expr]. Future calls to @sigelem[compiler:inner^
compile-extension] or @sigelem[compiler:inner^ compile-extension-to-c]
see the effects of the evaluation.}

@defproc[(compile-extension [scheme-source path-string?] 
                            [dest-dir path-string?])
         void?]{

Compiles a single Scheme file to an extension.}

@defproc[(compile-extension-to-c [scheme-source path-string?] 
                                 [dest-dir path-string?])
         void?]{

Compiles a single Scheme file to a @filepath{.c} file.}

@defproc[(compile-c-extension [c-source path-string?] 
                              [dest-dir path-string?])
         void?]{

Compiles a single @filepath{.c} file to an extension.}

}

@; ----------------------------------------

@subsection{Main Compiler Unit}

@defmodule[compiler/compiler-unit]

@defthing[compiler@ unit?]{

Provides the exports of @schememodname[compiler/compiler] in unit
form, where C-compiler operations are imports to the unit.

The unit imports @scheme[compiler:option^], @scheme[dynext:compile^],
@scheme[dynext:link^], and @scheme[dynext:file^]. It exports
@scheme[compiler^].}

@; ----------------------------------------

@subsection{Options Unit}

@defmodule[compiler/option-unit]

@defthing[option@ unit?]{

Provides the exports of @schememodname[compiler/option] in unit
form. It imports no signatures, and exports
@scheme[compiler:option^].}

@; ----------------------------------------

@subsection{Compiler Inner Unit}

@defmodule[compiler/comp-unit]

@defthing[comp@ unit?]{

The unit imports @scheme[compiler:option^], @scheme[dynext:compile^],
@scheme[dynext:link^], and @scheme[dynext:file^]. It exports
@scheme[compiler:inner^].}

