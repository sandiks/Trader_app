require 'sequel'
require 'json'


class OrderUtil

  DB = get_db

  def self.bittrex_api
    BittrexApi.new
  end

  def self.date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end

  def self.get_my_open_orders(mname) #need show open orders
    mname =@mname unless mname
    res=[]

    DB.transaction do
      DB[:my_open_orders].filter(pid: get_profile, Exchange:mname).delete
      exist = DB[:my_open_orders].filter(pid: get_profile, Exchange:mname).select_map(:OrderUuid)

      op_ords=bittrex_api.get_open_orders(mname)
      
      op_ords.each do |ord|
        if !exist.include?(ord['OrderUuid'])
          DB[:my_open_orders].insert(ord.merge(pid: get_profile))
        end
        r = ord['Limit']
        res<< {name:mname, ord_uuid: ord['OrderUuid'], type: ord['OrderType'], q:ord['Quantity'] , limit: r}
      end if op_ords
    end

    res
  end

  def self.get_my_open_orders_from_db #need show open orders
    res=[]

    data =DB[:my_open_orders].filter(pid: get_profile).all
    
    data.each do |ord|
      r = ord[:Limit]
      res<< {name:ord[:Exchange], ord_uuid: ord[:OrderUuid], type: ord[:OrderType], q:ord[:Quantity] , limit: r}
    end
    res
  end  
  
  def self.my_hist_orders(mname) #need show open orders
    p mname 
    res=[]
    #p "--------HISTORY ODRERS  #{mname}"
    DB.transaction do
      exist = DB[:my_hst_orders].filter(pid: get_profile, Exchange:mname).select_map(:OrderUuid)

      bittrex_api.market_orders_history(mname).each do |ord|

        if !exist.include?(ord['OrderUuid'])
          DB[:my_hst_orders].insert(ord.merge(pid: get_profile))
        end

        tm = DateTime.parse(ord['TimeStamp'])
        r = ord['Limit']
        res<< "time: #{tm.strftime('%F  %k:%M')} type:#{ord['OrderType']} q:#{'%0.1f' % ord['Quantity']} price:#{'%0.8f' % r}"
      end

    end
    res
  end


  def self.my_hist_orders_from_db2(mname,bid) #need show open orders

      from = date_now(12)
      hist_orders = DB[:my_hst_orders].filter( Sequel.lit("(pid=? and Exchange=? and Closed > ? )", get_profile, mname, from) ).reverse_order(:Closed).all

      sell_orders=[]

      buy_sell_orders=[]
  
      hist_orders.each do|ord|
      
        if ord[:OrderType]=='LIMIT_SELL'
          sell_orders <<ord
        elsif ord[:OrderType]=='LIMIT_BUY'
          buy_sell_orders << [ord, sell_orders.shift]
        end
    
      end  
      sum=0
      cost_sum=0
      order_info = buy_sell_orders.map do  |buy_sell| 
  
         if buy_sell[1]

          buy = buy_sell[0]
          sell = buy_sell[1]
          "
          buy: #{buy[:Closed].strftime('%d_%k:%M')} 
          sell: #{sell[:Closed].strftime('%d_%k:%M')}
           q:#{'%0.2f'% buy[:Quantity]} diff=#{'%4.1f' % (sell[:Limit]/buy[:Limit]*100 ) })" 
         
         else
          buy = buy_sell[0]
          sum +=buy[:Quantity]
          cost_sum+=buy[:Quantity]*buy[:Limit]

          "(#{'%0.2f'% buy[:Quantity]}) #{'%4.1f' % (bid/buy[:Limit]*100) } #{'%0.8f' % buy[:Limit] }  
          sum=#{'%0.2f' % sum} cost_sum=#{'%0.8f' % cost_sum}" 
         end
      end
      order_info.join("<br />")
      
  end  

  def self.my_hist_orders_from_db(mname) #need show open orders


    #all = My_hst_orders.filter(pid:get_profile, Exchange:mname).reverse_order(:Closed).limit(10).all
    
    bought = My_hst_orders.filter(Exchange:mname, OrderType:'LIMIT_BUY').reverse_order(:Closed).limit(6).all
    selled = My_hst_orders.filter(Exchange:mname, OrderType:'LIMIT_SELL').reverse_order(:Closed).limit(6).all
     
    res=[]
    bought.each do |ord|
      r = ord[:Limit]
      res<< "<tr><td>#{ord[:TimeStamp].strftime('%F  %k:%M')}</td><td> #{ord[:OrderType]}</td><td>#{'%0.1f' % ord[:Quantity]}</td><td>#{'%0.8f' % r} </td><tr>"
    end
    html1 = "<table class='forumTable' ><th>time</th><th>SELL/BUY</th><th>quantity</th><th>price per unit</th>#{res.join()}</table>"

    res=[]
    selled.each do |ord|
      r = ord[:Limit]
      res<< "<tr><td>#{ord[:TimeStamp].strftime('%F  %k:%M')}</td><td> #{ord[:OrderType]}</td><td>#{'%0.1f' % ord[:Quantity]}</td><td>#{'%0.8f' % r} </td><tr>"
    end
    html2 = "<table class='forumTable'><th>time</th><th>SELL/BUY</th><th>quantity</th><th>price per unit</th>#{res.join()}</table>"
    
    html ="<table style='width:50%;'><tr><td>#{html1}</td> <td>#{html2}</td></tr></table>"

  end  
end


