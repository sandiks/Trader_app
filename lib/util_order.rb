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
  def self.my_hist_orders_from_db(mname) #need show open orders

    res=[]

    bought = My_hst_orders.filter(pid:get_profile, Exchange:mname, OrderType:'LIMIT_BUY').order(:TimeStamp).limit(3).all
    selled = My_hst_orders.filter(pid:get_profile, Exchange:mname, OrderType:'LIMIT_SELL').order(:TimeStamp).limit(3).all

      #.map { |dd| "#{dd[:time]} type: #{dd[:type]} quantity: #{dd[:q]}  price: #{dd[:price]}" }.join('<br />'),
    (bought+selled).each do |ord|
      #tm = DateTime.parse(ord[:TimeStamp])
      r = ord[:Limit]
      res<< "<tr><td>#{ord[:TimeStamp].strftime('%F  %k:%M')}</td><td> #{ord[:OrderType]}</td><td>#{'%0.1f' % ord[:Quantity]}</td><td>#{'%0.8f' % r} </td><tr>"
    end

    "<table class='forumTable'><th>time</th><th>SELL/BUY</th><th>quantity</th><th>price per unit</th>#{res.join()}</table>"
  end  
end


