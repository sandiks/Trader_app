require 'sequel'

module CoinExchange

  class SiteUtil

    DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'coinexch', user: 'root')
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

      data = DB[:wallets].all   
      
      ticks = CoinExchange::BalanceUtil.get_all_bid_ask 
      usd_bid = CoinExchange::BalanceUtil.btc_usd[:bid]

      name_mid= CoinExchange::BalanceUtil.symb_hash('BTC')

      res=[]     
      data.each do |dd|

        curr=dd[:currency]
        
        balance=dd[:balance]
        next if balance==0

        bid=ask=1
        if curr!="BTC"
          bid,ask =ticks[name_mid[curr]] 
        end

        #bid = 0.00000001 unless bid
        next unless bid

        btc_bal = balance*bid rescue 0
        usd_bal = btc_bal*usd_bid 
        #p " curr #{curr} bal #{balance} usd_bid #{usd_bid} bid #{bid}"
        res<<{currency:curr, bid:bid||0, ask:ask||0, last_price:dd[:last_price], balance:balance, btc_balance:btc_bal, 
          usd_balance:usd_bal}
      end
      res.sort_by{|x| x[:btc_balance]}
    end
    
    def self.simul_table
      simul = DB[:simul_markets].all
      ticks = CoinExchange::BalanceUtil.get_all_bid_ask 

      lines_tr=[]
      lines_tr<< "<th>pair</th><th>BID</th><th>ASK</th><th>diff</th>"

      simul.each do |pair|
        mid = pair[:mid].to_i
        last = pair[:ppu]
        bid,ask = ticks[mid] 
        bid,ask =1,1 unless bid 

        name= CoinExchange::BalanceUtil.marketId_to_name(mid)
        line ="" 
        line += "<td style='width:15%;'><b>#{name}</b></td>"

        line += "<td><b>#{ '%0.8f' % bid }</b></td>" 
        line += "<td><b>#{'%0.8f' % ask}</b></td>"

        diff = last.nil? ? 100 : (bid/last*100)
        line += "<td>#{'%0.1f' % diff }</td>"  
      
        lines_tr<<"<tr>#{line}</tr>"
      end
      "<table class='forumTable' style='width:40%;'>#{lines_tr.join()}</table>"

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
        line += "<td style='width:15%;'><b>#{curr}</b></td>"

        line += "<td><b>#{ '%0.8f' % bid }</b></td>" 
        line += "<td><b>#{'%0.8f' % ask}</b></td>"
        line += "<td>#{'%0.8f' % balance}</td> "
        line += "<td>#{'%0.8f' % btc_balance}</td> "
        line += "<td>#{'%0.2f' % usd_balance }</td> "
        sum_usd_bal+= usd_balance
        sum_btc_bal+= btc_balance

        last=dd[:last_price]

        diff = last.nil? ? 100 : (bid/last*100)
        line += "<td>#{'%0.1f' % diff }</td>"  
      
        lines_tr<<"<tr>#{line}</tr>"
      end
      
      upd ="upd #{DateTime.now.strftime('%k:%M:%S')} "
      bf_btc_price = BF_DB[:hst_rates].filter(symb:3).reverse_order(:date).limit(10).select_map(:bid)
      .select.with_index { |x, i| i<10 || i % 5 == 0 }
      .map { |dd|  '%6.0f' % dd }.join(', ') 

      "#{upd}<br /> 
      ETH_USD price #{'%0.2f' % eth_bid} <br /> 
      BTC_USD #{bf_btc_price} <br /> 
      USDT: #{'%0.2f' % sum_usd_bal} BTC: #{'%0.6f' % sum_btc_bal}<br />
      <table class='forumTable' style='width:50%;'>#{lines_tr.join()}</table>
      <br/> 
      #{simul_table}"

    end

  end

end