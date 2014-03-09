require "ripar/version"
require "ripar/roller"

# include this in a class/instance and put the calls that
# would have been chained in the block.
module Ripar
  # return the final value
  def rive( &block )
    Roller.new( self, &block ).riven
  end

  # return the roller object containing the final value
  def roller( &block )
    Roller.new self, &block
  end
end
