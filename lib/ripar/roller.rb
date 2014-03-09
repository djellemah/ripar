require "ripar/version"
require 'ripar/combinder.rb'

# Pass in the original chainable object
# method calls in block will be applied
# resulting value will be in riven
class Ripar::Roller < BasicObject
  def initialize( original, &block )
    @original = original
    # clone is for protection or original - not strictly necessary?
    @riven = original.clone
    roll_block( &block ) if block
  end

  # Callback from Combinder.
  #
  # This happens when the outside self is_a?(original.class) already,
  # and inside is the roller, which will both respond to the same set
  # of methods. So we want the method calls to go to the roller inside the
  # roller block, otherwise the current value of the riven in the roller
  # will end up being constantly reset to the starting riven. Which
  # is exactly not the point.
  def __ambiguous_method__( bound_self, meth, *args, &blk )
    # TODO
    # maybe this should just always default to the roller? I don't see much point
    # in being fancier than that.
    if bound_self == @original || bound_self.ancestors.include?( @original.class )
      # send it to the roller
      send meth, *args, &blk
    else
      # send it to the outside block (actually to binding.block.eval('self'))
      # from the POV of inside the roller block.
      bound_self.send meth, *args, &blk
    end
  end

  attr_accessor :riven, :original

  # this is so that we a roller is returned from a
  # call, you can call roller on it again, and keep
  # things rolling along.
  def roller( &block )
    if block
      roll_block( &block ) if block
    else
      self
    end
  end

  # instantiate the roller, pass it the block and
  # immediately return the modified copy
  # TODO duplicate of Ripar#rive
  def self.rive( original, &block )
    instance = new( original, &block )
    instance.riven
  end

  # Forward to riven, if the method exists.
  # If the call to riven results in another instance of original,
  # keep rolling; otherwise just return the value (which breaks the chain).
  # TODO is this chain-breaking really necessary?
  def method_missing(meth, *args, &block)
    if @riven.respond_to? meth
      rv = @riven.send( meth, *args, &block )
      if rv.is_a?( @riven.class )
        @riven = rv
        self
      else
        rv
      end
    else
      super
    end
  end

  # make sure this BasicObject plays nicely in pry
  def inspect
    %Q{#<Ripar::Roller from #{@original.inspect} - #{@riven.inspect}>}
  end

  def pretty_inspect
    inspect
  end

protected

  def roll_block( &block )
    case block.arity
    when 0
      ::Ripar::Combinder.new( self, block.binding ).instance_eval &block
    when 1
      yield self
    else
      ::Kernel.raise "Don't know how to handle arity #{block.arity}"
    end
  end
end
