# Ripar

Think riparian. Think old man river, he jus' keep on rollin'

[rive](http://etymonline.com/index.php?search=rive)

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

Why is this different to instance_eval? Because the following will work:

``` ruby
  outside_block_regex = /Wahoody-hey/

  result = values.rive do
    select{|x| x.name =~ outside_block_regex}
    map{|x| x.count}
    inject(0){|s,x| s + x}
  end
```

**Warning** this can have some rare but weird side effects:
  - will break on classes that have defined method_missing, but not respond_to_missing
  - an outside variable with the same name as an inside method
    taking in-place hash argument will cause a syntax error.

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

yct = YourChainableThing.new.ripar do
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
