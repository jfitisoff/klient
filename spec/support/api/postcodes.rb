# Partial implementation of API for https://api.postcodes.io
class Postcodes
  include Klient

  default_collection_accessor :result

  def initialize
    super("https://api.postcodes.io", content_type: :json, accept: :json)
  end

  collection :postcodes, identifier: :postcode

  resource :random do
    resource :postcodes
  end
end
