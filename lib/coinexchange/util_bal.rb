require 'sequel'
require_relative 'client'

module CoinExchange
  class BalanceUtil

    def self.date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end
    
    DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'coinexch', user: 'root')
    BF_DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitfinex', user: 'root')
    
    def self.get_profile
      2
      #type=='simulate' ? 1 : 2
    end     
    def self.base_curr
       "ETH"
    end

    def self.btc_usd
      usd_bid = BF_DB[:my_ticks].filter(symb:3).select(:bid,:ask).first
    end

    def self.my_btc
       DB[:balances].filter(curr:'BTC').first[:balance] 
    end
  
    def self.get_bid_ask_from_tick(mid) 
      DB[:my_ticks].filter(name:mid).select_map([:bid,:ask]).first
    end    
     
    def self.get_all_bid_ask
      DB[:my_ticks].where{bid>0}.to_hash(:name,[:bid,:ask])
    end

    def self.name_to_market_id(base="BTC")
      DB[:markets].filter(BaseCurrencyCode:base).to_hash(:MarketAssetCode,:MarketID)
    end
    def self.marketId_to_name(mid,base="BTC")
      DB[:markets].first(MarketID:mid,BaseCurrencyCode:base)[:MarketAssetCode] rescue nil
    end

    def self.get_hist_trades(symb)
      last_trades = DB[:hst_trades].filter(market:symb).reverse_order(:date).limit(10).all
    end

    def self.last_buy_trade(symb)
       DB[:hst_trades].filter(market:symb, type:'buy').reverse_order(:date).first
    end 
  
    ### simulator
    def self.add_to_simul(mid)
      p "add_to_simul"
      ask = BalanceUtil.get_bid_ask_from_tick(mid)[1] rescue 0
      DB[:simul_markets].filter(pid:get_profile,mid:mid).delete
      DB[:simul_markets].insert({pid:get_profile,mid:mid, ppu:ask, buy_time: date_now(0)})
    end

    def self.new_simul_price_mark(mid)
      
      ask = BalanceUtil.get_bid_ask_from_tick(mid)[1] rescue 0
      DB[:simul_markets].filter(pid:get_profile,mid:mid).update({ppu:ask, buy_time: date_now(0)})
    end


    def self.delete_from_simul(mid)
      DB[:simul_markets].filter(pid:get_profile,mid:mid).delete
    end 

    def self.rebalance(curr,q)
      p "rebalance"
      DB[:wallets].filter(currency:curr).update({balance:q})
    end    

  end
end
