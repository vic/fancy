require File.dirname(__FILE__) + "/../parser.rb"
require File.dirname(__FILE__) + "/../compiler.rb"

require 'rubygems'
require 'rspec'

module Fancy
  module ParseHelper
    def parse(code, *args)
      FancyParser.parse(code, *args)
    end
  end
end

RSpec.configure do |config|
  config.include Fancy::ParseHelper
end
