#require 'parallel'
require 'sequel'
require_relative 'arr_helper'
require_relative 'bittrex_api'


Sequel.datetime_class = DateTime

class VolumeAnalz

  attr_accessor :config

  def initialize
    @config = DB[:config].select_hash(:name, :value)
  end

  DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'trading', user: 'root')

  def print_float(dd); sprintf('%02.4f', dd); end

  def save_ords(mname, data, type)
    min_d = date_now(30) #data.min { |oo| oo[:date] }
    exist = DB[:order_volumes].filter(Sequel.lit('name=? and date > ? and type=?', mname, min_d, type)).map(:date)
    exist = exist.map { |dd| [dd.hour, dd.min] }

    data.each do |ord|
      dd = ord[:date]
      if !exist.include?([dd.hour, dd.minute]) && dd>min_d
        #p "******new: #{type} hh_mm:#{[dd.hour, dd.minute]} count:#{ord[:count]} vol:#{ord[:vol]}"
        DB[:order_volumes].insert(ord)
      end
    end


  end

  def save_token_volume_hours(name,data)
    back10 =date_now(10)
    back20 =date_now(20)
    back30 =date_now(30)
    back60 =date_now(60)

    vol10 = data.select{ |dd|  dd[:date]>back10 }.reduce(0) { |sum, x| sum + x[:vol] }
    vol20 = data.select{ |dd|  dd[:date]>back20 }.reduce(0) { |sum, x| sum + x[:vol] }
    vol30 = data.select{ |dd|  dd[:date]>back30 }.reduce(0) { |sum, x| sum + x[:vol] }
    log "---save_token_volume_hours  vol:#{[vol10,vol20,vol30]}"
    DB[:stat_market_volumes].filter(name:name).update(vol10:vol10, vol20:vol20, vol30:vol30);

  end

  def save_token_checked_time(mname)

    res= DB[:stat_market_volumes].filter(name:mname).update(last_checked_at: date_now(0));
    if res!=1
      DB[:stat_market_volumes].insert(name:mname, last_checked_at: date_now(0))
    end
  end


  def log(txt)
    #p txt
  end

  ##--------------------
  def date_now(min_back=10); DateTime.now.new_offset(0/24.0)- min_back/(24.0*60) ; end

  def process_orders_and_save(_ords, mname, type)
    return unless _ords

    data = _ords.reverse.group_by { |pp| dd = pp[:Date]; DateTime.new(dd.year, dd.month, dd.day, dd.hour, dd.minute) }
    .select{|dt, vv| dt> date_now(150)}
    .map { |k, vv| { name: mname, date: k, count: vv.size, vol: vv.reduce(0) { |sum, x| sum + x[:Total] }, type: type } }

    log "***process_orders_and_save #{data.size}"
    
    save_ords(mname, data, type)
    #save_token_volume_hours(mname,data) if type=="BUY"

    data
  end

  def load_completed_orders_from_bittrix(mname)
    p "--load orders #{mname}"

    ords = BittrexApi.new.get_last_trades(mname)

    save_token_checked_time(mname)

    if  ords

      buy_ords = ords.select { |ord| ord['OrderType'] == 'BUY' }
      .map { |ord| { name:mname, Date: DateTime.parse(ord['TimeStamp']).new_offset(0 / 24.0), Total: ord['Total'], Type: 'BUY' } }

      sell_ords = ords.select { |ord| ord['OrderType'] == 'SELL' }
      .map { |ord| { name:mname, Date: DateTime.parse(ord['TimeStamp']).new_offset(0 / 24.0), Total: ord['Total'], Type: 'BUY' } }

    end
    {sell:sell_ords , buy:buy_ords}

  end

  def format_vol(dd, avg, type)
    "#{dd[:name]} [#{dd[:date].strftime("%k:%M")}] (#{dd[:count]}) #{ print_float(dd[:vol])}"
  end


  def calc_rise_fall_avg(data, type, need_show_all=false)
    res=[]

    p vols= data.map{|el| (el[:vol]||0)}
    avgs = []
    rise={}
    fall={}

    for i in 0..data.size-1
      avgs<<  (i==0 ? vols[i..i+1].mean :  vols[i-1..i+1].mean)
    end
    #p "vol_size:#{vols.size} avg_size:#{avgs.size}"

    for i in 1..data.size-1
      ff= vols[i]/vols[i-1]
      #ff= avgs[i]/avgs[i-1]

      rise[i]=ff if ff>2 && vols[i]>0.5

      #fall[i]=ff if ff<0.5
    end

    min_vol=@config["show_orders_with_min_volume"].to_f


    is_rised=1
    prev=""
    ldate=nil
    for i in 0..data.size-1
      dd = data[i]
      ss =format_vol(dd, avgs[i], "BUY")

      if rise[i]
        res<<"<b>#{ss}</b> ***RISE #{print_float(rise[i])}"
        is_rised=0
        ldate=dd[:date]
      else
        res<<"#{ss}" if need_show_all || is_rised==0 #||data[i][:vol]>= min_vol
        is_rised+=1
      end

    end

    {text:res.reverse,last_date:ldate}
  end

  def get_order_volumes_from_database(mname, min_back=20)
    ##from table

    ords = DB[:order_volumes].filter(Sequel.lit("sym=? and date > ? and type='BUY' ", mname, date_now(min_back))).order(:date).all
    log "---get_orders_from_api_or_database market:#{mname} ---DB size:#{ords.size} minutes_back:#{min_back}"

    buy_data = ords.select { |ord| ord[:type] == 'BUY' }
    sell_data = [] #ords.select { |ord| ord[:type] == 'SELL' }

    {sell:sell_data,buy:buy_data}
  end

  def show_order_volumes(mname, need_show_all=false)

    data = get_orders_from_database(mname,@config["history_orders_min_back"].to_i)[:buy]
    return [] unless data

    dd = calc_rise_fall_avg(data,"BUY", need_show_all)
    find_and_save_LAST_RISE(mname, dd, "check_token")
    dd[:text]
  end

  def find_and_save_LAST_RISE(mname, data, label)

    text= data[:text]
    ldate= data[:last_date].to_datetime if data[:last_date]

    last_rise = text.find{|ss| ss.include?("***RISE")}
    #p "-------now:#{now} rise_date:#{ldate}---------last_rise:#{last_rise}"
    now = date_now(0)

    if last_rise && !last_rise.empty?
      last_rise="#{last_rise} "
      if ldate && ldate+1/24.0 <now
        last_rise=""
      end
    else
      last_rise=""
    end

    last = DB[:markets].filter( name: mname ).select_map(:Last).first
    last_rise="#{'%0.8f'% (last||0)} #{last_rise} "

    DB[:stat_market_volumes].filter(name:mname).update(last_rise:last_rise,last_rised_at:ldate)

  end

  def self.select_last_rised
    DB[:stat_market_volumes].reverse_order(:last_rised_at).limit(20).select_map(:name)
  end

  def show_pump(mname)
    p "#{mname}"

    last_checked = DB[:stat_market_volumes].first(name:mname)
    
    if last_checked && last_checked[:last_checked_at].to_datetime>date_now(10)
       p "--pump_group #{mname} already checked #{last_checked[:last_checked_at].strftime("%k:%M")}"
        return
    end
    
    res=[]
      
    orders = load_completed_orders_from_bittrix(mname)
    sell_ords = orders[:sell]
    buy_ords = orders[:buy]
    
    process_orders_and_save( buy_ords, mname, 'BUY' )
    process_orders_and_save( sell_ords, mname, 'SELL' )
  
  end
  
  
  def show_pump_report_for_group(market_array, page_size=20)

    market_orders={}
    last_checked = DB[:stat_market_volumes].to_hash(:name,:last_checked_at)
    
    Parallel.map_with_index(market_array,:in_threads=>3)  do |mname,indx|
     
      if last_checked[mname] && last_checked[mname].to_datetime>date_now(5)
        p "--pump_group #{mname} already checked #{last_checked[mname].strftime("%k:%M")}"
        next
      end

      buy_ords = load_completed_orders_from_bittrix(mname)[:buy]
      market_orders[mname] = buy_ords
    end
    market_orders.each do |mname , buy_ords|
        process_orders_and_save(buy_ords, mname, 'BUY')
    end    

  end

  def add_to_min_token(data)

    last_checked = DB[:stat_market_volumes].to_hash(:name,:last_checked_at)
    markets_names = data.map { |dd| dd[:name]  }
    
    market_orders={}

    Parallel.map_with_index(markets_names,:in_threads=>2)  do |mname,indx|
    #markets_names.each_with_index  do |mname,indx|
     
      if last_checked[mname] && last_checked[mname].to_datetime>date_now(3)
        p "--pump_group #{mname} already checked #{last_checked[mname].strftime("%k:%M")}"
        next
      end

      orders = load_completed_orders_from_bittrix(mname)
      sell_ords = orders[:sell]
      buy_ords = orders[:buy]
      market_orders[mname] = {buy_ords:buy_ords, sell_ords:sell_ords}
    end
    
    sello =nil
    buyo =nil
    ##save orders
    DB.transaction do
      market_orders.each do |mname , data|
          buyo = process_orders_and_save(data[:buy_ords], mname, 'BUY')
          sello = process_orders_and_save(data[:sell_ords], mname, 'SELL')
      end    
    end
    
    pump_from = date_now(60)
    
    volumes = DB[:order_volumes].filter(Sequel.lit('name in ?  and date > ? ', markets_names, pump_from))
    .reverse_order(:date).select(:name,:date,:vol,:count, :type).all
    
    volumes = volumes.group_by{|dd| dd[:name]}

    data.each do |dd|
      mname = dd[:name]

      if volumes[mname]

            sum=0
 
            hist = volumes[mname].group_by{|dd| dd[:date].min/2}.map do |mmin, dd| 
            
            vols_sell = dd.select{|x| x[:type]=="SELL"}.inject(0){|sum,x| sum+=(x[:vol]||0)}
            vols_buy = dd.select{|x| x[:type]=="BUY"}.inject(0){|sum,x| sum+=(x[:vol]||0)}
            
            diff = vols_buy-vols_sell
            sum +=diff

            if diff>0.1
              vols_html = "<b>vol: #{'%0.8f' % diff}</b>"
            else
              vols_html = "vol: #{'%0.8f' % diff}"            
            end
            # "#{dd[:date].strftime("%k:%M ")} #{vols}  (#{dd[:count]})" 
            "(#{mmin*2}..) #{vols_html} sum: #{'%0.8f' %  sum}" 
          end

          dd[:hist_volumes]=hist.join("<br />")
      end
    end
         
  end

end
