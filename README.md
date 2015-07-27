# BAM! BAM! Boogieman

BAM! BAM! Boogieman is a **B**oogie **A**ST **M**anipulator which implements
various code analyses and transformations for the [Boogie][bpl] intermediate
verification language, including the construction of call graphs and
control-flow graphs, pruning of unreachable code, and various code
simplifications. Boogie code is parsed into an abstract-syntax tree (AST) with
an expressive API which facilitates the creation of new AST passes.

[bpl]: http://boogie.codeplex.com

## Requirements

A recent version of [Ruby](https://www.ruby-lang.org) — I’m using 2.2.0 and
I’m guessing you’ll need at least 1.9.

Optionally, you may also fancy:

+ [SMACK][smack], if you want the enable the C/LLVM frontend.
+ [Boogie][boogie], if you want to enable verification.
+ the [`eventmachine`][em] gem, if you want to enable parallelism.
+ the [`colorize`][color] gem, if you want pretty console output.

[color]: https://github.com/fazibear/colorize
[em]: http://rubyeventmachine.com
[boogie]: http://boogie.codeplex.com
[smack]: https://github.com/smackers/smack

## Installation

First build the `bam-bam-boogieman` gem with the command,

    gem build bam-bam-boogieman.gemspec

which will generate some `bam-bam-boogieman-X.Y.Z.gem` file; then install this
gem with the command (substituting `X.Y.Z` with the actual version number),

    gem install bam-bam-boogieman-X.Y.Z.gem

If you have not used gems before, you may need to add the gem installation path
to your executable path in order to locate the `bam` executable; if you’ve
installed Ruby with [Homebrew](http://brew.sh) like I have, adding the following
line to your `~/.profile` might work.

    export PATH=$PATH:/usr/local/opt/ruby/bin/

Then you can always uninstall with the command

    gem uninstall bam-bam-boogieman

## Usage

The `bam` executable expects a single source file and an aribtrary number of
AST passes. See the list of possible options and passes with

    bam --help

## Adding New AST Passes

New AST passes are created by extending the `Bpl::Pass` class. Follow the
examples in `lib/bpl/analysis` and `lib/bpl/transformation` and add your new
pass accordingly.

## Author

Please direct all fan mail and hate mail to
[Michael Emmi](michael.emmi@gmail.com).
