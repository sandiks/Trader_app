require 'sequel'

require_relative 'client'

module  Cryptopia
  module Util
    
    DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'cryptopia', user: 'root')

    def self.date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end

    def self.save_markets
      data = api_query("GetMarkets" )

      DB.transaction do
        data.each do |dd|

          DB[:markets].insert(dd)
        end
      end
    end

    def self.fetch_markets_and_save_to_rates
      #data = api_query("GetMarkets", market_list)
      data = api_query("GetMarkets")
      DB.transaction do
        data.each do |dd|
          
          trade_pair_id = dd['TradePairId']
          label = dd['Label']
          bid,ask = dd['BidPrice'],dd['AskPrice']
          
          if label.end_with?('/BTC')
           rr={mid: trade_pair_id, bid:bid,ask:ask, date:date_now(0) }
           DB[:hst_rates].insert(rr)
          end

        end
      end
    end 

    def self.get_market(mid)
      data = api_query("GetMarket", [ mid])

    end    

    def self.get_mark_prices  
      DB[:buy_mark_prices].to_hash(:mid,:price)
    end
        
    def self.get_markets_from_db
      DB[:markets].to_hash(:TradePairId, :Label)
    end

    def self.save_to_ticks(mid, bid, ask)
      rr = { bid: bid, ask: ask }
      DB[:my_ticks].filter(name: mid).update(rr)
    end

  end
end

#Cryptopia::Util.save_markets

#Cryptopia::Util.get_market(5141) rescue 0