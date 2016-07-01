require 'omniauth-oauth2'
require 'httpauth'

module OmniAuth
  module Strategies
    class YahooJp < OmniAuth::Strategies::OAuth2

      option :name, 'yahoojp'
      option :client_options, {
        :site => 'https://auth.login.yahoo.co.jp',
        :authorize_url => '/yconnect/v1/authorization',
        :token_url => '/yconnect/v1/token'
      }

      option :authorize_options, [:display, :prompt, :scope]

      def request_phase
        super
      end

      uid { raw_info['user_id'] }

      info do
        prune!({
          :name       => raw_info['name'],
          :email      => raw_info['email'],
          :first_name => raw_info['given_name'],
          :last_name  => raw_info['family_name'],
          :urls => {
            'YahooJp' => raw_info['link'],
          },
        })
      end

      extra do
        hash = {}
        hash[:raw_info] = raw_info unless skip_info?
        prune! hash
      end

      def raw_info
        access_token.options[:mode] = :header
        @raw_info ||= access_token.get('https://userinfo.yahooapis.jp/yconnect/v1/attribute?schema=openid').parsed
      end

      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end

      def build_access_token
        token_params = {
          :code => request.params['code'],
          :redirect_uri => callback_url,
          :grant_type => 'authorization_code',
          :headers => {'Authorization' => HTTPAuth::Basic.pack_authorization(client.id, client.secret)}
        }

        client.get_token(token_params);
      end

      def callback_url
        full_host + script_name + callback_path
      end

    end
  end
end

OmniAuth.config.add_camelization 'yahoojp', 'YahooJp'
