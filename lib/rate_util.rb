require 'sequel'

class RateUtil

  BF_DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitfinex', user: 'root')
  BN_DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'binance', user: 'root')
  PID=2

  def self.date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end
  
  def self.get_binance_db
    Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitfinex', user: 'root')
  end
  
  def self.symb_hash
    DB[:symbols].to_hash(:name, :symbol_id)
  end
  
  def self.get_bid_ask_from_tick(mname)
    BN_DB[:my_ticks].filter(name:mname).select_map([:bid,:ask]).first
  end

  def self.get_all_bid_ask

    #BF_DB[:my_ticks].to_hash(:symb,[:BID,:ASK])
    BN_DB[:my_ticks].to_hash(:name,[:bid,:ask])

  end

end