# Dist::Zilla::Plugin::AlienBuilder [![Build Status](https://secure.travis-ci.org/plicease/Dist-Zilla-Plugin-AlienBuilder.png)](http://travis-ci.org/plicease/Dist-Zilla-Plugin-AlienBuilder)

use Alien::Builder with Dist::Zilla

# SYNOPSIS

    ; meanwhile, within your dist.ini file:
    [MakeMaker]
    [AlienBuilder]
    name = foo
    retriever_spec.0.pattern = ^foo-1.([0-9]+)\.tar\gz$
    build_commands = %c --prefix=%s
    build_commands = make
    install_commands = make install

# DESCRIPTION

This plugin makes the necessary changes to your `Makefile.PL` to
make it work with [Alien::Builder](https://metacpan.org/pod/Alien::Builder) (it uses [Alien::Builder::MM](https://metacpan.org/pod/Alien::Builder::MM)).
It ONLY works with [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker), to create an [Alien](https://metacpan.org/pod/Alien)
module that works with [Module::Build](https://metacpan.org/pod/Module::Build), see [Dist::Zilla::Plugin::Alien](https://metacpan.org/pod/Dist::Zilla::Plugin::Alien).

# ATTRIBUTES

These attributes are passed directly into the [Alien::Builder::MM](https://metacpan.org/pod/Alien::Builder::MM) constructor:

- arch
- autoconf\_with\_pic
- build\_commands
- build\_dir
- dest\_dir
- extractor
- ffi\_name
- install\_commands
- interpolator
- isolate\_dynamic
- msys
- name
- provides\_cflags
- provides\_libs
- retriever
- retriever\_start
- test\_commands
- version\_check

These attributes require a little more background:

## ab\_class

The builder class to use.  This is [Alien::Builder::MM](https://metacpan.org/pod/Alien::Builder::MM) by
default.  If you want to override some of the behavior then
you can create a subclass and specify it here.  Put the class
in your `inc` directory, which will automatically get
included.

## retriever\_spec

The retriever specification is an array of hashes.  See
the [Alien::Builder](https://metacpan.org/pod/Alien::Builder) documentation for details.  You can
specify elements in this array using the dot `.` character:

    [AlienBuilder]
    retriever_spec.0.pattern = ^foo-(([0-9]+\.)*[0-9]+)$
    retriever_spec.1.pattern = ^foo-(([0-9]+\.)*[0-9]+)\.tar\.gz$

# SEE ALSO

- [Alien](https://metacpan.org/pod/Alien)
- [Alien::Base](https://metacpan.org/pod/Alien::Base)
- [Alien::Builder](https://metacpan.org/pod/Alien::Builder)
- [Alien::Builder::MM](https://metacpan.org/pod/Alien::Builder::MM)
- [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla)
- [Dist::Zilla::Plugin::Alien](https://metacpan.org/pod/Dist::Zilla::Plugin::Alien)

# AUTHOR

Graham Ollis &lt;plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
