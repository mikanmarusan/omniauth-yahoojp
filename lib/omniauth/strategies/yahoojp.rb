require 'omniauth-oauth2'
require 'httpauth'
require 'json/jwt'

module OmniAuth
  module Strategies
    class YahooJp < OmniAuth::Strategies::OAuth2

      option :name, 'yahoojp'
      option :client_options, {
        :site => 'https://auth.login.yahoo.co.jp',
        :authorize_url => '/yconnect/v2/authorization',
        :token_url => '/yconnect/v2/token',
        :auth_scheme => :basic_auth,
        :userinfo_url => 'https://userinfo.yahooapis.jp/yconnect/v2/attribute'
      }
      option :authorize_options, [:display, :prompt, :scope, :bail]
      option :userinfo_access, true

      def request_phase
        super
      end

      uid { raw_info['sub'] }

      info do
        prune!({
          :sub        => raw_info['sub'],
          :name       => raw_info['name'],
          :given_name => raw_info['given_name'],
          :given_name_ja_kana_jp => raw_info['given_name#ja-Kana-JP'],
          :given_name_ja_hani_jp => raw_info['given_name#ja-Hani-JP'],
          :family_name => raw_info['family_name'],
          :family_name_ja_kana_jp => raw_info['family_name#ja-Kana-JP'],
          :family_name_ja_hani_jp => raw_info['family_name#ja-Hani-JP'],
          :gender     => raw_info['gender'],
          :zoneinfo   => raw_info['zoneinfo'],
          :locale     => raw_info['locale'],
          :birthdate  => raw_info['birthdate'],
          :nickname   => raw_info['nickname'],
          :picture    => raw_info['picture'],
          :email      => raw_info['email'],
          :email_verified => raw_info['email_verified'],
          :address    => raw_info['address'],
        })
      end

      extra do
        hash = {}
        hash[:raw_info] = raw_info unless skip_info?
        prune! hash
      end

      def raw_info
        @raw_info ||= if options.userinfo_access
          access_token.options[:mode] = :header
          access_token.get(options.client_options.userinfo_url).parsed
        elsif id_token
          id_token_claims.slice(:sub).merge(
            id_token: id_token,
            id_token_claims: id_token_claims,
          )
        else
          {}
        end
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

      def id_token
        access_token&.params&.dig('id_token')
      end

      def id_token_claims
        JSON::JWT.decode(id_token, :skip_verification)
      end
    end
  end
end

OmniAuth.config.add_camelization 'yahoojp', 'YahooJp'
