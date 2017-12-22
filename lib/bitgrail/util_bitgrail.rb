require 'dotenv'
require 'sequel'

require_relative 'bitgrail_api'

Dotenv.load('.env')

class BitgrailUtil

  def self.date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end
  
  BTG_DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitgrail', user: 'root')

  def  self.save_to_ticks(symb,bid,ask)

    rr = {bid:bid, ask:ask }
    BTG_DB[:my_ticks].filter(symb:symb).update(rr)
  end

  def  self.save_to_rates(symb, bid,ask)

      rr = {symb:symb, bid:bid, ask:ask, date:date_now(0)}
      BTG_DB[:hst_rates].insert(rr)
  end

  def  self.show_order_book(symb="")
      symb="BTC-XRB"
      orders = get_order_book(symb)

      orders['asks'].take(10).each do |ord| 
          p "price: %0.8f  amount: %0.8f" % [ ord['price'], ord['amount'] ]
      end

  end

  def self.get_bid_ask_from_tick(mname) 
    dd = BTG_DB[:my_ticks].first(symb:mname)
    [dd[:bid],dd[:ask]]
  end 

end

#set_db
#update_bitgrail_tickers
#show_order_book