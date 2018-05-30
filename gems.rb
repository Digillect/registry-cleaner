source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'docker-api'
gem 'kubeclient'
gem 'rest-client'

gem 'activesupport'
gem 'awesome_print'
gem 'semantic_logger'

group :test do
  gem 'minitest'
  gem 'minitest-stub-const'
  gem 'rake'
end
