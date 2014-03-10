require 'rspec'

require Pathname(__dir__) + '../lib/ripar.rb'

describe Ripar::Combinder do
  def an_object
    @an_object ||= Object.new.tap do |obj|
      class << obj
        def flying_dutchman
          'BigBoat'
        end

        def oops
          'dead mudokons'
        end
      end
    end
  end

  # otherwise rspec tries to create a Combinder and fails
  subject{}

  # Yes, you really have to set up combinder in example,
  # so you can get the binding

  describe 'ambiguous method' do
    def oops
      'more dead mudokons'
    end

    it 'raise on ambiguous method' do
      combinder = Ripar::Combinder.new(an_object, binding)
      ->{combinder.instance_eval{ oops }}.should raise_error(Ripar::Combinder::AmbiguousMethod, /exists on both/)
    end

    it 'callback on ambiguous method' do
      an_object.stub :__ambiguous_method__ do |binding_self, meth, *args|
        binding_self.object_id.should == self.object_id
        meth.should == :oops
        args.should == []
      end

      Ripar::Combinder.new(an_object, binding).instance_eval{oops}
    end
  end

  describe 'local variables' do
    it 'gets value' do
      unknown_soldier = 'SomeGuy'
      combinder = Ripar::Combinder.new(an_object, binding)
      combinder.instance_eval{ unknown_soldier }.should == 'SomeGuy'
    end

    it 'respond_to as methods' do
      unknown_soldier = 'SomeGuy'
      combinder = Ripar::Combinder.new(an_object, binding)
      combinder.instance_eval{ respond_to? :unknown_soldier }.should be_true
    end

    it 'respond_to local variables as methods' do
      unknown_soldier = 'SomeGuy'
      combinder = Ripar::Combinder.new(an_object, binding)

      combinder.instance_eval do
        respond_to?(:unknown_soldier)
      end.should be_true
    end

    it 'use respond_to_missing via method()' do
      unknown_soldier = 'SomeGuy'
      combinder = Ripar::Combinder.new(an_object, binding)

      combinder.instance_eval do
        meth = __outside__.method(:unknown_soldier)
        meth.call
      end.should == 'SomeGuy'
    end

    it 'force to inside method call with ()' do
      flying_dutchman ='LovesCheese'

      combinder = Ripar::Combinder.new(an_object, binding)

      # this is the local variable, above
      combinder.instance_eval{ flying_dutchman }.should == 'LovesCheese'

      # this is the method call on an_object
      combinder.instance_eval{ flying_dutchman() }.should == 'BigBoat'
    end
  end

  describe 'self methods' do
    it 'finds them' do
      combinder = Ripar::Combinder.new(an_object, binding)
      combinder.instance_eval{ respond_to?(:flying_dutchman) }.should be_true
      combinder.instance_eval{ flying_dutchman }.should == 'BigBoat'
    end

    it 'method() works' do
      pending "this is hard to support. not sure if it's even necessary"
      combinder.instance_eval{ method(:flying_dutchman) }.call.should == 'BigBoat'
    end
  end

  describe 'binding self methods' do
    def hero
      'missing, presumed dead'
    end

    it 'finds them' do
      combinder = Ripar::Combinder.new(an_object, binding)
      combinder.instance_eval{ respond_to?(:hero) }.should be_true
      combinder.instance_eval{ hero }.should == 'missing, presumed dead'
    end
  end

  describe 'non-existent variables/methods' do
    it 'error for not found method/variable' do
      combinder = Ripar::Combinder.new(an_object, binding)
      combinder.instance_eval{subject.respond_to?(:marie_celeste)}.should be_false

      lambda do
        combinder.instance_eval{marie_celeste}
      end.should raise_error(NoMethodError)
    end

    it 'method for not found method/variable' do
      pending 'ditto'
      combinder.instance_eval do
        ->{method(:marie_celeste)}.should raise_error(NameError)
      end
    end
  end

  describe '() for .call' do
    it 'calls lambda' do
      fn = ->(val){"#{val}, where are you?"}

      combinder = Ripar::Combinder.new(an_object, binding)
      combinder.instance_eval{fn(oops)}.should == 'dead mudokons, where are you?'
    end

    it 'calls #call' do
      obj = Object.new
      class << obj
        def call( finagle )
          finagle * 2
        end
      end

      combinder = Ripar::Combinder.new(an_object, binding)
      combinder.instance_eval{obj(oops)}.should == 'dead mudokonsdead mudokons'
    end
  end

  describe '#__inside__' do
    it 'allows access to inside method' do
      combinder = Ripar::Combinder.new(an_object, binding)
      combinder.instance_eval{__inside__}.should == an_object
    end
  end
end

