require 'coveralls'
Coveralls.wear!

require 'commander'
require 'commander/methods'
require 'pry'
require 'fakefs/spec_helpers'

# Mock terminal IO streams so we can spec against them
def mock_terminal
  @input = StringIO.new
  @output = StringIO.new
  $terminal = HighLine.new @input, @output
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
