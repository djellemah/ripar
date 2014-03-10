# must be before coverage'd code is loaded
require 'simplecov'
require 'pry'

SimpleCov.start do
  add_filter '/spec/'
end
