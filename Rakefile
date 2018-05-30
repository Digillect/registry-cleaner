require 'rubygems'
require 'bundler'

Bundler.setup(:default, :test)

require 'rake/testtask'

Rake::TestTask.new do |task|
  task.libs << %w[tests src]
  task.pattern = 'tests/test_*.rb'
end

task(default: :test)
