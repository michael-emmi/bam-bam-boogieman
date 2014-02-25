# c2s -- concurrent-to-sequential code translation

A code-to-code translator for the [Boogie][bpl] language implementing
concurrent to sequential transformations -- so-called "sequentializations",
based on [delay bounding][db], [phase bounding][pb], and other ridiculous
research ideas. These translations generally encode a limited set of program
behaviors by limiting executions to the neighborhood of a particular scheduler;
read [this research paper][db] for more information.

[bpl]: http://boogie.codeplex.com
[db]: http://dl.acm.org/citation.cfm?id=1926432
[pb]: http://link.springer.com/article/10.1007%2Fs10009-013-0276-z

## Requirements

A recent version of [Ruby](https://www.ruby-lang.org) -- I'm using 2.1.0.

## Installation

First build the `c2s` gem with the command,

    gem build c2s.gemspec

which will generate some `c2s-X.Y.Z.gem` file; then install this gem with the
command (obviously substituting `X.Y.Z` with the actual version number),

    gem install c2s-X.Y.Z.gem
    
If you have not used gems before, you may need to add the gem installation path
to your executable path in order to locate c2s; if you've installed Ruby with
[Homebrew](http://brew.sh) like I have, adding the following line to your
`~/.profile` might work.

    export PATH=$PATH:/usr/local/opt/ruby/bin/

Then you can always uninstall with the command

    gem uninstall c2s

## Usage

See the list of possible options with

    c2s-ruby --help

## Author

Please direct all fan mail and hate mail to
[Michael Emmi](michael.emmi@gmail.com).