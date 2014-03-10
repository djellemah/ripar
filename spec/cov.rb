# must be before coverage'd code is loaded
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
end
