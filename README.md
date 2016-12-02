# BAM! BAM! Boogieman

BAM! BAM! Boogieman is a Boogie AST Manipulator which implements various code
analyses and transformations for the [Boogie][boogie] intermediate verification
language, including the construction of call graphs and control-flow graphs,
pruning of unreachable code, and various code simplifications. Boogie code is
parsed into an abstract-syntax tree (AST) with an expressive API which
facilitates the creation of new AST passes.


## Installation

Install from Ruby’s package manager:

    $ gem install bam-bam-boogieman

To enable the C/LLVM front end, ensure that [SMACK][smack] is in your executable
path.

To enable the verification back end, ensure that [Boogie][boogie] is in your
executable path.


## Usage

The `bam` executable expects a single source file and an arbitrary number of
AST passes. See the list of possible options and passes with

    $ bam --help


## Development

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/michael-emmi/bam-bam-boogieman. This project is intended to
be a safe, welcoming space for collaboration, and contributors are expected to
adhere to the [Contributor Covenant](http://contributor-covenant.org) code of
conduct.


## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).


[boogie]: https://github.com/boogie-org/boogie
[smack]: https://github.com/smackers/smack
