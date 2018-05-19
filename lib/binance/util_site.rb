require 'sequel'

module Binance

  class SiteUtil

    DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'binance', user: 'root')
    

    def self.date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end
        
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

      
      ticks = Binance::BalanceUtil.get_all_bid_ask 
      usd_bid = Binance::BalanceUtil.btc_usd[:bid]

      data = DB[:wallets].all   
      res=[]     
      data.each do |dd|

        curr=dd[:currency]
        
        balance=dd[:balance]
        next if balance==0

        bid = ask = 1
        symbol = "#{curr}BTC" 
        if curr!="BTC"
          bid,ask =ticks[symbol] 
        end

        bid = 0.00000001 unless bid
        next unless balance

        btc_bal = balance*bid 
        usd_bal = btc_bal*usd_bid 
        #next unless usd_bal<5
        #p " curr #{curr} bal #{balance} usd_bid #{usd_bid} bid #{bid}"
        res<<{mid:0 ,currency:curr, bid:bid||0, ask:ask||0, last_price:dd[:last_price], balance:balance, btc_balance:btc_bal, 
          usd_balance:usd_bal}
      end
      res.sort_by{|x| x[:btc_balance]}
    end
    
    def self.simul_table
      simul = DB[:simul_markets].all
      ticks = Binance::BalanceUtil.get_all_bid_ask 

      lines_tr=[]

      simul.each do |pair|

        mid=0

        name = pair[:name]
        last = pair[:ppu]
        bid,ask = ticks[name] 
        
        bid,ask =1,1 unless bid 

        next unless name  
        line ="" 
        line += "<td style='width:8%;'>#{mid}</td>"
        line += "<td style='width:15%;'><b>#{name}</b></td>"

        line += "<td><b>#{'%0.8f' % ask}</b></td>"
        line += "<td><b>#{ '%0.8f' % bid }</b></td>" 

        diff = last.nil? ? 100 : (ask/last*100)
        diff_str=""

        if diff>120
          diff_str="<sapn style='color:red;'>#{'%0.1f' % diff}</span>"
        else
         diff_str="#{'%0.1f' % diff}"
        end 

        line += "<td>#{diff_str}</td>" 
        line += "<td><a href='https://www.binance.com/trade.html?symbol=#{name.sub("BTC","")}_BTC' target='blank'>URL</a></td>"   

        
        btn_delete = "<button class='btn_tick_table_simul_delete' data-mname='#{name}'> del </button>"
        btn_update_rate = "<button class='btn_tick_table_update_rate' data-mname='#{name}'> rate </button>"
        line += "<td>#{btn_delete} #{btn_update_rate}</td>"

      
        lines_tr<<{tr: "<tr>#{line}</tr>", diff: diff}

      end

      sorted_lines=[]
      sorted_lines<< "<th>mid</th><th>pair</th><th>ASK</th><th>BID</th><th>diff</th><th>URL</th><th>del</th>"
      sorted_lines += lines_tr.sort_by{|xx| -xx[:diff]}.map{|xx| xx[:tr]}

      "<table class='forumTable' style='width:40%;'>#{sorted_lines.join()}</table>"

    end
    
    def self.table_tick
   
     
      lines_tr=[]
      
      rates = RateUtil.get_all_bid_ask 
      
      eth_bid = rates['ETHUSDT'][0]
      btc_bid = rates['BTCUSDT'][0]

      data = get_balance_for_site
      sum_usd_bal =0
      sum_btc_bal=0

      data.each do |dd|

        curr=dd[:currency]
        mid=dd[:mid]
        balance=dd[:balance]

        bid,ask =dd[:bid],dd[:ask] 
        btc_balance =dd[:btc_balance]
        usd_balance =dd[:usd_balance]

        line ="" 
        line += "<td>#{mid}</td>"
        line += "<td><b>#{curr}</b></td>"

        line += "<td><b>#{'%0.8f' % ask}</b></td>"
        line += "<td><b>#{ '%0.8f' % bid }</b></td>" 
        line += "<td>#{'%0.8f' % balance}</td> "
        line += "<td>#{'%0.8f' % btc_balance}</td> "
        line += "<td>#{'%0.2f' % usd_balance }</td> "
        sum_usd_bal+= usd_balance
        sum_btc_bal+= btc_balance

        last=dd[:last_price]

        diff = last.nil? ? 100 : (bid/last*100)
        diff_str=""
        if diff>110
          diff_str="<sapn style='color:red;'>#{'%0.1f' % diff}</span>"
        else
         diff_str="#{'%0.1f' % diff}"
        end 
        line += "<td>#{diff_str}</td>"  

        ### rebalance
        txt_code = "<input type='text' name='q' size='10' value='#{ '%0.3f' % 0 }'>"
        btn_rebalance = "<button class='btn_tick_table_rebalance btn_style_green' data-curr='#{curr}'> *REBALANCE* </button>"
        line += "<td>#{txt_code} #{btn_rebalance}</td>"   

        line += "<td><a href='https://www.binance.com/trade.html?symbol=#{curr}_BTC' target='blank'>URL</a></td>"   

      
        lines_tr<<{tr: "<tr>#{line}</tr>", diff: diff}
      end
      
      upd ="upd #{DateTime.now.strftime('%k:%M:%S')} "
      btc_price = DB[:hst_rates].filter(name: 'BTCUSDT').reverse_order(:date).limit(10).select_map(:bid)
      .select.with_index { |x, i| i<10 || i % 5 == 0 }
      .map { |dd|  '%6.0f' % dd }.join(', ') 


      sorted_lines =[]
      sorted_lines<<
        "<th style='width:8%;'>mid</th>
        <th style='width:8%;'>MARKET</th>
        <th>ASK</th>
        <th>BID</th>
        <th>balance</th>
        <th>BTC</th>
        <th>USDT</th>
        <th>diff</th>
        <th style='width:30%;'>Manage</th>
        <th>URL</th>"
      #sorted_lines += lines_tr.sort_by{|xx| xx[:diff]}.map{|xx| xx[:tr]}
      sorted_lines += lines_tr.map{|xx| xx[:tr]}

      "#{upd}<br /> 
      ETH_USD price #{'%0.2f' % eth_bid} <br /> 
      BTC_USD #{btc_price} <br /> 
      USDT: #{'%0.2f' % sum_usd_bal} BTC: #{'%0.6f' % sum_btc_bal}<br />
      <table class='forumTable' style='width:60%;'>#{sorted_lines.join()}</table>
      <br/> 
      #{simul_table}"

    end

  end

end