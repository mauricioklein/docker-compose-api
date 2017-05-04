require 'byebug'
require 'simplecov'
require 'codeclimate-test-reporter'

Dir[File.join(File.dirname(__FILE__), '../lib/**/*.rb')].each { |f| require f }

SimpleCov.start do
  add_filter '/spec/'
end
