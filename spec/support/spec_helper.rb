require 'klient'
require 'json'

class Postcodes
  include Klient

  def initialize
    super(
      "https://api.postcodes.io",
      {content_type: :json, accept: :json}
    )
  end

  resource :postcodes do |postcode|
  end

  resource :random do
    resource :postcodes
  end
end
