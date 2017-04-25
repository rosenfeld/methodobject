# frozen_string_literal: true

require 'method_object/parameter'

# Allows for the creation of {https://sourcemaking.com/refactoring/replace-method-with-method-object method objects},
# to ease the extraction of complex methods from other classes and the implementation of service objects.
#
# A method object works similarly to a proc/lambda, exposing a {.call} method and convenience
# {.to_proc} method to convert it to a Proc.
#
# Major differences in behaviour compared to a `lambda`:
#   * It accepts only named parameters
#   * It performs type checking on the parameters
#
# @example Defining and invoking a method object
#   class ComplexCalculation < MethodObject
#     parameter :start_number, Integer
#     parameter :end_number, Integer, default: 2
#
#     called do
#       @magic_number = 42
#       perform_complex_calculation
#     end
#
#     private
#
#     def perform_complex_calculation
#       start_number + second_number + @magic_number
#     end
#   end
#
#   ComplexCalculation.call(start_number: 1, end_number: 3) #=> 46
#   ComplexCalculation.call(start_number: 1) #=> 45
#   ComplexCalculation.call(end_number: 3) #=> raise ArgumentError
#
#   calculation = ComplexCalculation.new(end_number: 3)
#   calculation.start_number = 1
#   calculation.call # => 46
#
#   calculation.end_number = 2
#   calculation.call # => 45
#
# @example Using the method object as a block
#   class NameSayer < MethodObject
#     parameter :name, String
#
#     called { "You're #{name}" }
#   end
#
#   def say_my_name
#     puts "- Say my name."
#     puts "- " + yield(name: "Heisenberg")
#     puts "- You're goddamn right!"
#   end
#
#   say_my_name(&NameSayer)
#   # Output:
#   #
#   # - Say my name.
#   # - You're Heisenberg
#   # - You're goddamn right!
class MethodObject
  class << self
    # Calls the MethodObject with the given arguments.
    #
    # @param **args [Hash{Symbol => Object}] arguments to pass to the method
    # @return [Object] return value of the method object
    def call(**args)
      new(**args).call
    end

    # Returns a proc that calls the MO with the given arguments.
    # @return [Proc]
    def to_proc
      proc { |**args| call(**args) }
    end

    protected

    # Defines a parameter for the method object.
    #
    # Parameters are also inherited from superclasses and can be redefined (overwritten) in subclasses.
    #
    # @param name [Symbol] name of the parameter
    # @param type [Class, #===] type of the parameter. Can be a Class, a Proc or anything that defines a meaningful
    #   `===` method
    # @param **options [Hash] extra options for the parameter
    # @option **options [Object, #call] :default default value if the parameter is not passed. If the default implements
    #   `#call`, it gets called once in the context of the method object instance when it is instanciated
    #
    # @return [void]
    def parameter(name, type = BasicObject, **options)
      arg = MethodObject::Parameter.new(name, type, options)
      parameters.delete(arg)
      parameters << arg

      define_method("#{name}=") do |value|
        raise ArgumentError, "Expected a #{type} for #{name}, #{value.class} received" unless arg.acceptable?(value)
        @monitor.synchronize { instance_variable_set("@#{name}", value) }
      end

      define_method("#{name}?") do
        !public_send(name).nil?
      end

      attr_reader name
    end

    # Defines the method body.
    # The body can be overwritten in subclasses and the superclass implementation can be invoked with `super()`,
    # as with a regular method definition.
    #
    # @yield Block to be used as method body definition for the method object
    # @return [void]
    def called(&block)
      define_method(:do_call, &block)
      protected :do_call
    end

    private

    # @return [Set]
    def superclass_parameters
      if superclass < MethodObject
        superclass.send(:parameters)
      else
        Set.new
      end
    end

    # @return [Set]
    def parameters
      @parameters ||= Set.new(superclass_parameters)
    end
  end

  # @param **args [Hash{Symbol => Object}] arguments to set on the method object
  def initialize(**args)
    self.class.send(:parameters).freeze

    @monitor = Monitor.new

    args.each { |k, v| public_send("#{k}=", v) }
    self.class.send(:parameters)
        .reject { |p| args.keys.map(&:to_sym).include?(p.name) }
        .select(&:default?)
        .each { |p| public_send("#{p.name}=", p.default_in(self)) }
  end

  # Returns a hash with the parameters currently set.
  # @return [Hash{Symbol => Object}]
  def parameters
    self.class.send(:parameters).map(&:name)
        .select { |p| instance_variable_defined?("@#{p}") }
        .map { |p| [p, public_send(p)] }
        .to_h
  end

  # Calls the method object with the parameters currently set.
  # @raise [ArgumentError] if any required parameter is missing
  # @return [Object] the return value result of the method invokation
  def call
    unless respond_to?(:do_call, true)
      raise NotImplementedError,
            'Implementation missing. Please use `called { ... }` to define method body'
    end

    @monitor.synchronize do
      assert_required_arguments!
      do_call
    end
  end

  # Returns a lambda that calls the method object with the parameters currently set.
  # @return [Proc]
  def to_proc
    -> { call }
  end

  private

  # @raise [ArgumentError]
  def assert_required_arguments!
    missing_params =
      self.class.send(:parameters)
          .select { |p| !p.default? && !public_send("#{p.name}?") }
          .map(&:name)

    raise ArgumentError, "Missing required arguments: #{missing_params.join(', ')}" \
      unless missing_params.empty?
  end
end
