require 'sequel'
require 'json'
#require 'dotenv'


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
    curr_ = balances.keys.map { |rr| pair(rr) }
    bids = DB[:my_ticks].filter(Sequel.lit(" name in ? ", curr_)).to_hash(:name,:bid) 

    res={}

    balances.each do |k,bal_avail|
      balance, available = bal_avail

       if k==base_crypto
        res[k]={ btc:balance, usdt:balance*usdt_base}
        next
       end
       pair = pair(k)

       bid=bids[pair]

       btc_bal = balance * bid rescue 0
       usdt_bal = btc_bal*usdt_base
       next if usdt_bal<1
       res[k]={ btc:btc_bal, usdt:usdt_bal}
    end
    res
  end  

##############
##############  
  
  def self.get_balance_for_site ##used in ---controllers/trade.rb
  
    balances = balance_table
    curr_ = balances.keys.map { |rr| pair(rr) }

    bids = DB[:markets].filter(Sequel.lit(" name in ? ", curr_)).to_hash(:name,[:Bid,:Ask]) 
    ticks = DB[:my_ticks].to_hash(:name,[:bid,:ask])

    amounts =  DB[:my_trade_pairs].filter( Sequel.lit("pid=? and name in ? ", get_profile, curr_) ).to_hash(:name, :operation_amount)
    
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
        else
          bid,ask = bids[mname] 
        end 
      end

      base_balance = balance*bid rescue 0
      
      usdt_bal = base_balance*base_price
      next if usdt_bal<1

      ##### orders
      from = date_now(36)
      hist_orders = DB[:my_hst_orders].filter( Sequel.lit("(pid=? and Exchange=? and Closed > ? )", get_profile, mname, from) ).reverse_order(:Closed).all
      
      last_orders = find_last_hist_order_not_sold(hist_orders) 
      last=last_orders.first
      diff_str=""
      
      if last
        diff1= bid/last[:Limit]*100 
        if diff1>=104
         diff_str="<sapn style='color:red;'>#{'%0.1f' % diff1}</span>"
        else
         diff_str="#{'%0.1f' % diff1}"
        end 
      end
      
      order_info = last_orders.take(5).map { |last| "(#{ '%0.2f' % last[:Quantity]}) #{'%0.8f' % last[:Limit]} (#{'%0.1f' % (bid/last[:Limit]*100)})" }.join('<br />')
      operation_amount = amounts[mname]


      res << {currency:k, last_bid:bid, last_ask:ask, balance:balance, available:available,  btc:base_balance, 
        usdt:usdt_bal, diff:diff_str, op_amount:operation_amount, orders_info:order_info, percents:""}

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