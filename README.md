# OmniAuth YahooJp [![Gem Version](https://badge.fury.io/rb/omniauth-yahoojp.svg)](https://badge.fury.io/rb/omniauth-yahoojp)

**These notes are based on master, please see tags for README pertaining to specific releases.**

This is the OmniAuth strategy for authenticating to Yahoo! JAPAN( [YConnect](http://developer.yahoo.co.jp/yconnect/v2/) ).
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
        scope: "openid profile email address",
        userinfo_access: true  # default: true
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

### `userinfo_access` Option

Controls how user profile information is retrieved.

- `userinfo_access: true` (default) — Calls the UserInfo API (`https://userinfo.yahooapis.jp/yconnect/v2/attribute`) to retrieve full profile information including name variants (kana, kanji), gender, locale, birthdate, nickname, picture, email, and address.
- `userinfo_access: false` — Skips the UserInfo API call and extracts profile information from the `id_token` claims instead. This is useful when your application does not have access to the UserInfo API.

> **Note:** The fields available in `id_token` claims may differ from those returned by the UserInfo API. The `id_token` typically contains a subset of profile fields depending on the requested scopes. Yahoo! JAPAN has made the UserInfo API access-restricted, so some applications may need to rely on `id_token` claims.

### ID Token

When the `openid` scope is requested, the strategy automatically captures the `id_token` returned by Yahoo! JAPAN's token endpoint.

- `credentials.id_token` — The raw JWT string as returned from the token endpoint.
- `extra.id_token_claims` — The decoded claims hash from the `id_token`.

The `id_token` signature verification is skipped because the token is received directly from Yahoo! JAPAN's token endpoint over TLS in the Authorization Code Flow, which guarantees its authenticity.

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

## Auth Hash

Here is an example of the auth hash available in `request.env['omniauth.auth']`:

```ruby
{
  provider: "yahoojp",
  uid: "abcdefg",
  info: {
    sub: "abcdefg",
    name: "山田 太郎",
    given_name: "太郎",
    given_name_ja_kana_jp: "タロウ",
    given_name_ja_hani_jp: "太郎",
    family_name: "山田",
    family_name_ja_kana_jp: "ヤマダ",
    family_name_ja_hani_jp: "山田",
    gender: "male",
    locale: "ja-JP",
    email: "example@yahoo.co.jp",
    email_verified: true
  },
  credentials: {
    token: "ACCESS_TOKEN",
    refresh_token: "REFRESH_TOKEN",
    expires_at: 1496120719,
    expires: true,
    id_token: "eyJhbGciOiJSUzI1NiIs..."
  },
  extra: {
    raw_info: { ... },           # Full response from UserInfo API (or id_token claims)
    id_token: "eyJhbGciOiJSUzI1NiIs...",  # Raw JWT string
    id_token_claims: {           # Decoded id_token claims
      iss: "https://auth.login.yahoo.co.jp/yconnect/v2",
      sub: "abcdefg",
      aud: ["YOUR_CLIENT_ID"],
      exp: 1496120719,
      iat: 1496117119,
      nonce: "..."
    }
  }
}
```

> **Note:** Available fields in `info` and `extra.raw_info` depend on the requested scopes and the `userinfo_access` setting.

## License

Copyright (c) 2013 by mikanmarusan

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
