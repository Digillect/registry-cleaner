source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'kubeclient'
gem 'rest-client'

gem 'activesupport'
gem 'awesome_print'
#gem 'hashie'
gem 'semantic_logger'
