require 'sequel'
require 'json'
#require 'dotenv'
require_relative 'util_trade'


class BalanceUtil

  DB = get_db
  GROUP = config(:group)
  

  def self.bittrex_api
    BittrexApi.new
  end

  def self.date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end

  def self.balance_table
    DB[:my_balances].filter(pid:get_profile).to_hash(:currency,[:Balance,:Available])
  end  

####  balance
  def self.pair(curr)
    GROUP==1 ? "BTC-#{curr}" : "ETH-#{curr}"
  end

  def self.get_balance(usdt_base=0)
    usdt_base = TradeUtil.usdt_base if usdt_base==0

    balances = balance_table
    ticks = DB[:my_ticks].to_hash(:name,[:bid,:ask])

    res={}

    balances.each do |k,bal_avail|
      balance, available = bal_avail

       if k==base_crypto
        res[k]={ btc:balance, usdt:balance*usdt_base}
        next
       end
       pair = pair(k)

       bid,ask=ticks[pair]

       btc_bal = balance * bid rescue 0
       usdt_bal = btc_bal*usdt_base
       next if usdt_bal<4
       res[k]={ btc:btc_bal, usdt:usdt_bal, bid:bid, ask:ask}
    end
    res
  end  

##############
##############  
  
  def self.get_balance_for_site ##used in ---controllers/trade.rb
  
    balances = balance_table
    curr_ = balances.keys.map { |rr| pair(rr) }

    ticks = DB[:my_ticks].to_hash(:name,[:bid,:ask])
    pair_trade_data =  DB[:my_trade_pairs].filter( Sequel.lit("pid=? and name in ? ", get_profile, curr_) ).to_hash(:name, [:operation_amount,:center_price])
    
    base_price = TradeUtil.usdt_base

    res=[]
    balances.each do |k,bal_avail|
      
      balance, available = bal_avail

      mname = pair(k)
      next if  balance.nil? || balance==0 

      bid=ask=1
      if k!=base_crypto 
        if ticks.key?(mname)
          bid,ask = ticks[mname] 
        end 
      end

      base_balance = balance*bid rescue 0
      
      usdt_bal = base_balance*base_price
      next if usdt_bal<4

      ##### orders
      from = date_now(36)
      hist_orders = DB[:my_hst_orders].filter( Sequel.lit("(pid=? and Exchange=? and Closed > ? )", get_profile, mname, from) ).reverse_order(:Closed).all
      
      last_orders = find_last_hist_order_not_sold(hist_orders) 
      order_info = last_orders.take(3).map { |last| "(#{ '%0.2f' % last[:Quantity]}) #{'%0.8f' % last[:Limit]} (#{'%0.1f' % (bid/last[:Limit]*100)})" }.join('<br />')
 
      next if !pair_trade_data[mname]
      
      center_price = pair_trade_data[mname][1]
      #last_ord= last_orders.first
      diff_str="NO_CENTER"

      last = last_orders.first ? last_orders.first[:Limit] : center_price 

      if last
        diff= bid/last*100 
        
        if diff>106
         diff_str="<sapn style='color:red;'>#{'%0.1f' % diff}</span>"
        elsif diff<0.4
         diff_str="<sapn style='color:green;'>#{'%0.1f' % diff}</span>"
        else
         diff_str="#{'%0.1f' % diff}"
        end 
      end
      
      operation_amount = pair_trade_data[mname][0]

      res << {currency:k, last_bid:bid, last_ask:ask, balance:balance, available:available,  btc:base_balance, 
        usdt:usdt_bal, diff:diff_str, op_amount:operation_amount, orders_info:order_info, percents:""}

    end

    res
  end  

  def self.get_simul_tokens ##used in ---controllers/trade.rb
  
    res=[]
    simul_curr =  DB[:simul_trades].filter(pid:get_profile, base_crypto: base_group).all
    simul_curr.each do |curr|

      bid,ask = TradeUtil.get_bid_ask_from_market(curr[:pair]) 
      diff = (bid||0)/ curr[:ppu] *100 

      diff_str=""
      if diff>106
       diff_str="<sapn style='color:red;'>#{'%0.1f' % diff}</span>"
      elsif diff<0.4
       diff_str="<sapn style='color:green;'>#{'%0.1f' % diff}</span>"
      else
       diff_str="#{'%0.1f' % diff}"
      end 

      res << {pair:curr[:pair], last_bid:bid, last_ask:ask, diff:diff_str, percents:""}
      
    end
    res
    
  end
#############

  def self.find_last_hist_order_not_sold(hist_orders)
      
      last_indx=0
      orders=[]
      ##find last not solded
      hist_orders.each do|ord|
      
        last_indx +=1 if ord[:OrderType]=='LIMIT_SELL'
        if last_indx==0
          orders<<ord 
        end
        last_indx -=1 if ord[:OrderType]=='LIMIT_BUY' && last_indx>0 
      end  
      
      orders
  end
  
end