# Ripar [![Gem Version](https://badge.fury.io/rb/ripar.png)](http://badge.fury.io/rb/ripar) [![Build Status](https://travis-ci.org/djellemah/ripar.png?branch=master)](https://travis-ci.org/djellemah/ripar)

Think riparian. Think old man river, he jus' keep on rollin'. Think
[rive](http://etymonline.com/index.php?search=rive). Also river, reaver,
repair, reaper.

Tear chained method calls apart, put them in a block, and return the block value. eg

Before:
``` ruby
  result = values.select{|x| x.name =~ /Jo/}.map{|x| x.count}.inject(0){|s,x| s + x}
```

After:
``` ruby
  result = values.rive do
    select{|x| x.name =~ /Jo/}
    map{|x| x.count}
    inject(0){|s,x| s + x}
  end
```

This is also a little different to instance_eval, because the following will work:

``` ruby
  outside_block_regex = /Wahoody-hey/

  result = values.rive do
    select{|x| x.name =~ outside_block_regex}
    map{|x| x.count}
    inject(0){|s,x| s + x}
  end
```

**Warning** this can have some rare but weird side effects:
  - will probably break on classes that have defined method_missing, but not respond_to_missing
  - an outside variable with the same name as an inside method
    taking in-place hash argument will cause a syntax error.

But you can obviate all of that by just using the safe syntax:

``` ruby
  outside_block_regex = /Wahoody-hey/

  result = values.rive do |vs|
    vs.select{|x| x.name =~ outside_block_regex}
    vs.map{|x| x.count}
    vs.inject(0){|s,x| s + x}
  end
```

Or using the magic disambiguaters:

``` ruby
  select = /Wahoody-hey/

  result = values.rive do
    __inside__.select{|x| x.name =~ __outside__.select}
    map{|x| x.count}
    inject(0){|s,x| s + x}
  end
```

## Installation

Add this line to your application's Gemfile:

    gem 'ripar'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ripar

## Usage

In your class
``` ruby
class YourChainableThing
  include Ripar
end

yct = YourChainableThing.new.rive do
  # operations
end
```

In a singleton
``` ruby
o = Object.new
class << o
  include Ripar
end
```

The mostest lightweightiest
``` ruby
o = Object.new.extend(Ripar)
```

Monkey-patch
``` ruby
class Object
  include Ripar
end
```

## Contributing

The standard github pull request dance:

  1. Fork it ( http://github.com/<my-github-username>/ripar/fork )
  1. Create your feature branch (`git checkout -b my-new-feature`)
  1. Commit your changes (`git commit -am 'Add some feature'`)
  1. Push to the branch (`git push origin my-new-feature`)
  1. Create new Pull Request

## PS
```ruby
Thing = Struct.new :name, :count
values = [
  Thing.new('John', 20),
  Thing.new('Joe', 7),
  Thing.new('Paul', 3),
  Thing.new('James', 3),
  Thing.new('Wahoody-heydi-dude', 3.141527),
]
```
