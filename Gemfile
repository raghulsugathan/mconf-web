source 'http://rubygems.org'

gem 'rails', '3.2.11'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', '~> 3.2.0'
  gem 'coffee-rails', '~> 3.2.0'
  gem 'uglifier', '>= 1.0.3'
  gem 'yui-compressor'
  gem 'compass-rails', '~> 1.0'

  # TODO: remove when compass-rails is updated
  # This compass is here so we can have css3/animation
  gem 'compass', '~> 0.13.alpha'
end

gem 'net-ldap'
gem 'gon', '3.0.5'
gem 'mysql2', '~> 0.3.0'
gem 'rake'
gem 'jquery-rails'
gem 'therubyracer', :require => 'v8'
gem 'haml'
gem 'will_paginate'
gem 'chronic'
gem 'yaml_db'
gem 'delayed_job', '~> 3.0.0'
gem 'delayed_job_active_record'
gem 'daemons' # for delayed_job
gem 'rails_autolink'
gem 'whenever', :require => false
gem 'garb'
gem 'bigbluebutton-api-ruby', :git => 'git://github.com/mconf/bigbluebutton-api-ruby.git'
gem 'bigbluebutton_rails', :git => 'git://github.com/mconf/bigbluebutton_rails.git'
gem 'simple_form', '~> 2.0.0'
gem 'acts_as_tree', :git => 'https://github.com/parasew/acts_as_tree.git'
gem 'friendly_id'
gem 'station', :git => 'git://github.com/mconf/station.git', :branch => 'mweb-v2'
gem 'devise'
gem 'devise-encryptable' # TODO: only while we have old station users
gem 'cancan', '~> 1.6.0'
gem 'i18n-js', :git => "git://github.com/fnando/i18n-js.git", :branch => 'rewrite'
gem 'rabl'
gem 'yajl-ruby' # json parser for rabl

# for bootstrap
gem 'less-rails'
gem 'twitter-bootstrap-rails'

# TODO: Gems to review if we can remove/update
gem 'galetahub-simple_captcha', :require => 'simple_captcha'
gem 'attachment_fu', :git => 'git://github.com/mconf/attachment_fu.git'
gem 'vpim' # vcard and icalendar
gem 'hpricot'
gem 'feed-normalizer'
gem 'httparty'
gem 'ci_reporter'
gem 'nokogiri', '1.4.1'
gem 'rubyzip' # TODO: see rubyzip2
gem 'rmagick', :git => 'git://github.com/rmagick/rmagick.git', :require => false
gem 'dynamic_form'
gem 'prism'
# not the official repo, but has fixes for rails 3
gem 'table_helper', :git => 'git://github.com/eeng/table_helper.git'

group :development do
  gem 'debugger'
  gem 'translate-rails3', :require => 'translate', :git => 'git://github.com/mconf/translate.git'
  gem 'spork-rails'
  gem 'rails-footnotes'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'populator'
  gem 'ffaker'
  gem 'forgery'
  gem 'factory_girl_rails'
  gem 'sqlite3'
  gem 'webrat'
  gem 'rspec-instafail'
  gem 'fuubar'
  gem 'shoulda-matchers'
  gem 'htmlentities'
  gem 'turn', '0.8.2', :require => false # TODO: why 0.8.2?
  gem 'simplecov'
end

gem 'god', '0.12.1'
gem 'passenger', '3.0.17'
gem 'exception_notification'

# Rails 3.1 - Heroku
#group :production do
#  gem 'therubyracer-heroku', '0.8.1.pre3'
#  gem 'pg'
#end
