# PierLogging

A gem developed by [PIER](https://www.pier.digital/) to standardize our logs (request and general-purpose)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pier_logging'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pier_logging

## Usage

Create an initializer at `config/initializers/pier_logging.rb` to configure the gem.
Configure General-purpose logging, Request logging and register the request logger rails middleware.

### General-purpose logging

Use `PierLogging.configure_logger` block to configure general-purpose logs. Accepted configs are:

| config    | Required | Type                      | Default                            |
| --------- | --------:| -------------------------:| ----------------------------------:|
| app_name  | true     | string                    | nil                                |
| env       | true     | string                    | nil                                |
| formatter | false    | `Ougai::Formatters::Base` | `PierLogging::Formatter::Json.new` |

### Request logging

Use `PierLogging.configure_request_logger` block to configure request logs. Accepted configs are:

| config           | Required | Type            | Default    |
| ---------------- | --------:| ---------------:| ----------:|
| enabled          | false    | boolean         | false      |
| user_info_getter | true     | block (headers) | nil        |

The block passed to `user_info_getter` receives the headers of the request so you can use your headers to define the username or role. 

You have at your disposal the following helper methods:

- has_basic_credentials(headers): checks if there are basic auth credentials in the header
- get_basic_credentials_user(headers): get the user from the basic auth credential

### Example

```ruby
PierLogging.configure_logger do |config|
  config.app_name = Rails.application.class.module_parent_name.underscore.dasherize
  config.env = Rails.env
  config.formatter = Rails.env.production? ? PierLogging::Formatter::Json.new : 
    PierLogging::Formatter::Readable.new
end 

PierLogging.configure_request_logger do |config|
  config.user_info_getter do |headers|
    if headers['MY-USER-HEADER'].present?
      { username: headers['MY-USER-HEADER']  }
    elsif has_basic_credentials?(headers)
      { username: get_basic_credentials_user(headers) }
    else
      { username: 'anonymous' }
    end
  end
  config.enabled = ENV.fetch('REQUEST_LOG_ENABLED', 'true') == 'true'
end

Rails.application.config.middleware.use PierLogging::RequestLogger, PierLogging::Logger.new(STDOUT)
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pier-digital/pier_logging.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
