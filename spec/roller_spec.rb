require 'rspec'

require Pathname(__dir__) + '../lib/ripar.rb'

describe Ripar::Roller do
  def collection
    @collection ||= [1,2,3,4,5,6,7,8].tap do |ry|
      class << ry
        def multiply( factor: 2 )
          map{|x| x * factor}
        end

        include Ripar
      end
    end
  end

  # this deliberately doesn't have a ?
  def even( arg )
    arg % 2 == 0
  end

  def seven
    7
  end

  it 'returns an instance immediately' do
    rvs = collection.rive do
      reverse
    end

    rvs.should_not be_respond_to(:__class__)
    rvs.should be_a(Array)
    collection.should == rvs.reverse
  end

  it 'riven returns an instance' do
    rlr = collection.roller
    rlr.riven.should_not be_respond_to(:__class__)
    rlr.riven.should be_a(collection.class)
  end

  it 'pretends to be the original class' do
    rlr = collection.roller
    rlr.should be_a(Array)
  end

  it 'takes a 1 arg block' do
    rlr = collection.roller do |rlr|
      rlr.original.should be_a(Array)
    end
  end

  it 'applies a 1 arg block' do
    evens = collection.rive do |vs|
      vs.select{|x| even(x)}
    end

    evens.should be_a(Array)
    evens.should == [2,4,6,8]
  end

  # And this is the really important one
  it 'takes a 0 arg block' do
    method(:even).should be_a(Method)

    rlr = collection.roller do
      select{|x| even(x)}
    end

    rlr.riven.should be_a(Array)
    rlr.riven.should == [2,4,6,8]
  end

  it 'fails for -1 arity' do
    ->{ collection.roller {|*args|} }.should raise_error(/arity -1/)
  end

  it 'fails for 2 arity' do
    ->{ collection.roller {|arg1,arg2|} }.should raise_error(/arity 2/)
  end

  it 'disambiguates outside variable and inside method call' do
    multiply = 'go forth and'
    rlr = collection.roller do
      __inside__.multiply factor: 3
    end
    rlr.riven.should == collection.multiply( factor: 3 )
  end

  it 'access outside variable when name clashes' do
    reverse = 2
    rlr = collection.roller do
      select{|x| x < reverse }
    end
    rlr.riven.should == [1]
  end

  it '(...) will force inside method call and ignore outside local variable' do
    delete = 'doggone'
    rlr = collection.roller do
      delete(2)
    end
    rlr.riven.should == 2
  end

  it '() will force inside method call' do
    reverse = 'sdrawkcab'

    rlr = collection.roller do
      reverse()
    end
    rlr.riven.should == collection.reverse

    rlr = collection.roller do
      reverse
    end

    rlr.riven.should_not == collection.reverse
  end

  it 'syntax error for outside variable and inside method call in-place hash syntax' do
    multiply = 'go forth and'
    # This will cause a syntax error because the interpreter
    # finds the outside variable, and we're trying to call a method.
    # but only if we're using the in-place hash syntax
    lambda do
      eval <<-EOS
      rlr = collection.roller do
        multiply factor: 3
      end
      EOS
    end.should raise_error(SyntaxError, /unexpected ':'/)
  end

  # counter-case for previous example
  it 'eval outside variable and inside method call in-place hash syntax' do
    multiply = 'go forth and'
    begin
      rlr = collection.roller do
        eval "multiply factor: 3"
      end
    end.riven.should == [3,6,9,12,15,18,21,24]
  end

  it 'in-place hash syntax with name clash ok with (...)' do
    multiply = 'go forth and'
    rlr = collection.roller do
      multiply( factor: 3 )
    end
    rlr.riven.should == [3,6,9,12,15,18,21,24]
  end

  it 'allows explicit access to outside variables' do
    selection = 8
    rlr = collection.roller do
      select{|x| x == __outside__.selection}
    end
    rlr.riven.should == [8]
  end

  it 'allows explicit access to outside methods' do
    rlr = collection.roller do
      select{|x| x == __outside__.seven}
    end
    rlr.riven.should == [7]
  end

  it 'allows variable assignment inside' do
    filter = 'hello'
    rlr = collection.roller do
      irl = __inside__
      irl.map{|x| x-1}
    end
    rlr.riven.should == [0,1,2,3,4,5,6,7]
  end

  it 'can directly call lambdas' do
    fn = ->(x){x + 4}
    rlr = collection.roller do
      select{|x| x < fn(1)}
    end
    rlr.riven.should == [1,2,3,4]
  end

  it 'can directly call outside callables' do
    fn = Object.new.tap do |obj|
      class << obj
        def call(ignored)
          3
        end
      end
    end

    rlr = collection.roller do
      select{|x| x < fn(1)}
    end
    rlr.riven.should == [1,2]
  end

  it 'can access outside lambdas' do
    fn = ->(x){x.odd?}
    rlr = collection.roller do
      select &fn
    end
    rlr.riven.should == [1,3,5,7]
  end

  describe 'ambiguous method' do
    def to_be_duplicated
    end

    it 'handles non-nested ambiguity' do
      class << collection
        def to_be_duplicated
          flat_map{|x| [x,x]}
        end
      end

      ->{collection.roller{ to_be_duplicated }}.should raise_error(Ripar::Roller::Undispatchable)
    end

    it 'handles nested rollers' do
      class << collection
        def square_evens
          roller do
            select &:even?
            map{|x| x ** 2}
          end
        end
      end

      collection.square_evens.riven.should == [4,16,36,64]

      squares_doubled = collection.roller do
        square_evens
        self * 2
      end

      squares_doubled.inspect.should =~ /Roller/
      squares_doubled.riven.should == [4,16,36,64] * 2
      squares_doubled.roller{count}.should == 8

      # TODO this should really be elsewhere
      squares_doubled.riven.should == 8
    end
  end

  describe '#roller' do
    it 'returns self with no block' do
      rlr = collection.roller
      rlr.__class__.should == Ripar::Roller
      rlr.__object_id__.should == rlr.roller.__object_id__
    end
  end

  describe '#inspect' do
    it 'has class name' do
      collection.roller.inspect.should =~ /Ripar::Roller/
    end

    it 'has original' do
      collection.roller.original.should == collection
    end

    it 'has riven' do
      collection.roller.riven.object_id.should_not == collection.object_id
    end
  end

  describe '#respond_to?' do
    it 'forwarded methods' do
      rlr = collection.roller
      rlr.should respond_to(:to_a)
    end

    it 'Roller methods' do
      rlr = collection.roller
      rlr.should respond_to(:riven)
    end

    it 'singleton methods' do
      rlr = collection.roller
      class << rlr
        def bergle; riven end
      end
      rlr.should respond_to(:bergle)
    end
  end
end
