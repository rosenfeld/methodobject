# Method Object
[![Gem Version](https://badge.fury.io/rb/methodobject.svg)](https://rubygems.org/gems/methodobject)
[![Build Status](https://travis-ci.org/LIQIDTechnology/methodobject.svg?branch=master)](https://travis-ci.org/LIQIDTechnology/methodobject)
[![Coverage Status](https://coveralls.io/repos/github/LIQIDTechnology/methodobject/badge.svg?branch=master)](https://coveralls.io/github/LIQIDTechnology/methodobject?branch=master)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://www.rubydoc.info/gems/methodobject/)
[![Documentation coverage](https://inch-ci.org/github/LIQIDTechnology/methodobject.svg?branch=master)](https://inch-ci.org/github/LIQIDTechnology/methodobject)


Provides a lightweight and dependency-free solution for the creation of [method objects](https://sourcemaking.com/refactoring/replace-method-with-method-object),
a common pattern used to ease the extraction of complex methods from other classes and for the implementation of service objects.

The __method object pattern__ is advisable when a method is too long and difficult to separate due to tangled masses of local variables that are hard to isolate from each other: the solution is to extract the entire method into a separate class and turn its local variables into fields of the class; this allows isolating the problem at the class level and it paves the way for splitting a large and unwieldy method into smaller ones that would not fit with the purpose of the original class anyway.

This gem also provides a uniform interface to write __service objects__, that is a common way to extract common operations from models and controllers in Rails application. Borrowing the design from [an article](http://brewhouse.io/blog/2014/04/30/gourmet-service-objects.html) on what the author defines as _"Gourmet Service Object"_, it provides some plumbing to implement such a pattern, with objects that expose a operation as their entry-point.

The interface exposed by a MethodObject is similar to the one of a _proc_/_lambda_, exposing a `call` method both at class and instance level and a convenience `to_proc` method to convert it to a Proc. Other neat features include optional type checking for the arguments and inheritance between MO's.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'methodobject'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install methodobject

## Usage

### Defining and invoking a method object

```ruby
class ComplexCalculation < MethodObject
  # Type checking is optional. If omitted, anything is accepted.
  # Type checking can also done with a proc or anything that responds to #===
  # e.g. parameter :start_number, ->(p) { p.respond_to?(:to_i) }
  parameter :start_number, Integer

  # Parameters that define a default are optional.
  # `default` supports also a proc, that gets evaluated at
  # object instantiation.
  # e.g. default: -> { Time.now }
  parameter :end_number, Integer, default: 2

  # Defines the `call` method body.
  # Inheritance works also as expected. Calling `super()` invokes
  # superclass' implementation.
  called do
    @magic_number = 42
    perform_complex_calculation
  end

  private

  def perform_complex_calculation
    # The arguments are available as accessors
    start_number + second_number + @magic_number
  end
end

# The class-method version of `call` accepts the arguments as named parameters
ComplexCalculation.call(start_number: 1, end_number: 3) #=> 46
ComplexCalculation.call(start_number: 1)                #=> 45
ComplexCalculation.call(end_number: 3)                  #=> raise ArgumentError

# `call` can also be omitted, as per usual Ruby semantics
ComplexCalculation.(start_number: 1)

# The class-method version of `to_proc` returns a proc that takes the same arguments
ComplexCalculation.to_proc.call(start_number: 1)

# The method object can also be instantiated, passing the arguments to the constructor
# or to the accessors
calculation = ComplexCalculation.new(end_number: 3)
calculation.start_number = 1
calculation.call # => 46

calculation.end_number = 2
calculation.call # => 45

# The instance-method version of `to_proc` returns a lambda that calls the method object
# with the parameters currently set
calculation.to_proc.call # => 45
```

### Using the method object as a block

```ruby
class NameSayer < MethodObject
  parameter :name

  called { "You're #{name}" }
end

def say_my_name
  puts "- Say my name."
  puts "- " + yield(name: "Heisenberg")
  puts "- You're goddamn right!"
end

say_my_name(&NameSayer)
# Output:
#
# - Say my name.
# - You're Heisenberg
# - You're goddamn right!
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/LIQIDTechnology/methodobject. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

