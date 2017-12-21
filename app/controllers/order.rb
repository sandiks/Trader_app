Tweb::App.controllers :order do

  get :index do
    @title = "order::index"

    @tracked_pairs = Tprofiles.filter(pid:get_profile, enabled:1).all
    
    render 'index'

  end  
  get :hist_orders, with:[:pair] do
    @pair = params[:pair]
    @title = "order::hist_orders #{@pair}"
    
    kk = "my_hist_orders_date-#{@pair}"
    
    OrderUtil.my_hist_orders(@pair)
    #sleep 0.5
    OrderUtil.get_my_open_orders(@pair)    
      
    @bought = My_hst_orders.filter(Exchange:@pair, OrderType:'LIMIT_BUY').reverse_order(:TimeStamp).all
    
    @selled = My_hst_orders.filter(Exchange:@pair, OrderType:'LIMIT_SELL').reverse_order(:TimeStamp).all

    render '_hist_orders', :layout => false
  end

  get :load_open_orders, with:[:pair] do
    @pair = params[:pair]
    OrderUtil.get_my_open_orders(@pair)    
    
    return "--loaded #{@pair}"
  end
  
  get :refresh_orders do
    pairs = BalanceUtil.get_balance.sort_by{|k,v| v[:usdt]}.select{|k,v| v[:usdt]>4 }
    p mnames = pairs.map{|k,v| "#{base_crypto}-#{k}"}

    p "----order::refresh_orders #{mnames}"
    mnames.each do |mname|
      next if mname =="BTC-BTC" ||mname =="ETH-ETH" 
      #OrderUtil.my_hist_orders(mname)
      #sleep 0.2
      OrderUtil.get_my_open_orders(mname)
    end
    mnames.join(', ')

  end

  get :map_hist_orders, with:[:pair] do
    @pair = params[:pair]
    @title = "order::map_hist_orders #{@pair}"

    kk = "my_hist_orders_date-#{@pair}"
    cache_date = Tweb::App.cache[kk]
    need_updated_cache = cache_date && cache_date < DateTime.now.new_offset(0/24.0)- 10/(60*24.0)
    
    if cache_date.nil? || need_updated_cache
      p "-- my_hist_orders_date  [update cache]"
      Tweb::App.cache[kk] = DateTime.now.new_offset(0/24.0)
      OrderUtil.my_hist_orders(@pair)
    end
    
    all_mapped = My_hist_buy_sell_orders.filter(market:@pair).all
    
    mapped_bords = all_mapped.select{|x| x.type=="BUY" }.map { |ord| ord.ord_uuid }
    mapped_sords = all_mapped.select{|x| x.type=="SELL" }.map { |ord| ord.ord_uuid }
    mapped_bords=[1] if mapped_bords.size==0
    mapped_sords=[1] if mapped_sords.size==0
    
    @bought = My_hst_orders.filter(Sequel.lit("Exchange=? and OrderType=? and OrderUuid NOT IN ?", @pair, 'LIMIT_BUY', mapped_bords))
    .reverse_order(:TimeStamp).all
    @bought = @bought.group_by{|dd| [dd.TimeStamp.month, dd.TimeStamp.day] }
    
    @selled = My_hst_orders.filter(Sequel.lit("Exchange=? and OrderType=? and OrderUuid NOT IN ?", @pair, 'LIMIT_SELL', mapped_sords))
    .reverse_order(:TimeStamp).all
    @selled = @selled.group_by{|dd| [dd.TimeStamp.month, dd.TimeStamp.day] }
    
    render 'map_hist_buy_sell_orders'
  end

  get :mapped_hist_orders, with:[:pair] do
    @pair = params[:pair]
    @title = "order::mapped #{@pair}"
    
    all_mapped = My_hist_buy_sell_orders.filter(market:@pair).all
    
    mapped_bords = all_mapped.select{|x| x.type=="BUY" }.map { |ord| ord.ord_uuid }
    mapped_sords = all_mapped.select{|x| x.type=="SELL" }.map { |ord| ord.ord_uuid }
    mapped_bords=[1] if mapped_bords.size==0
    mapped_sords=[1] if mapped_sords.size==0

    @mapped = all_mapped.group_by{|dd| dd.orders_group}
    .map{ |k,vv| { group:k, 
      buy_orders: vv.select{|x| x.type=="BUY" }.map { |ord| ord.ord_uuid },
      sell_orders: vv.select{|x| x.type=="SELL" }.map { |ord| ord.ord_uuid } 
    }}
    
    render 'mapped_hist_buy_sell_orders'
  end

  post :map_hist_orders do
    pair = params[:pair]
    b_orders = params[:buy]    
    s_orders = params[:sell]
    res = map_buy_sell_orders_to_group(b_orders,s_orders, pair)
    return "inserted orders: #{res}"
  end

  post :copy_to_bot_trading do
    pair = params[:pair]
    b_orders = params[:buy]    
    res = copy_to_bot_trading(pair,b_orders)

    return "copied orders: #{res}"
  end
  get :list_mapped_orders, with:[:pair] do
    pair = params[:pair]
    #p @date = DateTime.parse(params[:date])

    render '_range_hist_orders', :layout => false
  end

  get :hist_ranged_orders, with:[:pair] do
    @pair = params[:pair]
    #p @date = DateTime.parse(params[:date])

    @range=OrderAnalz.range_price(@pair)
    render '_range_hist_orders', :layout => false
  end

  get :open_orders, with:[:pair] do
    @pair = params[:pair]
    #OrderUtil.get_my_open_orders(@pair)    
    
    if @pair=="all"
      @open_orders=OrderUtil.get_my_open_orders_from_db
    else
      @open_orders=OrderUtil.get_my_open_orders(@pair)
    end
    #render 'open_orders', :layout => false
    partial 'order/open_orders', :object => @open_orders
  end

  get '/close_open_order/:o_uuid' do
    uuid = params[:o_uuid]
    res = TradeUtil.cancel_by_uuid(uuid)
    "--closed order #{uuid} #{res}"
  end

### falling- volume info
  get :orders_volume do
    mname = params[:pair]
    p update = params[:update].to_i==1

    if update
      VolumeAnalz.new.show_pump(mname) 
    end

    pump_from = date_now(2)

    volumes = DB[:order_volumes].filter(Sequel.lit('name=?  and date > ? ', mname, pump_from))
    .order(:date).select(:name,:date,:vol,:count, :type).all

    sum=0
    hist ={}

    volumes.group_by{|dd| [dd[:date].hour, dd[:date].min/5]}.map do |hh_min, dd| 
    
      vols_sell = dd.select{|x| x[:type]=="SELL"}.inject(0){|sum,x| sum+=(x[:vol]||0)}
      vols_buy = dd.select{|x| x[:type]=="BUY"}.inject(0){|sum,x| sum+=(x[:vol]||0)}
      
      diff = vols_buy-vols_sell
      sum +=diff

      if diff>0.3
        vols_html = "<b> <<< #{'%0.8f' % diff}</b>"

      elsif diff<-0.3
        vols_html = "<b> >>> #{'%0.8f' % diff}</b>"

      else
        vols_html = "vol: #{'%0.8f' % diff}"            
      end
         
      hist[hh_min] = "(#{hh_min[0]}:#{hh_min[1]*5}) #{vols_html} sum: #{'%0.8f' %  sum}" 
    end    

    res=[]
    now_min = date_now.min/5+1
    hour = date_now.hour-2

    hours_mins = 24.times.map {|i| [hour+(now_min+i)/12 , (now_min+i)%12 ]  }

    hours_mins.each do |hh_min|

      if hist.key?(hh_min)
        res << hist[hh_min]
      else
        res<< "(#{hh_min[0]}:#{hh_min[1]*5}) --------"
      end
    end

    return res.join("<br />") 
  end

end
