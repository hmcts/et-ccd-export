source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.3'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Sidekiq - Used to receive the jobs from the API service
gem 'sidekiq', '~> 5.2', '>= 5.2.7'
gem 'sidekiq_alive', '~> 1.1'
gem 'sidekiq-failures', '~> 1.0'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Azure deployment so we need this
gem 'azure_env_secrets', git: 'https://github.com/ministryofjustice/azure_env_secrets.git', tag: 'v0.1.3'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'

gem 'addressable', '~> 2.6'
gem 'rest-client', '~> 2.0', '>= 2.0.2'
gem 'jbuilder', '~> 2.9', '>= 2.9.1'
gem 'et_ccd_client', git: 'https://github.com/hmcts/et-ccd-client-ruby.git', tag: 'v0.1.1'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :test do
  gem 'rspec-rails', '~> 3.8', '>= 3.8.2'
  gem 'factory_bot', '~> 5.0', '>= 5.0.2'
  gem 'jsonpath', '~> 0.5.8'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'rubocop', '~> 0.71.0'
  gem 'rubocop-rspec', '~> 1.33'
end


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
