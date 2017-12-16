require 'dotenv'
require 'bitfinex-rb'
require 'rufus-scheduler'

require_relative 'bitfinex-lib/db_util'
Dotenv.load('.env')

class BitfinexBot

    BASE_URL = "https://api.bitfinex.com/v2/"
    API_KEY = ENV["BF_API_KEY"]
    API_SECRET = ENV["BF_SECRET"]


  Bitfinex::Client.configure do |conf|
      conf.secret = API_SECRET
      conf.api_key = API_KEY
      conf.use_api_v2
  end

  def self.get_wallet
    client = Bitfinex::Client.new
    ww=client.wallets
    BitfinexDB.save_wallet(ww)

  end

end