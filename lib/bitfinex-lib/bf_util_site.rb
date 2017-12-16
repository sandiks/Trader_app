require 'sequel'
require_relative 'db_util'

class BF_SiteUtil

  DB = BitfinexDB.get_db
  

  def self.date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end
  
  def self.config(key)
    case key
      when :group; DB[:config].first(name:'group')[:value].to_i
    end
  end
  
  def self.base_crypto
    config(:group) ==1 ? "BTC" : "ETH"
  end  

  def self.get_bid_ask

    DB[:my_ticks].to_hash(:symb,[:BID,:ASK])

  end

  def self.calc_max_buy(market_name)
    p market_name
    bids = DB[:my_ticks].filter(name:market_name).select_map(:ask)
    balances = BalanceUtil.balance_table
    btc = balances["BTC"] 
    btc/bids[0] rescue 0
  end 

  def self.calc_price_for_one_token(market_name)
    
    ask = DB[:my_ticks].filter(name:market_name).select_map(:ask).first
    if ask
     ask*TradeUtil.usdt_base
    else
     0
    end
  end 

####
  def self.get_balance_for_site

    data = DB[:wallets].filter(pid:2).all   
    
    rates = get_bid_ask 
    symbols=BitfinexDB.symb_hash
    usd_bid = rates[symbols['tETHUSD']][0]

    res=[]     
    data.each do |dd|

      curr=dd[:currency]
      
      balance=dd[:balance]
      bid=ask=1
      if curr!=base_crypto
        sid = symbols["t#{curr}ETH"]
        bid,ask =rates[sid] 
      end
      
      res<<{curr:curr,bid:bid,ask:ask,balance:balance,usd_balance:balance*usd_bid}
    end
    res
  end

  def self.table_tick
 
   
    lines_tr=[]
    lines_tr<< "<th>BID</th><th>ASK</th><th>QUANT</th><th>USDT bal</th><th>diff</th><th>pair</th>"
    symbols=BitfinexDB.symb_hash
    rates = get_bid_ask 
    
    data = get_balance_for_site
    data.each do |dd|

      curr=dd[:currency]
      balance=dd[:balance]||0
      bid,ask =rates[symbols["t#{curr}#{base_crypto}"]] 

      line ="" 
      line += "<td><b>#{ '%0.8f' % dd[:bid] }</b></td>" 
      line += "<td><b>#{'%0.8f' % dd[:ask]}</b></td>"
      line += "<td>#{'%0.8f' % balance}</td> "
      line += "<td>#{'%0.2f' % dd[:usd_balance] }</td> "

      line += "<td>diff</td>" 
      line += "<td><b>#{curr}</b></td>"
    
      lines_tr<<"<tr>#{line}</tr>"
    end
    
    eth_bid = rates[symbols["tETHUSD"]][0]
    btc_bid = rates[symbols["tBTCUSD"]][0]

    upd ="upd #{DateTime.now.strftime('%k:%M:%S')} "

    "#{upd}<br /> 
    ETH_USD price #{'%0.2f' % eth_bid} <br /> 
    BTC_USD price #{'%0.2f' % btc_bid} <br /> 
    USDT bal: #{'%0.2f' % 0}<br />
    <table class='forumTable' style='width:50%;'>#{lines_tr.join()}</table>"

  end

  def self.get_tracked_markets(tracked_level,pid=2) ##used -- controllers/trade.rb:

    tracked_pairs = DB[:tprofiles].filter(pid:get_profile, pumped:tracked_level, group:GROUP).select_map(:name)
    tracked=[]
    from = date_now(2)

    usd_btc_bid = TradeUtil.usdt_base
    
    all_data = DB[:hst_btc_rates].filter(Sequel.lit("(date > ? and name in ?)", from, tracked_pairs)).reverse_order(:date).select(:name,:bid,:ask).all

    tracked_pairs.each do |m_name|
      currency = m_name.sub('BTC-','')

      data = all_data.select{|dd|dd[:name] == m_name }
      next if data.size<1
      
      last_bid=data.first[:bid]
      last_ask=data.first[:ask]
      usdt_price = usd_btc_bid*last_bid

      last3=""
      if last_bid!=0
        last3=data.take(40).map { |dd| "#{'%4d' % (dd[:bid]/last_bid*1000)}" }.join(' ') 
      end
      tracked<< {name:m_name, usdt_price: usdt_price, last_bid:last_bid, last_ask:last_ask, hist_bids:last3 } 
    end

    tracked
  end

  def self.select_for_buy(list) ##used -- controllers/trade.rb:

    tracked=[]
    from = date_now(1)

    usd_btc_bid = TradeUtil.usdt_base
    balances = BalanceUtil.get_balance(usd_btc_bid)
    
    all_data = DB[:hst_btc_rates].filter(Sequel.lit("(date > ? and name in ?)", from, list)).reverse_order(:date).select(:name,:bid,:ask).all

    list.each do |m_name|
      currency = m_name.sub('BTC-','')

      data = all_data.select{|dd|dd[:name] == m_name }
      next if data.size<1
      last_bid=data.first[:bid]
      last_ask=data.first[:ask]
  
      bal = balances[currency]
      usdt_bal = bal ? bal[:usdt] : 0

      last3=data.take(15).map { |dd| "#{'%4d' % (dd[:bid]/last_bid*1000)}" }.join(' ') 
      tracked<< {name:m_name, usdt: usdt_bal, last_bid:last_bid, last_ask:last_ask, hist_bids:last3 } 
    end

    tracked
  end  
  
  def self.line_tick

    ticks = DB[:my_ticks].all
    res=[]
    ticks.each do |tt|
      if tt[:name]=="USDT-BTC"
       res<< "<tr><td>#{tt[:name]}</td> <td> #{'%0.0f' % tt[:bid]}</td> <td>  #{'%0.f' % tt[:ask]}</td></tr>"
      else
       res<< "<tr><td> <b>#{tt[:name]}</b></td> <td> #{'%0.8f' % tt[:bid]}</td> <td> #{'%0.8f' % tt[:ask]}</td></tr>"
      end
    end
    table = "<table class='forumTable' style='width:30%;'>#{res.join()}</table>"
    upd ="upd #{DateTime.now.strftime('%k:%M:%S')}<br /> #{table}"
  end

  def self.bot_sold
    from = date_now(5)
    ord = DB[:bot_trading].filter( Sequel.lit("date > ? and finished=1", from, list)).all
    
    res=[]
    ticks.each do |tt|
      if tt[:name]=="USDT-BTC"
       res<< "<tr><td>#{tt[:name]}</td> <td> #{'%0.0f' % tt[:bid]}</td> <td>  #{'%0.f' % tt[:ask]}</td></tr>"
      else
       res<< "<tr><td> <b>#{tt[:name]}</b></td> <td> #{'%0.8f' % tt[:bid]}</td> <td> #{'%0.8f' % tt[:ask]}</td></tr>"
      end
    end
    table = "<table class='forumTable' style='width:30%;'>#{res.join()}</table>"
    upd ="upd #{DateTime.now.strftime('%k:%M:%S')}<br /> #{table}"
  end

end


