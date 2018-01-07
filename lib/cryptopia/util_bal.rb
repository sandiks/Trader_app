require 'sequel'
require_relative 'client'

module Cryptopia
  class BalanceUtil

    def self.date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end
    
    DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'cryptopia', user: 'root')
    BF_DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitfinex', user: 'root')
    
    def self.base_curr
       "ETH"
    end

    def self.btc_usd
      usd_bid = BF_DB[:my_ticks].filter(symb:3).select(:bid,:ask).first
    end

    def self.my_btc
       DB[:balances].filter(curr:'BTC').first[:balance] 
    end
     
    def self.get_all_bid_ask
      DB[:my_ticks].where{bid>0}.to_hash(:name,[:bid,:ask])
    end

    def self.symb_hash
      DB[:markets].to_hash(:Label, :TradePairId)
    end

    def  self.show_order_book(symb="")
        symb="BTC-XRB"
        orders = get_order_book(symb)

        orders['asks'].take(10).each do |ord| 
            p "price: %0.8f  amount: %0.8f" % [ ord['price'], ord['amount'] ]
        end

    end

    def self.get_hist_trades(symb)
      last_trades = DB[:hst_trades].filter(market:symb).reverse_order(:date).limit(10).all
    end

    def self.last_buy_trade(symb)
       DB[:hst_trades].filter(market:symb, type:'buy').reverse_order(:date).first
    end 

 
    

  end
end
