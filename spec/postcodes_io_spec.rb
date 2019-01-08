require_relative 'spec_helper'

describe "postcodes.io" do
  before(:all) { @api = Postcodes.new }
  let(:api) { @api }

  describe "/outcodes" do
    it "gets an outcode" do
      resp = api.outcodes.get('RM12')
      expect(resp.admin_district.first).to eq("Havering")
    end
  end

  describe "/postcodes" do
    context "GET" do
      it "gets a specific postcode" do
        resp = api.postcodes.get "OX49 5NU"
        expect(resp.status_code).to eq 200
      end


      it "gets nearest postcodes for a given longitude and latitude" do
        resp = api.postcodes.get(lon: 0.629834723775309, lat: 51.7923246977375)
        expect(resp.length).to be > 0
      end
    end

    context "POST" do
      it "does a bulk postal code lookup" do
        resp = api.postcodes.post(postcodes: ["OX49 5NU", "M32 0JG", "NE30 1DP"])
        expect(resp.length).to eq(3)
      end

      it "does bulk reverse geocoding" do
        doc = {
          "geolocations": [
            {
              "longitude":  0.629834723775309,
              "latitude": 51.7923246977375
            },
            {
              "longitude": -2.49690382054704,
              "latitude": 53.5351312861402,
              "radius": 1000,
              "limit": 5
            }
          ]
        }
        resp = api.postcodes.post(doc)
        expect(resp.length).to be > 0
      end
    end
  end

  describe "/random/postcodes" do
    context "GET" do
      it "gets a random postcode" do
        resp = api.random.postcodes.get
        expect(resp.status_code).to eq 200
      end
    end
  end
end
