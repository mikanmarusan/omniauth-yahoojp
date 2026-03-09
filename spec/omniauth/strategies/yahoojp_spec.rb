require 'spec_helper'
require 'omniauth-yahoojp'
require 'json/jwt'

RSpec.describe OmniAuth::Strategies::YahooJp do
  let(:app) { lambda { |_env| [200, {}, ['Hello']] } }
  let(:strategy) { described_class.new(app, 'client_id', 'client_secret') }

  describe 'client options' do
    it 'has correct site' do
      expect(strategy.options.client_options.site).to eq('https://auth.login.yahoo.co.jp')
    end

    it 'has correct authorize url' do
      expect(strategy.options.client_options.authorize_url).to eq('/yconnect/v2/authorization')
    end

    it 'has correct token url' do
      expect(strategy.options.client_options.token_url).to eq('/yconnect/v2/token')
    end
  end

  describe 'default options' do
    it 'has userinfo_access enabled by default' do
      expect(strategy.options.userinfo_access).to be true
    end
  end

  describe 'constants' do
    it 'has correct JWKS_URI' do
      expect(described_class::JWKS_URI).to eq('https://auth.login.yahoo.co.jp/yconnect/v2/jwks')
    end

    it 'has correct ISSUER' do
      expect(described_class::ISSUER).to eq('https://auth.login.yahoo.co.jp/yconnect/v2')
    end
  end

  context 'with access_token' do
    let(:rsa_key) { OpenSSL::PKey::RSA.generate(2048) }
    let(:kid) { 'test-kid-1' }
    let(:jwt_payload) do
      {
        'sub' => 'test123',
        'name' => 'Test User',
        'email' => 'test@example.com',
        'iss' => 'https://auth.login.yahoo.co.jp/yconnect/v2',
        'aud' => 'client_id',
        'exp' => Time.now.to_i + 3600
      }
    end
    let(:jwt_string) do
      jwt = JSON::JWT.new(jwt_payload)
      jwt.kid = kid
      jwt.sign(rsa_key, :RS256).to_s
    end
    let(:access_token) do
      instance_double(
        OAuth2::AccessToken,
        token: 'mock_token',
        refresh_token: 'mock_refresh',
        expires?: true,
        expires_at: 1234567890,
        params: { 'id_token' => jwt_string },
        options: {}
      )
    end

    before do
      allow(strategy).to receive(:access_token).and_return(access_token)
      jwk = JSON::JWK.new(rsa_key, kid: kid)
      stub_request(:get, 'https://auth.login.yahoo.co.jp/yconnect/v2/jwks')
        .to_return(
          status: 200,
          body: { keys: [jwk] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    describe '#id_token' do
      it 'returns the id_token from access_token params' do
        expect(strategy.id_token).to eq(jwt_string)
      end

      it 'returns nil when no id_token in params' do
        allow(access_token).to receive(:params).and_return({})
        expect(strategy.id_token).to be_nil
      end

      it 'returns nil when id_token is empty string' do
        allow(access_token).to receive(:params).and_return({ 'id_token' => '' })
        expect(strategy.id_token).to be_nil
      end
    end

    describe '#id_token_claims' do
      it 'decodes and verifies the JWT' do
        claims = strategy.id_token_claims
        expect(claims['sub']).to eq('test123')
        expect(claims['name']).to eq('Test User')
        expect(claims['email']).to eq('test@example.com')
      end

      it 'memoizes the result' do
        first_call = strategy.id_token_claims
        second_call = strategy.id_token_claims
        expect(first_call).to equal(second_call)
      end

      it 'returns nil when id_token is nil' do
        allow(access_token).to receive(:params).and_return({})
        expect(strategy.id_token_claims).to be_nil
      end

      it 'returns nil without fetching JWKS when id_token is nil' do
        allow(access_token).to receive(:params).and_return({})
        strategy.id_token_claims
        expect(WebMock).not_to have_requested(:get, 'https://auth.login.yahoo.co.jp/yconnect/v2/jwks')
      end

      it 'raises on malformed id_token' do
        allow(access_token).to receive(:params).and_return({ 'id_token' => 'not-a-jwt' })
        expect { strategy.id_token_claims }.to raise_error(JSON::JWT::InvalidFormat)
      end

      context 'with invalid signature' do
        let(:wrong_key) { OpenSSL::PKey::RSA.generate(2048) }
        let(:bad_jwt_string) do
          jwt = JSON::JWT.new(jwt_payload)
          jwt.kid = kid
          jwt.sign(wrong_key, :RS256).to_s
        end

        before do
          allow(access_token).to receive(:params).and_return({ 'id_token' => bad_jwt_string })
        end

        it 'raises an error' do
          expect { strategy.id_token_claims }.to raise_error(JSON::JWS::VerificationFailed)
        end
      end

      context 'with invalid issuer' do
        let(:jwt_payload_bad_iss) { jwt_payload.merge('iss' => 'https://evil.example.com') }
        let(:bad_iss_jwt) do
          jwt = JSON::JWT.new(jwt_payload_bad_iss)
          jwt.kid = kid
          jwt.sign(rsa_key, :RS256).to_s
        end

        before do
          allow(access_token).to receive(:params).and_return({ 'id_token' => bad_iss_jwt })
        end

        it 'raises IdTokenValidationError' do
          expect { strategy.id_token_claims }.to raise_error(
            described_class::IdTokenValidationError, /Invalid issuer/
          )
        end
      end

      context 'with issuer missing /yconnect/v2 suffix' do
        let(:jwt_payload_wrong_iss) { jwt_payload.merge('iss' => 'https://auth.login.yahoo.co.jp') }
        let(:wrong_iss_jwt) do
          jwt = JSON::JWT.new(jwt_payload_wrong_iss)
          jwt.kid = kid
          jwt.sign(rsa_key, :RS256).to_s
        end

        before do
          allow(access_token).to receive(:params).and_return({ 'id_token' => wrong_iss_jwt })
        end

        it 'raises IdTokenValidationError' do
          expect { strategy.id_token_claims }.to raise_error(
            described_class::IdTokenValidationError, /Invalid issuer/
          )
        end
      end

      context 'with invalid audience' do
        let(:jwt_payload_bad_aud) { jwt_payload.merge('aud' => 'wrong_client_id') }
        let(:bad_aud_jwt) do
          jwt = JSON::JWT.new(jwt_payload_bad_aud)
          jwt.kid = kid
          jwt.sign(rsa_key, :RS256).to_s
        end

        before do
          allow(access_token).to receive(:params).and_return({ 'id_token' => bad_aud_jwt })
        end

        it 'raises IdTokenValidationError' do
          expect { strategy.id_token_claims }.to raise_error(
            described_class::IdTokenValidationError, /Invalid audience/
          )
        end
      end

      context 'with audience as array including client_id' do
        let(:jwt_payload_array_aud) { jwt_payload.merge('aud' => ['other_client', 'client_id']) }
        let(:array_aud_jwt) do
          jwt = JSON::JWT.new(jwt_payload_array_aud)
          jwt.kid = kid
          jwt.sign(rsa_key, :RS256).to_s
        end

        before do
          allow(access_token).to receive(:params).and_return({ 'id_token' => array_aud_jwt })
        end

        it 'accepts the token' do
          expect { strategy.id_token_claims }.not_to raise_error
        end
      end

      context 'with expired token' do
        let(:jwt_payload_expired) { jwt_payload.merge('exp' => Time.now.to_i - 60) }
        let(:expired_jwt) do
          jwt = JSON::JWT.new(jwt_payload_expired)
          jwt.kid = kid
          jwt.sign(rsa_key, :RS256).to_s
        end

        before do
          allow(access_token).to receive(:params).and_return({ 'id_token' => expired_jwt })
        end

        it 'raises IdTokenValidationError' do
          expect { strategy.id_token_claims }.to raise_error(
            described_class::IdTokenValidationError, /expired/
          )
        end
      end

      context 'with token within 30-second leeway' do
        let(:jwt_payload_just_expired) { jwt_payload.merge('exp' => Time.now.to_i - 10) }
        let(:leeway_jwt) do
          jwt = JSON::JWT.new(jwt_payload_just_expired)
          jwt.kid = kid
          jwt.sign(rsa_key, :RS256).to_s
        end

        before do
          allow(access_token).to receive(:params).and_return({ 'id_token' => leeway_jwt })
        end

        it 'accepts the token' do
          expect { strategy.id_token_claims }.not_to raise_error
        end
      end

      context 'with kid not found in JWKS' do
        let(:jwt_with_unknown_kid) do
          jwt = JSON::JWT.new(jwt_payload)
          jwt.kid = 'unknown-kid'
          jwt.sign(rsa_key, :RS256).to_s
        end

        before do
          allow(access_token).to receive(:params).and_return({ 'id_token' => jwt_with_unknown_kid })
        end

        it 'raises an error' do
          expect { strategy.id_token_claims }.to raise_error(StandardError)
        end
      end
    end

    describe '#raw_info' do
      context 'with userinfo_access: true' do
        let(:userinfo_response) do
          instance_double(OAuth2::Response, parsed: {
            'sub' => 'user456',
            'name' => 'Yahoo User',
            'email' => 'yahoo@example.com',
            'address' => { 'country' => 'JP' }
          })
        end

        before do
          allow(access_token).to receive(:get)
            .with('https://userinfo.yahooapis.jp/yconnect/v2/attribute')
            .and_return(userinfo_response)
        end

        it 'calls the UserInfo API' do
          strategy.raw_info
          expect(access_token).to have_received(:get)
            .with('https://userinfo.yahooapis.jp/yconnect/v2/attribute')
        end

        it 'sets access_token mode to header' do
          strategy.raw_info
          expect(access_token.options[:mode]).to eq(:header)
        end

        it 'returns parsed UserInfo response' do
          expect(strategy.raw_info['sub']).to eq('user456')
          expect(strategy.raw_info['name']).to eq('Yahoo User')
        end
      end

      context 'with userinfo_access: false and id_token present' do
        before do
          strategy.options[:userinfo_access] = false
        end

        it 'returns id_token_claims' do
          expect(strategy.raw_info['sub']).to eq('test123')
          expect(strategy.raw_info['name']).to eq('Test User')
        end

        it 'does not call the UserInfo API' do
          expect(access_token).not_to receive(:get)
          strategy.raw_info
        end
      end

      context 'with userinfo_access: false and no id_token' do
        before do
          strategy.options[:userinfo_access] = false
          allow(access_token).to receive(:params).and_return({})
        end

        it 'returns empty hash' do
          expect(strategy.raw_info).to eq({})
        end
      end
    end

    describe '#info' do
      let(:full_profile) do
        {
          'sub' => 'user456',
          'name' => 'Yahoo User',
          'given_name' => 'Taro',
          'given_name#ja-Kana-JP' => 'タロウ',
          'given_name#ja-Hani-JP' => '太郎',
          'family_name' => 'Yamada',
          'family_name#ja-Kana-JP' => 'ヤマダ',
          'family_name#ja-Hani-JP' => '山田',
          'gender' => 'male',
          'zoneinfo' => 'Asia/Tokyo',
          'locale' => 'ja-JP',
          'birthdate' => '1990-01-01',
          'nickname' => 'taro',
          'picture' => 'https://example.com/photo.jpg',
          'email' => 'taro@example.com',
          'email_verified' => true,
          'address' => { 'country' => 'JP', 'region' => 'Tokyo' }
        }
      end
      let(:userinfo_response) do
        instance_double(OAuth2::Response, parsed: full_profile)
      end

      before do
        allow(access_token).to receive(:get)
          .with('https://userinfo.yahooapis.jp/yconnect/v2/attribute')
          .and_return(userinfo_response)
      end

      it 'maps all standard fields' do
        info = strategy.info
        expect(info[:sub]).to eq('user456')
        expect(info[:name]).to eq('Yahoo User')
        expect(info[:given_name]).to eq('Taro')
        expect(info[:family_name]).to eq('Yamada')
        expect(info[:email]).to eq('taro@example.com')
        expect(info[:nickname]).to eq('taro')
        expect(info[:picture]).to eq('https://example.com/photo.jpg')
      end

      it 'maps Japanese locale-specific fields' do
        info = strategy.info
        expect(info[:given_name_ja_kana_jp]).to eq('タロウ')
        expect(info[:given_name_ja_hani_jp]).to eq('太郎')
        expect(info[:family_name_ja_kana_jp]).to eq('ヤマダ')
        expect(info[:family_name_ja_hani_jp]).to eq('山田')
      end

      it 'maps address as nested hash' do
        info = strategy.info
        expect(info[:address]['country']).to eq('JP')
      end

      it 'prunes nil values' do
        allow(userinfo_response).to receive(:parsed).and_return({ 'sub' => 'user456' })
        info = strategy.info
        expect(info).not_to have_key(:name)
        expect(info).not_to have_key(:email)
      end
    end

    describe '#uid' do
      context 'with userinfo_access: true' do
        let(:userinfo_response) do
          instance_double(OAuth2::Response, parsed: { 'sub' => 'user456' })
        end

        before do
          allow(access_token).to receive(:get)
            .with('https://userinfo.yahooapis.jp/yconnect/v2/attribute')
            .and_return(userinfo_response)
        end

        it 'returns sub from UserInfo' do
          expect(strategy.uid).to eq('user456')
        end
      end

      context 'with userinfo_access: false' do
        before do
          strategy.options[:userinfo_access] = false
        end

        it 'returns sub from id_token' do
          expect(strategy.uid).to eq('test123')
        end
      end
    end

    describe '#credentials' do
      it 'includes token' do
        expect(strategy.credentials['token']).to eq('mock_token')
      end

      it 'includes refresh_token' do
        expect(strategy.credentials['refresh_token']).to eq('mock_refresh')
      end

      it 'includes expires_at' do
        expect(strategy.credentials['expires_at']).to eq(1234567890)
      end

      it 'includes expires flag' do
        expect(strategy.credentials['expires']).to be true
      end

      it 'includes id_token' do
        expect(strategy.credentials['id_token']).to eq(jwt_string)
      end

      it 'omits id_token when not present' do
        allow(access_token).to receive(:params).and_return({})
        expect(strategy.credentials).not_to have_key('id_token')
      end
    end

    describe '#extra' do
      before do
        strategy.options[:userinfo_access] = false
      end

      it 'includes id_token' do
        expect(strategy.extra[:id_token]).to eq(jwt_string)
      end

      it 'includes id_token_claims' do
        claims = strategy.extra[:id_token_claims]
        expect(claims['sub']).to eq('test123')
      end

      it 'includes raw_info' do
        expect(strategy.extra[:raw_info]).not_to be_nil
      end
    end
  end
end
