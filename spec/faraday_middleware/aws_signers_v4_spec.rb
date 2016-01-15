describe FaradayMiddleware::AwsSignersV4 do
  let(:response) do
    {"accountUpdate"=>
      {"name"=>nil,
       "template"=>false,
       "templateSkipList"=>nil,
       "title"=>nil,
       "updateAccountInput"=>nil},
     "cloudwatchRoleArn"=>nil,
     "self"=>
      {"__type"=>
        "GetAccountRequest:http://internal.amazon.com/coral/com.amazonaws.backplane.controlplane/",
       "name"=>nil,
       "template"=>false,
       "templateSkipList"=>nil,
       "title"=>nil},
     "throttleSettings"=>{"burstLimit"=>1000, "rateLimit"=>500.0}}
  end

  let(:signed_headers) do
    'host;user-agent;x-amz-content-sha256;x-amz-date'
  end

  let(:default_expected_headers) do
    {"User-Agent"=>"Faraday v0.9.1",
     "host"=>"apigateway.us-east-1.amazonaws.com",
     "x-amz-date"=>"20150101T000000Z",
     "x-amz-content-sha256"=>
      "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
     "authorization"=>
      "AWS4-HMAC-SHA256 Credential=akid/20150101/us-east-1/apigateway/aws4_request, " +
      "SignedHeaders=#{signed_headers}, " +
      "Signature=#{signature}"}
  end

  let(:additional_expected_headers) { {} }

  let(:expected_headers) do
    default_expected_headers.merge(additional_expected_headers)
  end

  let(:client) do
    faraday do |stub|
      stub.get('/account') do |env|
        expect(env.request_headers).to eq expected_headers
        [200, {'Content-Type' => 'application/json'}, JSON.dump(response)]
      end
    end
  end

  before do
    stub_const('Faraday::VERSION', '0.9.1')
  end

  context 'without query' do
    let(:signature) do
      'd25bb10ed5b6735974a3d1e0bae0bd8e4e28bddfd03a39e3e9ada780d54990a7'
    end

    subject { client.get('/account').body }

    it { is_expected.to eq response }
  end

  context 'with query' do
    subject { client.get('/account', params).body }

    context 'include space' do
      let(:signature) do
        '1fab19a15836760910137069dfe5393a758047569f5efd276e09d3f40bc8e166'
      end

      let(:params) { {foo: 'b a r', zoo: 'b a z'} }

      it { is_expected.to eq response }
    end

    context 'not include space' do
      let(:signature) do
        'be8933a42d7517c7a9fba59f5440a3f920f21252376931c0dedeebf6c7d507eb'
      end

      let(:params) { {foo: 'bar', zoo: 'baz'} }

      it { is_expected.to eq response }
    end
  end

  context 'use net/http' do
    subject { client.get('/account').body }

    let(:signature) do
      'a1abb29af96761771fdf914527a97acbf1cfd72cbd7a23379a5b36f5b2c9d5eb'
    end

    let(:signed_headers) do
      'accept;accept-encoding;host;user-agent;x-amz-content-sha256;x-amz-date'
    end

    let(:additional_expected_headers) do
      {"Accept"=>"*/*",
       "Accept-Encoding"=>"gzip;q=1.0,deflate;q=0.6,identity;q=0.3"}
    end

    before do
      expect_any_instance_of(FaradayMiddleware::AwsSignersV4).to receive(:net_http?) { true }
    end

    it { is_expected.to eq response }
  end
end
