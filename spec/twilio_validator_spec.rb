require 'spec_helper'

describe Rack::TwilioValidator do
  let(:auth_token) { "5cc8534fb3f86ff7e52d884562bcca18" }
  let(:params) { { :foo => "fizz", :bar => "buzz" } }
  let(:valid_signature) { "4C3R3E2C2TwiOkEwqznWMH1k3O8=" }
  let(:uri) { "/twilio/endpoint"}

  let(:app) {
    Rack::Builder.new do
      use Rack::TwilioValidator, :auth_token => "5cc8534fb3f86ff7e52d884562bcca18"
      run lambda { |env| [200, {'Content-Type' => "text/plain"}, ["OK"]] }
    end
  }

  context "a valid signature" do
    it "is ok" do
      post(uri, params, "HTTP_X_TWILIO_SIGNATURE" => valid_signature)
      last_response.should be_ok
    end
  end

  context "an invalid signature" do
    before do
      post(uri, params, "HTTP_X_TWILIO_SIGNATURE" => "bad_signature")
    end

    it "is unauthorized" do
      last_response.status.should == 401
    end

    it "provides a TwiML error" do
      last_response.body.should include("<Response><Say>Unable to authenticate request. Please try again.</Say></Response>")
    end
  end

  context "a missing signature" do
    it "is unauthorized" do
      post(uri, params, "HTTP_X_TWILIO_SIGNATURE" => nil)
      last_response.status.should == 401
    end
  end

  context "when a protected path is supplied" do
    let(:app) {
      Rack::Builder.new do
        use Rack::TwilioValidator, :auth_token => "5cc8534fb3f86ff7e52d884562bcca18", :protected_path => "/twilio"
        run lambda { |env| [200, {'Content-Type' => "text/plain"}, ["OK"]] }
      end
    }

    it "checks actions under the protected path" do
      post("/twilio/endpoint", params, "HTTP_X_TWILIO_SIGNATURE" => "bad_signature")
      last_response.status.should == 401
    end

    it "skips actions outside the protected path" do
      post("/other/endpoint", params, "HTTP_X_TWILIO_SIGNATURE" => "bad_signature")
      last_response.should be_ok
    end
  end
end