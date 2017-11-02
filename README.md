# OmniAuth YahooJp [![Gem Version](https://badge.fury.io/rb/omniauth-yahoojp.svg)](https://badge.fury.io/rb/omniauth-yahoojp)

**These notes are based on master, please see tags for README pertaining to specific releases.**

This is the official OmniAuth strategy for authenticating to Yahoo! JAPAN( [YConnect](http://developer.yahoo.co.jp/yconnect/v2/) ).
To use it, you'll need to sign up for a YConnect Client ID and Secret
on the [Yahoo! JAPAN Developer Network](https://e.developer.yahoo.co.jp/dashboard/).

Supports OAuth 2.0 Authorization Code flows. Read the Yahoo!JAPAN docs for more details: https://developer.yahoo.co.jp/yconnect/v2/

## Installing

Add to your `Gemfile`: 

```ruby
gem 'omniauth-yahoojp'
```

Then `bundle install`.

## Basic Usage

`OmniAuth::Strategies::YahooJp` is simply a Rack middleware. Read the OmniAuth docs for detailed instructions: https://github.com/intridea/omniauth.

YConnect API v2 lets you set scopes to provide granular access to different types of data: 

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
    provider :yahoojp, ENV['YAHOOJP_KEY'], ENV['YAHOOJP_SECRET'], 
    {
        scope: "openid profile email address"
    }
end
```

## Advanced Parameters

You can also set :display, :prompt, :scope, :bail parameter to specify behavior of sign-in and permission page.
More info on [YConnect](http://developer.yahoo.co.jp/yconnect/v2/).

For example, to request `openid`, `profile`,  and `email` permissions and display the authentication page in a popup window:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
    provider :yahoojp, ENV['YAHOOJP_KEY'], ENV['YAHOOJP_SECRET'], 
    {
        scope: "openid profile email",
        display: "popup"
    }
end
```

### API Version

OmniAuth YahooJp uses versioned API endpoints by default (current v2). You can configure a different version via `client_options` hash passed to `provider`, specifically you should change the version in the `site` and `authorize_url` parameters. For example, to change to v1:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
    provider :yahoojp, ENV['YAHOOJP_KEY'], ENV['YAHOOJP_SECRET'], 
    {
        scope: "openid profile email address",
        client_options: {
            authorize_url: '/yconnect/v1/authorization',
            token_url: '/yconnect/v1/token'
        }
    }
end
```

## License

Copyright (c) 2013 by mikanmarusan

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
