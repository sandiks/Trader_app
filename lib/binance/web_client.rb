require 'binance'

module Binance

  class WebClient
    
    attr_reader :key, :secret
    attr_accessor :client

    DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'binance', user: 'root')

    def initialize(attrs = {})
      @key    = attrs[:key]
      @secret = attrs[:secret]
      @client = Binance::Client::REST.new 

    end    
 
  end

end
