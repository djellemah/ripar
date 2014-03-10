require "ripar/version"
require "ripar/roller"

# include this in a class/instance and put the calls that
# would have been chained in the block.
module Ripar
  # return the final value
  # short, unique, unlikely to clash with other methods in Object
  # if you want to monkey-patch.
  def rive( &block )
    Roller.rive self, &block
  end

  # return the roller object containing the final value
  def roller( &block )
    Roller.new self, &block
  end
end
