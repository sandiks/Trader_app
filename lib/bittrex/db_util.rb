require 'sequel'

DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'trading', user: 'root')
PID=2

def get_db
  Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'trading', user: 'root')
end

def get_bitfinex_db
  Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitfinex', user: 'root')
end

def date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end


def save_tick_to_db(mname,dd)
  return if mname.start_with?("USDT-")

  #DB.run("truncate table my_ticks") 
  DB[:my_ticks].filter(name:mname).delete
  rr = {name:mname,last:dd['Last'], bid:dd['Bid'], ask:dd["Ask"] }
  DB[:my_ticks].insert(rr)
end

def get_trading_mode
  type = DB[:config].first(name:'trade_type')[:value]
end 

def get_profile
  type = DB[:config].first(name:'trade_type')[:value]
  type=='simulate' ? 1 : 2
end 

def toggle_real_simulate

  type = DB[:config].first(name:'trade_type')[:value]
  type = (type=='simulate' ? 'real' : 'simulate')

  DB[:config].filter(name:'trade_type').update(value:type)
  return type
end

def config(key)
  case key
    when :simulate; DB[:config].first(name:'trade_type')[:value]=='simulate'
    when :real; DB[:config].first(name:'trade_type')[:value]=='real'
    when :group; DB[:config].first(name:'group')[:value].to_i
  end
end

def base_group
  config(:group) 
end

def base_crypto
  config(:group) ==1 ? "BTC" : "ETH"
end

def base_pair(curr='')
  config(:group) ==1 ? "BTC-#{curr}" : "ETH-#{curr}"
end


def save_markets_summaries(direct=true, reload_market=false)
  
  data = BittrexApi.new.get_markets_summaries(direct)

  DB.run("truncate table markets") if reload_market

  DB.transaction do

    data.each do |dd|
      # "#{dd["MarketName"]} vol: #{dd["BaseVolume"]} time_stamp: #{dd["TimeStamp"]}" }
      item = {
        name: dd["MarketName"],
        High: dd["High"],
        Low: dd["Low"],
        Volume: dd["Volume"],
        Last: dd["Last"],
        BaseVolume: dd["BaseVolume"],
        TimeStamp: dd["TimeStamp"],
        Bid: dd["Bid"],
        Ask: dd["Ask"],
        OpenBuyOrders: dd["OpenBuyOrders"],
        OpenSellOrders: dd["OpenSellOrders"],
        PrevDay: dd["PrevDay"],
        Created: dd["Created"]
      }
      DB[:markets].insert(item) if reload_market
    end
    ##save to rates
    data.each{ |dd|
      rr = {name:dd["MarketName"],last:dd["Last"], bid:dd["Bid"], ask:dd["Ask"], date:date_now(0) }
      DB[:hst_btc_rates].insert(rr) if dd["MarketName"].start_with?("BTC-")
      DB[:hst_eth_rates].insert(rr) if dd["MarketName"].start_with?("ETH-")
      DB[:hst_usdt_rates].insert(rr) if dd["MarketName"].start_with?("USDT-")
    }

  end
end

def save_log(type, text)
  DB[:bot_logs].insert({type:type, info:text, date: now})
end

def copy_market_to_profile
  all = DB[:markets].filter(Sequel.like(:name, 'BTC-%')).select_map(:name)
  all<<"USDT-BTC"
  DB.transaction do
    exist = DB[:tprofiles].filter(pid:get_profile).select_map(:name)
    all.each do |mm|

      group= (mm.start_with?("BTC-") ? 1 : 2)
      DB[:tprofiles].insert({pid:get_profile, name:mm, group: group, enabled:1}) if !exist.include?(mm)
    end
  end
end

def copy_market_to_market_ids
  market_names = DB[:markets].filter(Sequel.like(:name, 'BTC-%')).order(:Created).select_map([:name, :Created])

  DB.transaction do
    exist = DB[:market_ids].select_map(:name)
    indx=0
    market_names.each do |mname,created|

      if !exist.include?(mname)
       indx+=1
       DB[:market_ids].insert({id: indx, name:mname, created: created}) 
       p "--insert #{mname}"
      end

    end
  end
end

def copy_market_to_ticks
  market_names = DB[:markets].filter(Sequel.like(:name, 'ETH-%')).order(:Created).select_map([:name, :Created])

  DB.transaction do
    exist = DB[:my_ticks].filter(base:base_group).select_map(:name)
    indx=0
    market_names.each do |mname,created|

      if !exist.include?(mname)
       indx+=1
       DB[:my_ticks].insert({base: base_group, name:mname}) 
       p "--insert #{mname}"
      end

    end
  end
end

#copy_market_to_ticks

def del_rates
  from = date_now(48)
  p DB[:hst_btc_rates].filter(Sequel.lit("date < ?", from)).delete
end

def map_buy_sell_orders_to_group(b_orders, s_orders, mname)
  
  not_correct = b_orders.nil? || s_orders.nil?
  return "orders empty" if not_correct 

  all = b_orders+s_orders
  empty=DB[:my_hist_buy_sell_orders].filter(Sequel.lit("market=? and ord_uuid in ?", mname, all)).empty?
  return "orders already in group" if  !empty

  group = DB.fetch(Sequel.lit("SELECT max(`orders_group`) as max FROM my_hist_buy_sell_orders where market=?", mname)).select_map(:max).first
  group = group.to_i+1

  DB.transaction do
    s_orders.each do |ord|
      rr = {market:mname, ord_uuid: ord, type:"SELL",  orders_group:group, created:date_now(0)}
      DB[:my_hist_buy_sell_orders].insert(rr)
    end

    b_orders.each do |ord|
      rr = {market:mname, ord_uuid: ord, type:"BUY",  orders_group:group, created:date_now(0)}
      DB[:my_hist_buy_sell_orders].insert(rr)
    end

  end
  group
end

def copy_to_bot_trading(mname, orders_uuid)
  
  not_correct = orders_uuid.nil? 
  return "orders empty" if not_correct 

  orders = DB[:my_hst_orders].filter(OrderUuid:orders_uuid).select(:OrderUuid,:Limit,:Quantity,:Closed )
  
  DB.transaction do

    orders.each do |ord|
      uuid=ord[:OrderUuid]

      unless DB[:bot_trading].first(ord_uuid:uuid)
        rr = {ord_uuid:ord[:OrderUuid], name:mname, quant: ord[:Quantity],ppu:ord[:Limit], bought_at:ord[:Closed]}
        DB[:bot_trading].insert(rr)
      end
    end

  end
  orders_uuid
end