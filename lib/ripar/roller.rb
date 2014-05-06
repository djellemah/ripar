require "ripar/version"
require 'ripar/combinder.rb'

# Pass in the original chainable object
# method calls in block will be applied
# resulting value will be in riven
class Ripar::Roller < BasicObject
  def initialize( original, &block )
    @original = original
    # clone is for protection of original - not strictly necessary?
    @riven = original.clone
    roll_block( &block ) if block
  end

  class Undispatchable < ::RuntimeError; end

  # Callback from Combinder.
  #
  # This happens when the outside self is_a?(original.class) already,
  # and inside is the roller, which will both respond to the same set
  # of methods. So we want the method calls to go to the roller inside the
  # roller block, otherwise the current value of riven in the roller
  # will end up being constantly reset to original. Which
  # is exactly not the point.
  def __ambiguous_method__( binding_self, meth, *args, &blk )
    # TODO maybe this should just always default to the roller? I don't see much point
    #   in being fancier than that.
    # ::Kernel.puts "__ambiguous_method__ #{meth} for #{binding_self.inspect} and #{@obj.inspect}"
    if binding_self == @original
      # send it to the roller
      send meth, *args, &blk
    else
      # don't know what to do with it
      raise Undispatchable, "don't know how to dispatch #{meth}"
    end
  end

  attr_accessor :riven, :original

  # this is so that we a roller is returned from a
  # call, you can call roller on it again, and keep
  # things rolling along.
  def roller( &block )
    if block
      roll_block &block
    else
      self
    end
  end

  # instantiate the roller, pass it the block and
  # immediately return the modified copy
  def self.rive( original, &block )
    new( original, &block ).riven
  end

  # Forward to riven, let it raise a method missing exception if necessary
  def method_missing(meth, *args, &block)
    @riven = @riven.send( meth, *args, &block )
  end

  # used by combinder, so must be defined, otherwise it perturbs method_missing
  def send( meth, *args, &block )
    method_missing meth, *args, &block
  end

  # used by combinder, so must be defined, otherwise it perturbs method_missing
  # no point in using respond_to_missing?, because that's part of Object#respond_to,
  # not BasicObject
  def respond_to?( meth, include_all = false )
    @riven.respond_to?(meth, include_all) || __methods__.include?(meth)
  end

  # make sure this BasicObject plays nicely in pry
  def inspect
    %Q{#<#{self.__class__} original: #{@original.inspect}, riven: #{@riven.inspect}>}
  end

  def pretty_inspect
    inspect
  end

  def to_s; inspect; end

  # include useful methods from Kernel, but rename
  define_method :__class__, ::Kernel.instance_method(:class)
  define_method :__object_id__, ::Kernel.instance_method(:object_id)

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

private

  def __methods__
    self.__class__.instance_methods
  end
end
