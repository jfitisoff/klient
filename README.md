# klient
A REST client library I'm working on. I've only recently started on it and it has a long way to go before it might be worth using.

## postcodes.io client example:
```ruby
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

resource = api.postcodes.get "OX49 5NU"
=> #<Postcodes::Postcodes:70141412425480 @url="https://api.postcodes.io/postcodes">

# Most recent HTTP status for resource:
resource.status_code
=> 200

# Resource delegates method calls down to last response ('results' isn't a
# defined method call: It's just part of the document that's getting returned.):
resource.result.parish
=> "Brightwell Baldwin"

# Postcode bulk lookup. Collection responses are arrays right now, next step is
# to create a collection class that stores headers, allows pagination etc.
results = api.postcodes.post(postcodes: ["OX49 5NU", "M32 0JG", "NE30 1DP"])
=> [#<Postcodes::Postcodes:70243439926840 @url="https://api.postcodes.io/postcodes/OX49%205NU">,
 #<Postcodes::Postcodes:70243439926340 @url="https://api.postcodes.io/postcodes/M32%200JG">,
 #<Postcodes::Postcodes:70243439925820 @url="https://api.postcodes.io/postcodes/NE30%201DP">]

# Gets a random postcode.
# BUG: Note that in the case below the constructed resource doesn't include the
# resource identifier. (The test works because the response data is handled
# properly.) I plan to add support to infer/define (both) the type of resource
# that should be built when processing responses. Know what I'm going to do,
# just need to get to it.
resource = api.random.postcodes.get
=> #<Postcodes::Random::Postcodes:70243435956120 @url="https://api.postcodes.io/random/postcodes">
resource.result.postcode
=> "PO20 2WA"
```
