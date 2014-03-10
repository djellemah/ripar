require 'rspec'

require Pathname(__dir__) + '../lib/ripar.rb'

describe Ripar::Combinder::BindingWrapper do
  describe '#method_missing' do
    def flying_dutchman
      'BigBoat'
    end

    subject do
      unknown_soldier = 'SomeGuy'
      Ripar::Combinder::BindingWrapper.new(binding)
    end

    it 'fails for args' do
      ->{subject.unknown_soldier('hello')}.should raise_error(/can't take arguments/)
    end

    it 'finds local variables' do
      subject.respond_to?(:unknown_soldier).should be_true
      subject.unknown_soldier.should == 'SomeGuy'
      meth = subject.method(:unknown_soldier)
      meth.call.should == 'SomeGuy'
    end

    it 'finds self methods' do
      subject.respond_to?(:flying_dutchman).should be_true
      subject.flying_dutchman.should == 'BigBoat'
      meth = subject.method(:flying_dutchman)
      meth.call.should == 'BigBoat'
    end

    it 'error for not found method/variable' do
      subject.respond_to?(:marie_celeste).should be_false
      ->{subject.marie_celeste}.should raise_error(NoMethodError, /outside/)
      ->{subject.method(:marie_celeste)}.should raise_error(NameError)
    end
  end
end
