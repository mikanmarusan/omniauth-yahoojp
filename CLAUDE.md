# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Testing
- `rake spec` or `rspec` - Run all tests
- `rspec spec/omniauth/strategies/yahoojp_spec.rb` - Run specific test file
- `rake` - Default task runs specs

### Development Tools
- `guard` - File watcher for automatic test running (configured via Guardfile)
- `bundle install` - Install gem dependencies

## Architecture

This is a Ruby gem that implements an OmniAuth strategy for Yahoo! JAPAN's YConnect OAuth 2.0 service.

### Core Components

**Main Strategy**: `lib/omniauth/strategies/yahoojp.rb`
- Inherits from `OmniAuth::Strategies::OAuth2`
- Implements Yahoo! JAPAN YConnect v2 API endpoints
- Handles OAuth 2.0 authorization code flow with basic auth for token exchange
- Supports YConnect-specific parameters: display, prompt, scope, bail

**Key Implementation Details**:
- Uses `https://auth.login.yahoo.co.jp` as OAuth provider
- YConnect v2 endpoints: `/yconnect/v2/authorization` and `/yconnect/v2/token`
- User info endpoint: `https://userinfo.yahooapis.jp/yconnect/v2/attribute`
- Custom `build_access_token` method for Yahoo-specific auth headers
- Supports Japanese locale-specific fields (kana, kanji names)

### File Structure
- `lib/omniauth-yahoojp.rb` - Main entry point, requires the strategy
- `lib/omniauth-yahoojp/version.rb` - Gem version
- `lib/omniauth/strategies/yahoojp.rb` - Strategy implementation
- `spec/` - RSpec tests

### Dependencies
- `omniauth` and `omniauth-oauth2` for OAuth framework
- `httpauth` for HTTP basic authentication headers