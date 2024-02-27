# Quantitative

[![Gem Version](https://badge.fury.io/rb/quantitative.svg)](https://badge.fury.io/rb/quantitative) [![codecov](https://codecov.io/gh/mwlang/quantitative/graph/badge.svg?token=ZXMSKQZKD5)](https://codecov.io/gh/mwlang/quantitative)

STATUS: ALPHA - very early stages!  The framework is very much a work in progress and I am rapidly introducing new things and changing existing things around.

Quantitative is a statistical and quantitative library for Ruby 3.2+ for trading stocks, cryptocurrency, and forex.  It provides a number of classes and modules for working with time-series data, financial data, and other quantitative data.  It is designed to be fast, efficient, and easy to use.

It has been highly optimized for fairly high-frequency trading purely in Ruby (no external numerical/statistical native extensions).  The one exception is that I opted to depend on `Oj` which is a high-performant JSON parser that greatly speeds up serializing data between disk and memory.  In practice, Quantitative is performant enough to trade one minute tickers on down to 30 second ticks for around 100 or so ticker symbols.  Trading anything lower depends on the amount of analysis you're doing and your mileage may vary.  It is possible, but you will find yourself with tradeoffs between the amount of data you can crunch and how fast you can react to live trading situations.

If you're looking to perform high-frequency quantitative trading intervals less than 30 seconds, or 1,000's of tickers concurrently, this library is probably not performant enough for such tasks due solely to Ruby's speed, not to mention that below 5 seconds, you're competing against other automated systems that are responding in the 4 to 10 milliseconds range.

This library is an extraction from an automated trading framework that I use to automate trading on cryptocurrency and stock exchanges.  It does not provide API endpoint functionality for hooking into such.  It is however, a very rich modeling of the space, thus allowing you to easily get started by building a few bridges to turn the payloads the API returns into something you can begin analyzing and generating signals to trade.  Quantitative provides the foundational building blocks to let you easily model ticks, series, intervals, and provides various indicators such as RSI, dominant cycles, band-pass, moving averages, bollinger, donchian, and many more.  Most of the indicators are designed around the concept of a dominant cycle to control the look back periods vs. relying on, say, setting the RSI to 14.

I have ported the majority of this library from Crystal-language, but have not released an open source version for Crystal.  As a strongly-typed language, Crystal can be challenging to work out new designs and refactor rapidly and that led me to port this library to Ruby.  I used the opportunity to rethink many pain-points that I wanted to solve for in the Ruby version with an eye towards eventually rewriting the Crystal version to match.  If you're interested in a Crystal port, let me know.

## Disclaimer

This library is intended for educational and informational purposes only. It is not intended to provide trading or investment advice. Trading cryptocurrency, stocks and forex involves substantial risk of loss and is not suitable for everyone.

The information provided by this library should not be construed as an endorsement, recommendation, or solicitation to buy or sell any security or financial instrument. Users of this library are solely responsible for their own trading decisions and should seek independent financial advice if they have any questions or concerns.

Past performance is not necessarily indicative of future results. By using this library, you agree that the developers and contributors will not be liable for any losses or damages arising from your use of the library. Use at your own risk.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add quantitative

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install quantitative

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mwlang/quantitative. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/mwlang/quantitative/blob/main/CODE_OF_CONDUCT.md).

The Relaxed Ruby Style Guide is adopted for RuboCop.

### Keeping Test Coverage High

TDD/BDD is fully embraced for this project.  If you opt to contribute, please include tests to coverage new features and behavior tests.

RSpec is the test framework. SimpleCov is used for coverage reports.

### Test Driven / Behavior Driven development Coverage Map:

![Coverage Map](https://codecov.io/gh/mwlang/quantitative/graphs/sunburst.svg?token=ZXMSKQZKD5)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Quantitative project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/mwlang/quantitative/blob/main/CODE_OF_CONDUCT.md).
