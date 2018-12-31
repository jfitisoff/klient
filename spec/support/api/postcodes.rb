# Partial implementation of API for https://api.postcodes.io
class Postcodes
  include Klient

  default_collection_accessor :result

  headers do
    { content_type: :json, accept: :json }
  end

  def initialize
    super("https://api.postcodes.io")
  end

  collection :postcodes do |postcode|
    resources :autocomplete, :nearest, :validate
  end

  collection :outcodes do |outcode|
    resource :nearest
  end

  resource :random do
    resource :postcodes
  end

  collection :terminated_postcodes do |postcode|
  end
end
