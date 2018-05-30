require 'rubygems'
require 'bundler'

Bundler.setup(:default, :test)

require 'active_support'
require 'active_support/dependencies'

ActiveSupport::Dependencies.autoload_paths += %w[src]

require 'minitest/autorun'
require 'minitest/stub_const'
