# frozen_string_literal: true

require "active_merchant"
require "active_merchant_buckaroo"
require "rspec"
require "rack/test"
require "vcr"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV['BUCKAROO_SECRET_KEY'] ||= "key4thebuck@buckaroo"
ENV['BUCKAROO_WEBSITE_KEY'] ||= "GZQsEjiDek"

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.filter_run_when_matching :focus
  config.order = :random
end

RSpec.configure do |config|
  VCR.configure do |c|
    c.hook_into :webmock # or :fakeweb
    c.configure_rspec_metadata!

    c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
    c.default_cassette_options = { erb: true }
    c.allow_http_connections_when_no_cassette = true

    c.filter_sensitive_data('<SECRETKEY>') { ENV['BUCKAROO_SECRET_KEY'] }
    c.filter_sensitive_data('<WEBSITEKEY>') { ENV['BUCKAROO_WEBSITE_KEY'] }

    c.ignore_request do |request|
      if [
        "127.0.0.1", "localhost",
        "s3.amazonaws.com"
      ].any? {|host| request.uri.include?(host) }
      end
    end

    c.before_record(:replace_erb) do |interaction, cassette|
      cassette.erb.each do |variable, value|
        interaction.filter!(value, "<%= #{variable} %>")
      end
    end
  end

  WebMock.disable_net_connect!(allow_localhost: true)
end
