# frozen_string_literal: true
require 'spec_helper'

RSpec.describe MethodObject do
  def define_method_object(*args, class_name: nil, base_class: MethodObject, &block)
    Class.new(base_class).tap do |klazz|
      klazz.class_exec(*args, &block)
      stub_const(class_name, klazz) if class_name
    end
  end

  subject { method_object_class }

  let(:execution_spy) { instance_double('Proc', call: nil) }
  let(:method_object_class) do
    define_method_object(execution_spy) do |passed_execution_spy|
      parameter :required_parameter, String
      parameter :with_default, Integer, default: 0
      parameter :with_dynamic_default, Integer, default: -> { @var = @var ? @var + 1 : 0 }

      called do
        passed_execution_spy.call(required_parameter)
      end
    end
  end

  describe '.parameter' do
    let(:method_object_class) do
      define_method_object do
        parameter :foo, String
      end
    end

    it 'is protected' do
      expect { subject.parameter }.to raise_error(NoMethodError)
    end

    describe 'parameter' do
      subject { method_object_class.new }

      describe '#`parameter_name`' do
        it { is_expected.to respond_to(:foo) }
      end

      describe '#`parameter_name`=' do
        it { is_expected.to respond_to(:foo=) }

        it 'checks data type' do
          expect { subject.foo = 'some string' }.not_to raise_error
          expect { subject.foo = 123 }.to raise_error(ArgumentError, /Expected a String for foo/)
        end
      end

      describe '#`parameter_name`?' do
        it { is_expected.to respond_to(:foo?) }

        it 'returns true when the field is not set' do
          expect(subject.foo?).to be_falsey
          subject.foo = 'bar'
          expect(subject.foo?).to be_truthy
        end
      end
    end
  end

  describe '.called' do
    it 'is protected' do
      expect { subject.called {} }.to raise_error(NoMethodError)
    end

    context 'when called without a block' do
      it 'raises an error' do
        expect { Class.new(MethodObject) { called } }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.call' do
    it 'instantiates the method object and invokes #call' do
      expect(subject).to receive(:new).with(required_parameter: 'foo').once.and_call_original
      method_object_class.call(required_parameter: 'foo')
      expect(execution_spy).to have_received(:call).with('foo')
    end
  end

  describe '.new' do
    it 'accepts parameters and sets defaults once' do
      mo = method_object_class.new(required_parameter: 'foo')

      expect(mo).to be_a(method_object_class)
      expect(mo.required_parameter).to eql('foo')
      expect(mo.with_default).to be(0)

      expect(mo.with_dynamic_default).to be(0)
      expect(mo.with_dynamic_default).to be(0)
    end

    context 'when an unknown parameter is set' do
      it 'raises NoMethodError' do
        expect { method_object_class.new(non_existing: 1) }.to raise_error(NoMethodError)
      end
    end
  end

  describe '.to_proc' do
    let(:generated_proc) { subject.to_proc }

    it 'creates a proc' do
      expect(generated_proc).to be_a(Proc)
    end

    describe 'the generated proc' do
      it 'instantiates the method object and invokes #call' do
        expect(subject).to receive(:new).with(required_parameter: 'foo').once.and_call_original
        generated_proc.call(required_parameter: 'foo')
        expect(execution_spy).to have_received(:call).with('foo')
      end
    end
  end

  describe '#call' do
    subject { method_object_class.new }

    let(:method_object_class) do
      define_method_object(execution_spy) do |passed_execution_spy|
        called do
          passed_execution_spy.call
          'return value'
        end
      end
    end

    context 'when a called block has not been called' do
      let(:method_object_class) { define_method_object {} }

      it 'raises NotImplementedError' do
        expect { subject.call }.to raise_error(NotImplementedError)
      end
    end

    context 'when a required parameter is not set' do
      let(:method_object_class) do
        define_method_object do
          parameter :required_parameter, String

          called do
            execution_spy.call
            'return value'
          end
        end
      end

      it 'raises ArgumentError' do
        expect { subject.call }.to raise_error(ArgumentError)
      end

      context 'but it has a default value' do
        let(:method_object_class) do
          define_method_object(execution_spy) do |passed_execution_spy|
            parameter :required_parameter_with_default, String, default: 'value'

            called do
              passed_execution_spy.call(required_parameter_with_default)
              'return value'
            end
          end
        end

        it 'uses the default value' do
          expect { subject.call }.not_to raise_error
          expect(execution_spy).to have_received(:call).with('value')
        end
      end
    end

    it 'doesn\'t take parameters' do
      expect(subject.method(:call).arity).to be(0)
    end

    it 'executes the contents of the `called` block' do
      subject.call
      expect(execution_spy).to have_received(:call)
    end

    it 'preserves return value' do
      expect(subject.call).to eql('return value')
    end
  end

  describe '#parameters' do
    it 'returns a hash of the parameters set' do
      mo = method_object_class.new(required_parameter: 'foo')
      expect(mo.parameters).to match(
        required_parameter: 'foo',
        with_default: 0,
        with_dynamic_default: 0
      )
    end
  end

  describe '#to_proc' do
    subject { method_object_class.new }
    let(:generated_proc) { subject.to_proc }

    it 'creates a lambda' do
      expect(generated_proc).to be_a(Proc).and be_lambda
      expect(generated_proc.arity).to be(0)
    end

    describe 'the generated proc' do
      it 'calls the method object #call' do
        expect(subject).to receive(:call).once
        generated_proc.call
      end
    end
  end

  context 'when inheriting' do
    let(:base_method_object_class) do
      define_method_object do
        parameter :base_param, String, default: nil
        parameter :inherited_param, Integer, default: nil

        called do
          1
        end
      end
    end

    let(:inherited_method_object_class) do
      define_method_object(base_class: base_method_object_class) do
        parameter :inherited_param, String, default: nil
        parameter :child_param, String, default: nil

        called do
          super() + 1
        end
      end
    end

    describe '.parameter' do
      it 'inherits parameters from the parent' do
        expect { base_method_object_class.new(base_param: 'foo', inherited_param: 1) }.not_to raise_error
        expect { inherited_method_object_class.new(base_param: 'foo', inherited_param: 'bar', child_param: 'baz') }.not_to raise_error
      end
    end

    describe '.called' do
      it 'can call the superclass' do
        expect(base_method_object_class.call).to be(1)
        expect(inherited_method_object_class.call).to be(2)
      end
    end
  end
end
