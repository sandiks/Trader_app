require 'sequel'

module Cryptopia

  class SiteUtil

    DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'cryptopia', user: 'root')
    BF_DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitfinex', user: 'root')
    

    def self.date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end

    def self.base_curr
       "BTC"
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

      data = DB[:wallets].all   
      
      ticks = Cryptopia::BalanceUtil.get_all_bid_ask 
      usd_bid = Cryptopia::BalanceUtil.btc_usd[:bid]
      name_mid= Cryptopia::BalanceUtil.name_to_market_id

      res=[]     
      data.each do |dd|

        curr=dd[:currency]
        
        balance=dd[:balance]
        next if balance==0

        bid=ask=1
        mid = name_mid["#{curr}/#{base_curr}"]

        if curr!="BTC"
          bid,ask =ticks[mid] 
        end

        usd_bal = balance*bid*usd_bid rescue 0
        btc_bal = balance*bid rescue 0
        #p " curr #{curr} bal #{balance} usd_bid #{usd_bid} bid #{bid}"
        res<<{mid:mid, currency:curr, bid:bid||0, ask:ask||0, last_price:dd[:last_price] , balance:balance, btc_balance:btc_bal, usd_balance:usd_bal}
      end
      res.sort_by{|x| x[:btc_balance]}
    end
    
    def self.simul_table
      simul = DB[:simul_markets].all
      ticks = Cryptopia::BalanceUtil.get_all_bid_ask 

      lines_tr=[]
      lines_tr<< "<th>mid</th><th>pair</th><th>ASK</th><th>BID</th><th>diff</th><th>URL</th><th>del</th>"

      simul.each do |pair|
        mid = pair[:mid].to_i
        last = pair[:ppu]
        bid,ask = ticks[mid] 
        bid,ask =1,1 unless bid 
        
        name= Cryptopia::BalanceUtil.marketId_to_name(mid)
        line ="" 
        line += "<td style='width:8%;'>#{mid}</td>"
        line += "<td style='width:15%;'><b>#{name}</b></td>"

        line += "<td><b>#{'%0.8f' % ask}</b></td>"
        line += "<td><b>#{ '%0.8f' % bid }</b></td>" 

        diff = last.nil? ? 100 : (bid/last*100)
        line += "<td>#{'%0.1f' % diff }</td>"  
        line += "<td><a href='https://www.cryptopia.co.nz/Exchange/?market=#{name.sub('/','_')}' target='blank'>URL</a></td>"   
       
        btn_delete = "<button class='btn_tick_table_simul_delete' data-mid='#{mid}'> del </button>"
        btn_update_rate = "<button class='btn_tick_table_update_rate' data-mid='#{mid}'> rate </button>"
        line += "<td>#{btn_delete} #{btn_update_rate}</td>"
      
        lines_tr<<"<tr>#{line}</tr>"
      end
      "<table class='forumTable' style='width:40%;'>#{lines_tr.join()}</table>"

    end

    def self.get_all_bid_ask
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
        line += "<td style='width:8%;'>#{mid}</td>"
        line += "<td><b>#{curr}</b></td>"

        line += "<td><b>#{'%0.8f' % ask}</b></td>"
        line += "<td><b>#{ '%0.8f' % bid }</b></td>" 
        line += "<td>#{'%0.8f' % balance}</td> "
        line += "<td>#{'%0.8f' % btc_balance}</td> "
        line += "<td style='width:10%;'>#{'%0.2f' % usd_balance }</td> "
        sum_usd_bal+= usd_balance
        sum_btc_bal+= btc_balance
        
        ### diff
        last=dd[:last_price]
        diff = last.nil? ? 100 : (bid/last*100)
        diff_str=""
        if diff>120
          diff_str="<sapn style='color:red;'>#{'%0.1f' % diff}</span>"
        else
         diff_str="#{'%0.1f' % diff}"
        end 
        line += "<td>#{diff_str}</td>"    
        
        ### rebalance
        txt_code = "<input type='text' name='q' size='10' value='#{ '%0.3f' % 0 }'>"
        btn_rebalance = "<button class='btn_tick_table_rebalance btn_style_green' data-curr='#{curr}'> *REBALANCE* </button>"
        line += "<td>#{txt_code} #{btn_rebalance}</td>"   

        ##url
        line += "<td><a href='https://www.cryptopia.co.nz/Exchange/?market=#{curr}_BTC' target='blank'>URL</a></td>"   

        lines_tr<<{tr: "<tr>#{line}</tr>", diff: diff}

      end

      sorted_lines =[]
      sorted_lines<<"
      <th>mid</th>
      <th>pair</th>
      <th>ASK</th>
      <th>BID</th>
      <th>balance</th>
      <th>BTC </th>
      <th>USDT </th>
      <th>diff</th>
      <th style='width:30%;'>set</th>
      <th>URL</th>"
      sorted_lines += lines_tr.map{|xx| xx[:tr]}


      upd ="upd #{DateTime.now.strftime('%k:%M:%S')} "
      bf_btc_price = BF_DB[:hst_rates].filter(symb:3).reverse_order(:date).limit(10).select_map(:bid)
      .select.with_index { |x, i| i<10 || i % 5 == 0 }
      .map { |dd|  '%6.0f' % dd }.join(', ') 


      "#{upd}<br /> 
      ETH_USD price #{'%0.2f' % eth_bid} <br /> 
      BTC_USD #{bf_btc_price} <br /> 
      USDT: #{'%0.2f' % sum_usd_bal} BTC: #{'%0.6f' % sum_btc_bal}<br />
      <table class='forumTable' style='width:65%;'>#{sorted_lines.join()}</table>
      <br/> 
      #{simul_table}"

    end

  end

end
