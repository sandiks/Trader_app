require 'sequel'
require_relative 'db_util'

class BF_SiteUtil

  BF_DB = BitfinexDB.get_db
  

  def self.date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end
  
  def self.config(key)
    case key
      when :group; BF_DB[:config].first(name:'group')[:value].to_i
    end
  end
  
  def self.base_crypto
    config(:group) ==1 ? "BTC" : "ETH"
  end  

  def self.get_all_bid_ask

    BF_DB[:my_ticks].to_hash(:symb,[:BID,:ASK])

  end

  def self.calc_max_buy(market_name)
    p market_name
    bids = BF_DB[:my_ticks].filter(name:market_name).select_map(:ask)
    balances = BalanceUtil.balance_table
    btc = balances["BTC"] 
    btc/bids[0] rescue 0
  end 

  def self.calc_price_for_one_token(market_name)
    
    ask = BF_DB[:my_ticks].filter(name:market_name).select_map(:ask).first
    if ask
     ask*TradeUtil.usdt_base
    else
     0
    end
  end 

####
  def self.base_curr
     "ETH"
  end
  
  def self.get_balance_for_site

    data = BF_DB[:wallets].filter(pid:2).all   
    
    rates = BF_SiteUtil.get_all_bid_ask 
    symbols=BitfinexDB.symb_hash
    usd_bid = rates[symbols["#{base_curr}USD"]][0]

    res=[]     
    data.each do |dd|

      curr=dd[:currency].upcase
      
      balance=dd[:balance]
      bid=ask=1
      if curr!=base_crypto
        sid = symbols["#{curr}#{base_curr}"]
        bid,ask =rates[sid] 
      end
      next if balance==0
      usd_bal = balance*bid*usd_bid rescue 0
      p " curr #{curr} bal #{balance} usd_bid #{usd_bid} bid #{bid}"
      res<<{currency:curr,bid:bid,ask:ask,balance:balance,usd_balance:usd_bal}
    end
    res
  end

  def self.table_tick
 
   
    lines_tr=[]
    lines_tr<< "<th>BID</th><th>ASK</th><th>balance</th><th>USDT bal</th><th>diff</th><th>pair</th>"
    symbols=BitfinexDB.symb_hash
    rates = BF_SiteUtil.get_all_bid_ask 
    
    eth_bid = rates[symbols["ETHUSD"]][0]
    btc_bid = rates[symbols["BTCUSD"]][0]

    data = get_balance_for_site
    usd_bal =0
    data.each do |dd|

      curr=dd[:currency]
      balance=dd[:balance]||0
      bid,ask =rates[symbols["t#{curr}#{base_crypto}"]] 

      line ="" 
      line += "<td><b>#{ '%0.8f' % (dd[:bid]||0) }</b></td>" 
      line += "<td><b>#{'%0.8f' % (dd[:ask]||0)}</b></td>"
      line += "<td>#{'%0.8f' % balance}</td> "
      line += "<td>#{'%0.2f' % dd[:usd_balance] }</td> "
      usd_bal+= dd[:usd_balance]

      line += "<td>diff</td>" 
      line += "<td><b>#{curr}</b></td>"
    
      lines_tr<<"<tr>#{line}</tr>"
    end
    
    upd ="upd #{DateTime.now.strftime('%k:%M:%S')} "

    "#{upd}<br /> 
    ETH_USD price #{'%0.2f' % eth_bid} <br /> 
    BTC_USD price #{'%0.2f' % btc_bid} <br /> 
    USDT bal: #{'%0.2f' % usd_bal}<br />
    <table class='forumTable' style='width:50%;'>#{lines_tr.join()}</table>"

  end



end


