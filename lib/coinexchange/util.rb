require 'sequel'
require_relative 'client'


module CoinExchange

  class Util

    DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'coinexch', user: 'root')
    PID=2

    def self.date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end
    
    def self.get_all_bid_ask
      DB[:my_ticks].where{bid>0}.to_hash(:name,[:bid,:ask])
    end
    
    def self.save_to_ticks(mid, bid, ask)
      rr = { bid: bid, ask: ask }
      DB[:my_ticks].filter(name: mid).update(rr)
    end

    def self.save_to_rates(mid, bid, ask)
      rr = {mid:mid, bid:bid, ask:ask, date:date_now(0)}
      DB[:hst_rates].insert(rr)
    end

    def self.save_markets(data) #need show open orders  
      DB.transaction do
        exist=DB[:markets].select_map(:MarketID)
        data.each do |dd|
          if !exist.include?(dd['MarketID'])
            DB[:markets].insert(dd)
          end
        end
      end
    end

    def self.get_markets #need show open orders  
      DB[:markets].to_hash(:MarketID,:MarketAssetName)
    end

    def self.get_mark_prices  
      DB[:buy_mark_prices].to_hash(:mid,:price)
    end
    
    def self.save_currencies(data) #need show open orders
      DB.transaction do

        exist=DB[:currencies].select_map(:CurrencyID)

        data.each do |dd|
          if !exist.include?(dd['CurrencyID'])
            DB[:currencies].insert(dd)
          end
        end

      end

    end

    def self.save_all_rates(data)

      DB.transaction do
        data.each do |tt|
          mid =tt['MarketID'].to_i          
          rr = {mid:mid, bid:tt['BidPrice'], ask:tt['AskPrice'], date:date_now(0)}
          DB[:hst_rates].insert(rr)
        end
      end

    end

    def self.save_wallet(wallet) #need show open orders
      DB[:wallets].delete
      wallet.each do |ww|
        DB[:wallets].insert({pid:2, type:ww[0],currency:ww[1], balance:ww[2], available:ww[4] })
      end
    end   

 
  end
end

def init
  #data = CoinExchange::Client.new.get_markets
  #CoinExchange::Util.save_markets(data)

  #data = CoinExchange::Client.new.get_currencies
  #CoinExchange::Util.save_currencies(data)
  #p data = CoinExchange::Client.new.get_market_summary(473)
p CoinExchange::Client.new.get_order_book(473)['SellOrders']

end

