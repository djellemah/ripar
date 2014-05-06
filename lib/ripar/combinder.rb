# This is the part that lets an instance_eval-style block access
# variables defined outside of it. Arguably that's a horrible idea, really.
#
# Implements method_missing to figure out which of binding.self and obj can handle the missing method.
# Can have somewhat weird side effect of making variables assigned to lambdas (or anything
# implementing call actually) directly callable.
#
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

  class AmbiguousMethod < ::RuntimeError; end

  # long method, but we want to keep BasicObject really empty.
  # TODO could split into private __methods
  def method_missing( meth, *args, &blk )
    if @obj.respond_to?( meth ) && (@binding.self.methods - ::Object.instance_methods).include?( meth )
      begin
        return @obj.__ambiguous_method__( @binding.self, meth, *args, &blk )
      rescue ::NoMethodError => ex
        unless ::Object::RUBY_VERSION == '2.0.0'
          # for some reason, any references to ex.message fail here for 2.0.0
          # so only for other versions just double-check versions that it was in fact caused by __ambiguous_method__
          # otherwise just raise whatever was missing.
          ::Kernel.raise unless ex.message =~ /__ambiguous_method__/
        end
        ::Kernel.raise AmbiguousMethod, "method :#{meth} exists on both #{@binding.self.inspect} (outside) and #{@obj.inspect} (inside)", ex.backtrace[3..-1]
      end
    end

    if @binding.local_variables.include?( meth )
    # This branch is only necessary to do lambda calls with (),
    # because variables in the binding are already, well, part of the binding.
    # So they are picked up before the code ever calls method_missing
      bound_value = @binding.eval meth.to_s

      if bound_value.respond_to?( :call )
        # It's a local variable, but it's been forced to come here by (). So call it.
        bound_value.call(*args)
      else
        # assume that the user really wants to call the object's method
        # rather than access the outside variable.
        @obj.send meth, *args, &blk
      end
    elsif @binding.self.respond_to?( meth )
      @binding.self.send meth, *args, &blk
    else
      @obj.send meth, *args, &blk
    end
  end

  def respond_to?( meth, include_all = false )
    # ::Kernel.puts "Combinder#respond_to #{meth}"
    # ::Kernel.puts "Combinder local variables #{@binding.local_variables}"
    return @binding.local_variables.include?( meth ) || @binding.self.respond_to?( meth, include_all ) || @obj.respond_to?( meth, include_all )
  end

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
        ::Kernel.raise NoMethodError, "No such outside variable #{meth}"
      end
    end

    def respond_to_missing?( meth, include_all = false )
      @binding.local_variables.include?(meth) || @binding.self.respond_to?(meth, include_all)
    end
  end

  # access the outside of the block, ie its binding.
  def __outside__
    BindingWrapper.new @binding
  end
end
