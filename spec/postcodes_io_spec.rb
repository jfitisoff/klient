require_relative 'spec_helper'

describe "postcodes.io" do
  before(:all) { @api = Postcodes.new }
  let(:api) { @api }

  context "/postcodes" do
    context "GET" do
      it "gets a specific postcode" do
        resp = api.postcodes.get "OX49 5NU"
        expect(resp.status_code).to eq 200
      end
    end

    context "POST" do
      it "does a bulk postal code lookup" do
        resp = api.postcodes.post(postcodes: ["OX49 5NU", "M32 0JG", "NE30 1DP"])
        expect(resp.length).to eq(3)
      end
    end
  end

  context "/random/postcodes" do
    context "GET" do
      it "gets a random postcode" do
        resp = api.random.postcodes.get
        expect(resp.status_code).to eq 200
      end
    end
  end
end
