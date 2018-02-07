[![Gem Version](https://badge.fury.io/rb/bam-bam-boogieman.svg)](http://badge.fury.io/rb/bam-bam-boogieman)
[![Build Status](https://travis-ci.org/michael-emmi/bam-bam-boogieman.svg?branch=master)](https://travis-ci.org/michael-emmi/bam-bam-boogieman)

# BAM! BAM! Boogieman

BAM! BAM! Boogieman is a Boogie AST Manipulator which implements various code
analyses and transformations for the [Boogie][boogie] intermediate verification
language, including the construction of call graphs and control-flow graphs,
pruning of unreachable code, and various code simplifications. Boogie code is
parsed into an abstract-syntax tree (AST) with an expressive API which
facilitates the creation of new AST passes.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bam-bam-boogieman'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bam-bam-boogieman

## Usage

The `bam` executable expects a single source file and an arbitrary number of
AST passes. See the list of possible options and passes with

    $ bam --help

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

To publish the latest version, use the bump gem…

    $ gem install bump

…and then from the master branch, run the following…

    $ bump patch --tag
    $ git push && git push --tags

…which will trigger publication.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/michael-emmi/bam-bam-boogieman. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the bam-bam-boogieman project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/michael-emmi/bam-bam-boogieman/blob/master/CODE_OF_CONDUCT.md).

[boogie]: https://github.com/boogie-org/boogie
