require 'spec_helper'
require 'omniauth-yahoojp'

describe OmniAuth::Strategies::YahooJp do
  let(:strategy) { described_class.new(app, options) }
  let(:options) { {} }
  let(:app) { nil }

  describe "client options" do
    subject { strategy.options.client_options }

    its(:site) do
      should eq "https://auth.login.yahoo.co.jp"
    end

    its(:authorize_url) do
      should eq '/yconnect/v2/authorization'
    end

    its(:token_url) do
      should eq '/yconnect/v2/token'
    end

    its(:userinfo_url) do
      should eq 'https://userinfo.yahooapis.jp/yconnect/v2/attribute'
    end
  end

  describe 'userinfo access' do
    subject { strategy.options.userinfo_access }

    context 'as default' do
      it { should be_truthy }
    end

    context 'when disabled' do
      let(:options) do
        {userinfo_access: false}
      end
      it { should be_falsy }
    end
  end
end
