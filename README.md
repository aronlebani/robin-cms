# Robin CMS

![Robin CMS logo](./assets/robin-logo.png)

Robin CMS is a minimalist flat-file CMS built with Ruby and Sinatra. It is
designed to be used by developers for creating custom built websites where the
client needs to be able to update content themselves. It works with any Static
Site Generator and can also be embedded in a dynamic Sinatra app. The idea is
that you can just drop it into your project and it gives you a completely
customised CMS for your website.

It is completely headless - it gives clients an admin interface where they can
manage raw content, while giving the developer full control over the HTML and
CSS. That way clients can't accidentally break layouts and design.

You can define the content model of your website using a YAML file. That way
you don't have to wrangle all your data into a "blog" post. You can choose to
store content either as HTML (predominantly for content with rich text), or
YAML for structured key-value data.

Robin CMS is designed to keep things as simple as possible. It uses files to
store data so you don't have to worry about managing a database. The entire CMS
can be installed with just two files - a two line `config.ru` file and a
`robin.yaml` configuration file.

## Motivation

I know, I know. Another CMS. Whilst there seems to be a plethora of options in
PHP and JavaScript, there aren't many options for Ruby. Most of them are big
Rails monoliths, designed either to be a full end-to-end CMS like Wordpress, or
for the specific use-case of building a blog. I couldn't find a simple
headless, flat-file CMS built in Ruby that met my needs. So here we are.

## Features

* Headless, flat file CMS
* Define custom content model using a YAML configuration file
* Store content as files in HTML or YAML format
* Works with any Static Site Generator or with a dynamic Sinatra app
* Simple to install into your website - you just need to add a `config.ru` and
  a `robin.yaml` file
* Self-contained - you don't need to ship any assets for the CMS admin site

## Limitations

In order to keep the CMS simple to maintain for your website, certain features
that are commonly found in CMS software have been omitted.

* Only supports a single user, which means you don't need to maintain a user
  database.
* Does not support relations between content models. This is the nature of a
  flat-file CMS. If you need data model relations, you are probably better off
  using an SQL database backend rather than a flat-file backend.
* Doesn't support multiple sites. It is designed to be simple enough that you
  can drop in a separate instance of the CMS for each website.
* Does not have a WYSIWYG editor. It is designed purely for managing structured
  content. You can however add richtext fields to your content models (see
  example below).

## Usage

1. Install gem

```sh
gem install robin-cms
```

2. Create a `config.ru` file

You can use it directly as a CMS for a Static Site Generator

```ruby
require 'robin-cms'
run RobinCMS::CMS
```

Alternatively, you can embed it into your own Sinatra project like this

```ruby
require 'robin-cms'
require 'sinatra'

use RobinCMS::CMS

get '/' do
    'Hello, world!'
end

run Sinatra::Application
```

3. Define your content model in a `robin.yaml` file

```yaml
content_dir: content
admin_username: "admin"
admin_password: "admin"
collections:
  - name: "poem"
    label: "Poem"
    filetype: "html"
    fields:
      - { label: "Title", name; "title", type: "input" }
      - { label: "Author", name; "author_name", type: "input" }
      - { label: "Content", name; "content", type: "richtext" }
  - name: "book"
    label: "Book"
    filetype: "yaml"
    fields:
      - { label: "Title", name; "title", type: "input" }
      - { label: "Author", name; "author_name", type: "input" }
```

That's it. Now run `rackup`, and go to `http://localhost:9292` in your browser.
You can log in with username "admin" and password "admin".

The admin username and password can also be set by the environment variables
`ADMIN_USER` and `ADMIN_PASS`. This is the recommended approach for a
production environment.

You'll also need to expose a `SESSION_SECRET` environment variable. If you
don't, it will create one for you, but it creates a new secret each time
the server starts, meaning you will have to log in again whenever you restart
the server. It is reccommended to create one via Ruby's SecureRandom package.

```sh
ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"
```

See the [example](./example) folder for a full example. I haven't written any
documentation yet, but the example `robin.yaml` file is thoroughly commented to
explain each of the fields.

## Testing

Unit test are written in RSpec. To run them:

```
rspec
```

Most of the core application is covered. Some UI tests probably still need to
be written at some point.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/aronlebani/robin-cms.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
