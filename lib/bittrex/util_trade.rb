require 'sequel'
require 'json'
#require 'dotenv'
require_relative 'bittrex_api'


class TradeUtil


  PID=2
  DB = get_db


  def self.bittrex_api
    BittrexApi.new
  end

  def self.date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end

  
  def self.usdt_base ##used in ---controllers/trade.rb
    mname =  config(:group) ==1 ? 'USDT-BTC' : 'USDT-ETH'
    base_rate = DB[:hst_usdt_rates].filter(name: mname).reverse_order(:date).limit(1).select_map(:bid)[0]

  end

  def self.usdt_btc ##used in ---controllers/trade.rb
      base_rate = DB[:hst_usdt_rates].filter(name:'USDT-BTC').reverse_order(:date).limit(1).select_map(:bid)[0]
  end
  
  def self.get_bid_ask(curr) 
    mname = curr
    if config(:group) ==1 
      mname = "BTC-#{curr}" if !curr.start_with?("BTC-")
    else
      mname = "ETH-#{curr}" if !curr.start_with?("ETH-")
    end

    dd= bittrex_api.get_ticker(mname)
    if dd
      save_tick_to_db(mname,dd) if dd['Bid']!=0
      [dd['Bid'],dd['Ask']]
    end
  end
  
  def self.get_bid_ask_from_tick(curr) 
    mname = curr
    if config(:group) ==1 
      mname = "BTC-#{curr}" if !curr.start_with?("BTC-")
    else
      mname = "ETH-#{curr}" if !curr.start_with?("ETH-")
    end
    dd = DB[:my_ticks].first(name:mname)
    [dd[:bid],dd[:ask]]
  end  

  def self.get_bid_ask_from_market(mname) 
    DB[:my_ticks].filter(name:mname).select_map([:bid,:ask]).first
  end

  def self.get_last_order(mname) 
     last = DB[:my_hst_orders].filter( Sequel.lit("(pid=? and Exchange=? and OrderType='LIMIT_BUY')", get_profile, mname) )
     .reverse_order(:Closed).limit(1).first
  end  

  def self.get_operation_amount(mname)

    dd = DB[:my_trade_pairs].first(pid:get_profile,name:mname)

    if dd 
      amount = dd[:operation_amount]
      
      if amount.nil? || amount==0
        bid,ask= TradeUtil.get_bid_ask_from_tick(mname)
        amount = 10/(bid*TradeUtil.usdt_base).round(4) 
      end

      #p "---get_operation_amount #{mname} amount #{amount} "
      amount
    
    else
      DB[:my_trade_pairs].insert({pid:get_profile, name:mname, operation_amount:0})
      bid,ask= TradeUtil.get_bid_ask_from_tick(mname)
      amount = 10/(bid*TradeUtil.usdt_base).round(4) 

    end  
  end

  def self.update_operation_amount(mname,q)

    dd = DB[:my_trade_pairs].first(pid:get_profile,name:mname)
    
    if dd 
      DB[:my_trade_pairs].filter(pid:get_profile, name:mname).update(operation_amount:q) if  q!=dd[:operation_amount]
    else
      DB[:my_trade_pairs].insert({pid:get_profile, name:mname, operation_amount:q})
    end  

  end


#########  BUY - SELL

  def self.buy_curr(mname, q, r)
    mname = "BTC-#{mname}" if !mname.start_with?("BTC-") 
        
    if config(:simulate)
      p "simulate"
      SimulatorUtil.buy_simulate(mname,q,r)
    else
      uuid = bittrex_api.buy(mname,q,r)
      #update_operation_amount(mname,q)
      
      if uuid
        DB[:my_trades].insert({pid:get_profile, ord_uuid:uuid, type:"BUY", name:mname, quantity:q, ppu:r,  bought_at: date_now(0)})
        #DB[:my_trade_pairs].filter(pid:get_profile, name:mname).update(center_price: r)
      end

      #sleep 0.2
      #OrderUtil.my_hist_orders(mname)
      uuid
    end
  end 

  def self.sell_curr(mname, q, r)

    if config(:simulate)
      SimulatorUtil.sell_simulate(mname,q,r)
    else
      
      if true
          
          uuid = bittrex_api.sell(mname,q,r)
          if uuid
            DB[:my_trades].insert({pid:get_profile, ord_uuid:uuid, type:"SELL", name:mname, quantity:q, ppu:r,  bought_at: date_now(0)})

            sleep 0.1
            TradeUtil.update_curr_balance('BTC')

            uuid
          end

      end
    end

  end 

######### FAST BUY - FAST SELL

  def self.fast_buy_curr(mname,q)
    mname = "BTC-#{mname}" if !mname.start_with?("BTC-") 

    if true
      pair =DB[:my_trade_pairs].first(name:mname)

      if pair
       q = pair[:operation_amount]||0 if q==0
       return "q is nil" if q==0
      end
      
      ask = TradeUtil.get_bid_ask_from_tick(mname)[1]

      p in_range = q*ask>0.0003 && q*ask<0.005

      if in_range
        
        if config(:simulate)
          SimulatorUtil.buy_simulate(mname,q,ask)
        else
          p uuid =  bittrex_api.buy(mname, q, ask)
          p "----------fast_buy_curr #{mname} q #{'%0.8f' % q} ask #{'%0.8f' % ask } uuid #{uuid}"

          #update_operation_amount(mname,q)
          #sleep 0.2
          #TradeUtil.update_curr_balance(mname.sub('BTC-',''))

          if uuid
            DB[:my_trades].insert({pid:get_profile, ord_uuid:uuid, type:"BUY", name:mname, quantity:q, ppu:ask,  bought_at: date_now(0)})
            #DB[:my_trade_pairs].filter(pid:get_profile, name:mname).update(center_price: ask)

          end
          "---bought q=#{'%0.2f' % q}  ask=#{'%0.8f' % ask} uuid=#{uuid}"
        end

      else
        "PPU is not in range "
      end
    end

  end     

  def self.fast_sell_curr(mname,q)   
    mname = "BTC-#{mname}" if !mname.start_with?("BTC-") 
  
    if true

      dd= DB[:my_trade_pairs].first(pid:get_profile, name:mname)
      return "set_params for #{mname} in --my_trade_pairs" unless dd

      ## sell factor
      sell_factor = dd[:sell_factor]
      return "sell_factor is nil" unless sell_factor 
      
      ##  operation amount
      q = dd[:operation_amount] if q==0
      return "q is nil" unless q 


      bid_ask = TradeUtil.get_bid_ask(mname)
      bid = bid_ask ? bid_ask[0] : TradeUtil.get_bid_ask_from_market(mname)[0]

      p price_in_range = q*bid<0.02
      
      if price_in_range
        
        if config(:simulate)
          SimulatorUtil.sell_simulate(mname,q,bid)
        else
  
          if true
            uuid= bittrex_api.sell(mname,q,bid)
            #update_operation_amount(mname,q)
            if uuid
              DB[:my_trades].insert({pid:get_profile, ord_uuid:uuid, type:"SELL", name:mname, quantity:q, ppu:bid,  bought_at: date_now(0)})
            end
          end

          "---sold q=#{'%0.2f' % q}  bid=#{'%0.8f' % bid} uuid=#{uuid}"
        end
      end

    end
  end  

  def self.update_curr_balance(sym)
    dd= bittrex_api.get_currency_balance(sym)
    DB[:my_balances].where(currency:sym).delete
    DB[:my_balances].insert(dd)
    dd
  end
  
  def self.cancel_by_uuid(uuid)
    p res =bittrex_api.cancel(uuid)
    DB[:my_open_orders].filter(pid:get_profile,OrderUuid:uuid).delete
    res
  end

  def self.add_to_simul(mname)
    
    q = DB[:my_trade_pairs].first(pid:get_profile, name:mname)[:operation_amount] rescue 1
    ask = TradeUtil.get_bid_ask(mname)[1] rescue 0
    DB[:simul_trades].filter(pid:get_profile,pair:mname).delete
    DB[:simul_trades].insert({pid:get_profile,pair:mname, quantity:q, ppu:ask, buy_time: date_now(0)})
    DB[:tprofiles].where(pid:get_profile, name: mname).update(pumped:2)
  end

  def self.new_simul_price_mark(mname)
    
    ask = TradeUtil.get_bid_ask(mname)[1] rescue 0
    DB[:simul_trades].filter(pid:get_profile,pair:mname)
    .update({ppu:ask, buy_time: date_now(0)})
  end


  def self.delete_from_simul(mname)
    DB[:simul_trades].filter(pid:get_profile,pair:mname).delete
  end

end