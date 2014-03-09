# Implements method_missing to figure out which of binding.self and obj can handle the missing method.
# Can have somewhat weird side effect of making variables assigned to lambdas directly callable.
# TODO @binding.eval('self') might define method_missing, so we may actually have to
# attempt to call the method to see if it's missing.
class Ripar::Combinder < BasicObject
  # This should be a refinement
  module BindingNiceness
    def self
      eval('self')
    end

    def local_variables
      eval('local_variables')
    end
  end

  def initialize( obj, saved_binding )
    @obj, @binding = obj, saved_binding
    @binding.extend BindingNiceness
  end

  # long method, but we want to keep BasicObject really empty.
  # TODO could split into private __methods
  def method_missing( meth, *args, &blk )
    if @obj.respond_to?( meth ) && @binding.self.respond_to?( meth )
      begin
        return @obj.__ambiguous_method__( @binding.self, meth, *args, &blk )
      rescue ::NoMethodError => ex
        ::Kernel.raise "method :#{meth} exists on both #{@binding.self.inspect} (outside) and #{@obj.inspect} (inside) #{ex.message}"
      end
    end

    # this is only necessary to do lambda calls with only ()
    # because variables in the binding are already, well, part of the binding.
    if @binding.local_variables.include?( meth )
      bound_value = @binding.eval meth.to_s

      if bound_value.respond_to?( :call )
        # hmm. it's callable. So call it.
        bound_value.call(*args)
      # elsif args.size == 0
      #   # ::Kernel.raise "This should never be called. Should be picked up by ruby interpreter in the binding already"
      #   # just return the value, if it did?
      #   bound_value
      else
        # assume a method on the object needs to be called instead of
        # a variable in the binding
        @obj.send meth, *args, &blk
      end

    elsif @binding.self.respond_to?( meth )
      @binding.self.send meth, *args, &blk
    else
      # dsl method, so call it
      @obj.send meth, *args, &blk
    end
  end

  def respond_to_missing?( meth, include_all )
    return @binding.self.respond_to?( meth ) || @obj.respond_to?( meth )
  end

  # this provides something like a hidden variable that is available to the block
  # for disambiguating outside variables vs method calls, otherwise
  # Ruby interpreter will find the outside variable name, and
  # use that instead of the method call. You could also
  # force the method call with (), but that is sometimes ugly.
  def __inside__
    @obj
  end

  # Forward method calls to bound variables
  # Could probably just use Combinder here.
  # TODO this should be accessing bound_self, right?
  # Variables are accessed anyway by Ruby interpreter because
  # They're in the binding. Not sure.
  class BindingWrapper
    def initialize( wrapped_binding )
      @binding = wrapped_binding
      @binding.extend BindingNiceness
    end

    def method_missing(meth, *args, &blk)
      ::Kernel.raise "outside variables can't take arguments" if args.size != 0

      if @binding.local_variables.include?( meth )
        @binding.eval meth.to_s
      elsif @binding.self.respond_to? meth
        @binding.self.send meth, *args, &blk
      else
        ::Kernel.raise "No such outside variable #{meth}"
      end
    end
  end

  def __outside__
    BindingWrapper.new @binding
  end
end
