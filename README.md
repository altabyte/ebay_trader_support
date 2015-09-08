# EbayTraderSupport

**EbayTraderSupport** extends the [ebay-trader](https://github.com/altabyte/ebay_trader) gem to offer a suite of classes 
and command line tools for interacting with the [eBay's Trading API](http://developer.ebay.com/DevZone/XML/docs/Reference/eBay/index.html).

## Caution

This gem is specific to my own business needs and may not be of direct use to your own circumstances. Please consider this 
package as a list of use case scenarios and feel free to copy any features or functionality into your own projects.

I will be adding additional functionality as and when I require it  :-)

## Command line tools

Get the UTC **time** from eBay. This tool serves as a pinger to check availability of the API service.

    $ ebay_time

Display a neatly formatted tree of sub-**categories** for a given parent ID. 
If no parent ID is supplied a list of root categories will be displayed.

```
$ ebay_categories 
    Usage: ebay_categories [options] category_ID
        -a, --all                        Show all root categories.
        -z, --ebay-site-id integer       ID number of the eBay site hosting the categories.
        -h, -?, --help                   Display this screen.
```

Get a list of the **category specifics** for a particular category.

```
$ ebay_category_specifics 
    Usage: ebay_category_specifics [options] category_ID
        -z, --ebay-site-id integer       ID number of the eBay site hosting the categories.
        -h, -?, --help                   Display this screen.
```

Get a CSV or JSON list of active items by a seller.

```
$ ebay_seller_list 
    Usage: ebay_seller_list [options] [ebay_id|sku|quantity|watchers]
  
      Required options:
          -u, --user username              .
      
      Additional options:
          -o, --output format              Output format (CSV or JSON)
          -s, --seller username            The seller eBay username if not me.
          -v, --[no-]verbose               Run verbosely
          -z, --ebay-site-id integer       ID number of the eBay site to receive this instruction.
          -h, -?, --help                   Display this screen.
```

Get a list of all unsold items, which can be filtered by date, re-listed status, 
auction or fixed-price format or end date.
By default it will return a list of eBay item numbers, but it can also display
**sku**, **quantity** and **watchers**.

```
$ ebay_unsold 
    Usage: ebay_unsold [options] [ebay_id|sku|quantity|watchers]
      
      Required options:
          -u, --user username              
      
      Additional options:
          -d, --end-date date              The local-time date on which unsold items ended.
              --[no-]relisted              Relisted items.
              --auction                    Auction items only.
              --fixed-price                Fixed price items only.
          -z, --ebay-site-id integer       ID number of the eBay site to receive this instruction.
          -h, -?, --help                   Display this screen.
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ebay_trader_support', git: 'git://github.com/altabyte/ebay_trader_support'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install https://github.com/altabyte/ebay_trader_support

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/altabyte/ebay_trader_support.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

