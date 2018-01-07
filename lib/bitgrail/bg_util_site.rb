require 'sequel'

module BG

  class SiteUtil

    DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitgrail', user: 'root')
    BF_DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitfinex', user: 'root')
    

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

      data = DB[:balances].all   
      
      ticks = BG::Util.get_all_bid_ask 
      usd_bid = BG::Util.btc_usd[:bid]

      res=[]     
      data.each do |dd|

        curr=dd[:curr]
        
        balance=dd[:balance]
        next if balance==0

        bid=ask=1
        if curr!="BTC"
          bid,ask =ticks["BTC-#{curr}"] 
        end

        usd_bal = balance*bid*usd_bid rescue 0
        btc_bal = balance*bid rescue 0
        #p " curr #{curr} bal #{balance} usd_bid #{usd_bid} bid #{bid}"
        res<<{currency:curr,bid:bid,ask:ask,balance:balance,btc_balance:btc_bal, usd_balance:usd_bal}
      end
      res
    end

    def self.table_tick
   
     
      lines_tr=[]
      lines_tr<< "<th>pair</th><th>BID</th><th>ASK</th><th>balance</th><th>BTC bal</th><th>USDT bal</th><th>diff</th>"
      bf_symbols=BitfinexDB.symb_hash
      bf_rates = BF_SiteUtil.get_all_bid_ask 
      
      eth_bid = bf_rates[bf_symbols["ETHUSD"]][0]
      btc_bid = bf_rates[bf_symbols["BTCUSD"]][0]

      data = get_balance_for_site
      sum_usd_bal =0
      sum_btc_bal=0

      data.each do |dd|

        curr=dd[:currency]
        balance=dd[:balance]

        bid,ask =dd[:bid],dd[:ask] 
        btc_balance =dd[:btc_balance]
        usd_balance =dd[:usd_balance]

        line ="" 
        line += "<td><b>#{curr}</b></td>"

        line += "<td><b>#{ '%0.8f' % bid }</b></td>" 
        line += "<td><b>#{'%0.8f' % ask}</b></td>"
        line += "<td>#{'%0.8f' % balance}</td> "
        line += "<td>#{'%0.8f' % btc_balance}</td> "
        line += "<td>#{'%0.2f' % usd_balance }</td> "
        sum_usd_bal+= usd_balance
        sum_btc_bal+= btc_balance

        line += "<td>diff</td>" 
      
        lines_tr<<"<tr>#{line}</tr>"
      end
      
      upd ="upd #{DateTime.now.strftime('%k:%M:%S')} "
      bf_btc_price = BF_DB[:hst_rates].filter(symb:3).reverse_order(:date).limit(10).select_map(:bid)
      .select.with_index { |x, i| i<10 || i % 5 == 0 }
      .map { |dd|  '%6.0f' % dd }.join(', ') 

      "#{upd}<br /> 
      ETH_USD price #{'%0.2f' % eth_bid} <br /> 
      BITFINEX BTC_USD #{bf_btc_price} <br /> 
      USDT bal: #{'%0.2f' % sum_usd_bal}<br />
      BTC bal: #{'%0.6f' % sum_btc_bal}<br />
      <table class='forumTable' style='width:40%;'>#{lines_tr.join()}</table>"

    end

  end

end