# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode
# (Use only when you can't set environment variables through your web/app server)
ENV['RAILS_ENV'] ||= 'production'

RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

SKIP_VERSION = '1.8.7'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# TODO: lighttpdで動作するとカレントディレクトリがpublicになりgettext-2.0.4がmoファイルを取得できず正しく動作しない。
#       gettext-rails側などで、根本解決できた場合に削除する
Dir.chdir(RAILS_ROOT)

Rails::Initializer.run do |config|
  # config.action_controller.session_store = :p_store

  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  # config.action_controller.session_store = :active_record_store

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  # config.action_controller.fragment_cache_store = :file_store, "#{RAILS_ROOT}/cache"

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  # config.active_record.schema_format = :ruby

  # See Rails::Configuration for more options
  config.gem 'openskip-skip_embedded', :lib => 'skip_embedded', :version => '0.9.19', :source => 'http://gems.github.com'
  config.gem 'will_paginate', :lib => 'will_paginate', :version=> '2.3.12', :source => 'http://gemcutter.org'
  config.gem "fastercsv", :version => '1.5.1'
  config.gem "json", :lib => "json/add/rails", :version => '1.2.0'
  config.gem "maedana-ar_mailer", :lib => 'action_mailer/ar_mailer', :source => 'http://gemcutter.org'
  config.gem 'locale', :version => '2.0.4'
  config.gem 'locale_rails', :version => '2.0.4'
  config.gem 'gettext', :version => '2.0.4'
  config.gem 'gettext_activerecord', :version => '2.0.4'
  config.gem 'gettext_rails', :version => '2.0.4'
  config.gem "feed-normalizer", :version => '1.5.2'
  config.gem "searchlogic", :version => '2.4.7'
  config.gem "nokogiri", :version => '1.4.1'
  config.gem "sanitize", :version => '1.2.0'
  config.gem 'diff-lcs', :lib => 'diff/lcs', :version => '1.1.2'
  config.gem 'httpclient', :lib => 'httpclient', :version => '2.1.5.2'
  config.gem 'jrails', :lib => 'jrails', :version => '0.6.0'
end

# 共通メニュー
common_menu_path = File.join(RAILS_ROOT, 'config', 'common_menus.yml')
COMMON_MENUS = File.exist?(common_menu_path) ? YAML::load(File.open(File.join(RAILS_ROOT, 'config', 'common_menus.yml'))) : {}

# 祝日マスタ
HOLIDAYS = YAML::load(File.open(File.join(RAILS_ROOT, 'config', 'holiday.yml')))

require 'hikidoc'
require 'skip_util'
