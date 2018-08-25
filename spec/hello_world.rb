require_relative 'support/spec_helper'

describe "postcodes.io" do
  before(:all) { @api = Postcodes.new }
  let(:api) { @api }

  context "/postcodes" do
    context "GET" do
      it "gets a specific postcode" do
        resp = api.postcodes.get "OX49 5NU"
        expect(resp.code).to eq 200
      end
    end

# "postcodes" : ["OX49 5NU", "M32 0JG", "NE30 1DP"]
    context "POST" do
      it "does a bulk lookup of multiple postal codes" do
        doc = <<~eos
          {
            "postcodes" : ["OX49 5NU", "M32 0JG", "NE30 1DP"]
          }
        eos
# binding.pry
        resp = api.postcodes.post doc
        puts resp

        expect(resp.code).to eq 200
      end
    end
  end


  context "/random/postcodes" do
    context "GET" do
      it "gets a random postcode" do
        resp = api.random.postcodes.get
        expect(resp.code).to eq 200
      end
    end
  end
end
