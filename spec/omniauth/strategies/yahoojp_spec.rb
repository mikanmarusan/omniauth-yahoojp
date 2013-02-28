require 'spec_helper'
require 'omniauth-yahoojp'

describe OmniAuth::Strategies::YahooJp do

  subject do
    OmniAuth::Strategies::YahooJp.new({})
  end

  context "client options" do
    it 'should have correct site' do
      subject.options.client_options.site.should eq("https://auth.login.yahoo.co.jp")
    end

    it 'should have correct authorize url' do
      subject.options.client_options.authorize_url.should eq('/yconnect/v1/authorization')
    end

    it 'should have correct token url' do
      subject.options.client_options.token_url.should eq('/yconnect/v1/token')
    end
  end
end
