require 'sequel'
require_relative 'arr_helper'


#PID=2
class OrderAnalz

  DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'trading', user: 'root')
  def date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end

  def self.show_sell_buy_orders
    mname = 'BTC-TIX'
    data = DB[:my_hst_orders].filter(Exchange:mname).all
    
    sell_ord =[]
    buy_ord =[]

    data.each do |dd|
      if dd[:OrderType] == "LIMIT_SELL"
        sell_ord<<dd
      end
      
      if dd[:OrderType] == "LIMIT_BUY"
        buy_ord<<dd
      end
    
    end

    buy_min = buy_ord.min_by{|ee| ee[:Limit]}[:Limit]
    sell_max = sell_ord.max_by{|ee| ee[:Limit]}[:Limit]

    p "------BUY"
    buy_ord.each do |dd|
        puts "date:#{dd[:TimeStamp].strftime("%F %k:%M ")} rate:#{'%0.8f' % dd[:Limit]} q: #{'%0.3f' % dd[:Quantity]} btc: #{'%0.8f' % dd[:Price]}"
    end
    p "------SELL"
    sell_ord.each do |dd|
        puts "date:#{dd[:TimeStamp].strftime("%F %k:%M ")} rate:#{'%0.8f' % dd[:Limit]} q: #{'%0.3f' % dd[:Quantity]} btc: #{'%0.8f' % dd[:Price]}"
    end

  end
  STEPS={'BTC-DNT':0.00000030, 'BTC-TIX':0.00000050 }

  def self.range_price(mname,from=nil)
    #mname = 'BTC-DNT'
    if from
      data = DB[:my_hst_orders].filter(Sequel.lit(" TimeStamp > ? and Exchange=? ", from, mname)).all
    else
      data = DB[:my_hst_orders].filter(Exchange:mname).all
    end
    
    sell_ord =[]
    buy_ord =[]

    data.each do |dd|
      if dd[:OrderType] == "LIMIT_SELL"
        sell_ord<<dd
      end

      if dd[:OrderType] == "LIMIT_BUY"
        #puts "buy date:#{dd[:date]} rate:#{'%0.8f' % dd[:rate].to_f} total: #{'%0.3f' % dd[:total]} btc: #{'%0.8f' % dd[:btc]}"
        buy_ord<<dd
      end

    end

    buy_min = buy_ord.min_by{|ee| ee[:Limit]}[:Limit]
    sell_max = sell_ord.max_by{|ee| ee[:Limit]}[:Limit]

    bsum=0
    ssum=0
    #step = 0.00000030 #STEPS[mname]  
    step = (sell_max-buy_min)/10
    i =buy_min
    
    out=[]

    while i<sell_max
      i+=step
      #p "----#{'%0.8f' % (i-step)} - #{'%0.8f' % i}" 
      
      ss= sell_ord.select{|x| x[:Limit]>=i-step && x[:Limit]<i}.map{|x| x[:Price] }
      sellq= sell_ord.select{|x| x[:Limit]>=i-step && x[:Limit]<i}.map{|x| x[:Quantity] }
      
      bb= buy_ord.select{|x|  x[:Limit]>=i-step && x[:Limit]<i}.map{|x| x[:Price] }
      buyq= buy_ord.select{|x|  x[:Limit]>=i-step && x[:Limit]<i}.map{|x| x[:Quantity] }
      
      
      bsum+=bb.sum
      ssum+=ss.sum 
      
      rr = {
        min_range: i-step, 
        max_range:i, 
        buy_btc: bb.sum, 
        sell_btc:ss.sum, 
        buy_quant: buyq.sum, 
        sell_quant: sellq.sum  
      }  
      out<<rr      
    end
   out
  end

end
