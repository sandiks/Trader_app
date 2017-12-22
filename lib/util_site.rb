require 'sequel'
require 'json'
#require 'dotenv'
require_relative 'bittrex_api'
require_relative 'price_analz'
require_relative 'db_util'

class SiteUtil

  DB = get_db
  BFDB = get_bitfinex_db

  GROUP = config(:group)
  
  def self.bittrex_api
    BittrexApi.new
  end

  def self.date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end

  def self.calc_max_buy(ask)
    balances = BalanceUtil.balance_table
    balances["BTC"][1]/ask rescue -1
  end 

  def self.line_tick

    data = BalanceUtil.get_balance.sort_by{|k,v| v[:usdt]}
    res=[]

    table_headers=[]
    
    data.each do |mname,tt|
      next if mname==base_crypto
      res<< "<th>#{mname}</th>"
      res<< "<tr><td><b>#{'%0.8f' % tt[:bid]} #{'%0.8f' % tt[:ask]} </b></td></tr>"
    end
 

    ["BTC-XRB"].each do |mname|

      bid,ask = BitgrailUtil.get_bid_ask_from_tick(mname)
      res<< "<th> Bitgrail- #{mname}</th>"
      res<< "<tr><td><b>#{'%0.8f' % bid} #{'%0.8f' % ask} </b></td></tr>"
    end

    symbols_ids=BitfinexDB.symb_hash

    ["EOSETH"].each do |symb|
      bid,ask = BitfinexDB.get_bid_ask_from_tick(symbols_ids[symb])
      res<< "<th> Bitfinex - #{symb}</th>"
      res<< "<tr><td><b>#{'%0.8f' % bid} #{'%0.8f' % ask} </b></td></tr>"
    end

    btc_price="#{'%4.0f' % TradeUtil.usdt_base}"
    usdt_sum = data.inject(0){|ss,x| ss+=x[1][:usdt]}
    btc_sum =  data.inject(0){|ss,x| ss+=x[1][:btc]}
    
    bf_btc_price = BFDB[:hst_rates].filter(symb:3).reverse_order(:date).limit(10).select_map(:bid)
    .select.with_index { |x, i| i<10 || i % 5 == 0 }
    .map { |dd|  '%6.0f' % dd }.join(', ') 


    info = "#{DateTime.now.strftime('%k:%M:%S')}<br /> 
    #{base_crypto} price #{btc_price} <br /> 
    BTC bitfinex  #{ bf_btc_price } <br /> 
    USDT bal: #{'%0.2f' % usdt_sum}<br />
    #{base_crypto} bal: #{'%0.8f' % btc_sum}<br />"

    table = "#{info} <br />
    <table class='forumTable' style='width:20%;'>
    #{res.join()} 
    </table>"

    #upd ="#{DateTime.now.strftime('%k:%M:%S')}<br /> #{table}"
  end


  def self.calc_price_for_one_token(market_name)
    
    ask = DB[:my_ticks].filter(name:market_name).select_map(:ask).first
    if ask
     ask*TradeUtil.usdt_base
    else
     0
    end
  end 


  def self.table_tick
        
    data = BalanceUtil.get_balance_for_site.sort_by{|dd| dd[:usdt]}

    lines_tr=[]
    lines_tr<< 
    "<th>balance</th> 
    <th>available</th> 
    <th>USDT bal</th> 
    <th style='width:10%;'>BID</th> 
    <th style='width:10%;'>ASK</th> 
    <th style='width:7%;'>diff</th> 
    <th style='width:10%;'>pair</th>
    <th style='width:30%;'>actions</th>"
    
    data.each do |dd|
      next if dd[:usdt] ==0
      
      line ="" 
      line += "<td>#{'%0.4f' %dd[:balance]}</td> "
      line += "<td>#{'%0.4f' %dd[:available]}</td> "
      line += "<td>#{'%0.2f' % (dd[:usdt]||0)}</td> "
      line += "<td><b>#{ '%0.8f' % dd[:last_bid] }</b></td>" 
      line += "<td><b>#{'%0.8f' % dd[:last_ask]}</b></td>"

      line += "<td>#{dd[:diff]}</td>" 
      line += "<td><b>#{dd[:currency]}</b></td>"
    
      btn_buy_code = "<button class='btn_tick_table_buy btn_style_green' data-curr='#{dd[:currency]}'> *BUY* </button>"
      txt_code = "<input type='text' name='q' size='5' value='#{ '%0.3f' % (dd[:op_amount]||0) }'>"
      btn_sell_code = "<button class='btn_tick_table_sell btn_style_green' data-curr='#{dd[:currency]}'> *SELL* </button>"
      
      btn_rate_code = "<button class='btn_currency_bid_ask btn_style_blue' data-curr='#{dd[:currency]}'>RATE</button>"
   
      line += "<td> #{btn_buy_code} #{txt_code} #{btn_sell_code} #{btn_rate_code}</td>"   
      line += "<td style='width:20%;'>#{dd[:orders_info]}</td>" 
      lines_tr<<"<tr>#{line}</tr>"
    end
    lines_tr<< 
    "<th colspan='3'></th> 
    <th>BID</th> 
    <th>ASK</th> 
    <th>diff</th> 
    <th style='width:10%;'>pair</th>
    <th style='width:30%;'>actions</th>"

    simul_curr =  DB[:simul_trades].filter(pid:get_profile, base_crypto: base_group).all
    simul_curr.each do |curr|

      bid,ask = TradeUtil.get_bid_ask_from_market(curr[:pair]) 
      diff = (bid||0)/ curr[:ppu] *100 
      
      line ="" 
      line += "<td colspan='3'></td>" 
      line += "<td><b>#{ '%0.8f' % (bid||0) }</b></td>" 
      line += "<td><b>#{ '%0.8f' % (ask||0) }</b></td>" 
      line += "<td>#{ '%0.1f' % diff  }</td>" 
      line += "<td><b>#{ curr[:pair] }</b></td>"
      btn_delete_code = "<button class='btn_tick_table_delete_simul_pair btn_style_green' data-curr='#{curr[:pair]}'>DELETE</button>"
      btn_volumes_code = "<button class='btn_orders_volume btn_style_green' data-update='1' data-market='#{curr[:pair]}'>VOLUMES</button>"
      
      line += "<td> #{btn_delete_code} #{btn_volumes_code}</td>"
      line += "<td>#{curr[:buy_time].strftime("%F %k:%M ")} #{'%0.8f' % curr[:ppu]}</td>"
      lines_tr<<"<tr>#{line}</tr>"
    end
    
    info = ""
    
    if false
      btc_price="#{'%4.0f' % TradeUtil.usdt_base}"
      usdt_sum = data.inject(0){|ss,x| ss+=x[:usdt]}
      btc_sum =  data.inject(0){|ss,x| ss+=x[:btc]}
      bf_btc_price = BFDB[:hst_rates].filter(symb:3).reverse_order(:date).limit(8).select_map(:bid).map { |dd|  '%6.0f' % dd }.join(', ') 

      info = "upd #{DateTime.now.strftime('%k:%M:%S')} <br /> 
      #{base_crypto} price #{btc_price} <br /> 
      BTC bitfinex  #{ bf_btc_price } <br /> 

      USDT bal: #{'%0.2f' % usdt_sum}<br />
      #{base_crypto} bal: #{'%0.8f' % btc_sum}<br />"
    end

    "#{info} <table class='forumTable' style='width:75%;'>#{lines_tr.join()}</table>"

  end

  
  def self.order_book(tt="bid",mname)
    mname =@mname unless mname
    out=[]
    out<< "--------ORDER BOOK #{mname}"
    out<< "<br />--------#{tt.upcase}"
    out<< "<table class='forumTable'>"
    headers = ["<th>SUM</th>","<th>Total</th>", "<th>quant</th>", "<th>rate</th>"]
    out<<  ( tt=='bid' ? headers.join("") : headers.reverse.join(""))

    sum=0

    
    data= bittrex_api.get_order_book(mname, tt=="bid" ? "buy": "sell" )
    return "ERROR" unless data 
    data.take(15).each do |rr|
      q = rr["Quantity"]
      r = rr["Rate"]
      sum+=r*q
      s1= "#{'%0.8f' % r}"
      s2="#{'%0.1f' % q}"

      if tt=='bid'
        out<< "<tr> <td>#{'%0.4f' % sum}</td>  <td>#{'%0.4f' % (r*q)}</td>  <td>#{s2}</td> <td>#{s1}</td> </tr>"
      else
        out<< "<tr> <td>#{s1}</td> <td>#{s2}</td>  <td>#{'%0.4f' % (r*q)}</td> <td>#{'%0.4f' % sum}</td></tr>"
      end
    end
    out<< "</table>"
    out.join("")
  end
  
  def self.order_book_both(mname)
    mname =@mname unless mname
    
    headers1 = "<th>SUM</th><th>Total</th><th>quant</th><th>rate</th>"
    headers2 = "<th>rate</th><th>quant</th><th>Total</th><th>SUM</th>"
   
    data = bittrex_api.get_order_book(mname, 'both')
    return "ERROR" unless data 

    sum=0
    table1=[]

    data["buy"].take(15).each do |rr|
      q = rr["Quantity"]
      r = rr["Rate"]
      sum+=r*q
      s1= "<b>#{'%0.8f' % r}</b>"
      s2="<b>#{'%0.1f' % q}</b>"
      table1<< "<tr> <td>#{'%0.4f' % sum}</td>  <td>#{'%0.4f' % (r*q)}</td>  <td>#{s2}</td> <td>#{s1}</td> </tr>"
    end
    
    sum=0 
    table2=[]

    data["sell"].take(15).each do |rr|
      q = rr["Quantity"]
      r = rr["Rate"]
      sum+=r*q
      s1= "<b>#{'%0.8f' % r}</b>"
      s2="<b>#{'%0.1f' % q}</b>"
      table2<< "<tr> <td>#{s1}</td> <td>#{s2}</td>  <td>#{'%0.4f' % (r*q)}</td> <td>#{'%0.4f' % sum}</td></tr>"
    end

    data1="<table id='tbl_bid' class='forumTable'>"+headers1+table1.join("")+"</table>"
    data2="<table id='tbl_ask' class='forumTable'>"+headers2+table2.join("")+"</table>"
    
    [data1,data2]
  end
  
####

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


