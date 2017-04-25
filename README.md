# Method Object

Allows for the creation of [method objects](https://sourcemaking.com/refactoring/replace-method-with-method-object),
to ease the extraction of complex methods from other classes and the implementation of service objects.

A method object works similarly to a proc/lambda, exposing a {.call} method and convenience
{.to_proc} method to convert it to a Proc.

Major differences in behaviour compared to a `lambda`:
* It accepts only named parameters
* It performs type checking on the parameters


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
  parameter :start_number, Integer
  parameter :end_number, Integer, default: 2

  called do
    @magic_number = 42
    perform_complex_calculation
  end

  private

  def perform_complex_calculation
    start_number + second_number + @magic_number
  end
end

ComplexCalculation.call(start_number: 1, end_number: 3) #=> 46
ComplexCalculation.call(start_number: 1) #=> 45
ComplexCalculation.call(end_number: 3) #=> raise ArgumentError

calculation = ComplexCalculation.new(end_number: 3)
calculation.start_number = 1
calculation.call # => 46

calculation.end_number = 2
calculation.call # => 45
```

### Using the method object as a block

```ruby
class NameSayer < MethodObject
  parameter :name, String

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

