# Robin CMS

![Robin CMS logo](./assets/robin-logo.png)

A minimalist CMS built with Ruby and Sinatra.

## Usage

You can use it directly by creating a `config.ru` with the following contents

    require 'robin-cms'
    run RobinCMS::CMS

Alternatively, you can embed it into your own Sinatra project like this

    require 'robin-cms'
    require 'sinatra'

    use RobinCMS::CMS

    get '/' do
        'Hello, world!'
    end

    run Sinatra::Application

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/aronlebani/robin-cms.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
