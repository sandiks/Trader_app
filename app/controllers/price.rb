Tweb::App.controllers :price do
  
  get :falling, with:[:hours] do
    hours = params[:hours].to_f
    @title = "price/falling #{hours}"

    @falling = PriceAnalz.find_tokens_with_min_price(hours).take(50)
    VolumeAnalz.new.add_to_min_token(@falling)
    
    @my_balance = BalanceUtil.get_balance.select{|k,v| v[:usdt]>2 }

    render 'falling'
    
  end

  get :all do
    @title = "price-all"

    @all = DB[:my_ticks].select(:name,:bid, :ask).all
    @my_balance = BalanceUtil.get_balance.select{|k,v| v[:usdt]>2 }

    render 'all'
  end

  get :rising,  with:[:hours]do
    
    hours = params[:hours].to_f
    @title="price/rising #{hours}"
    @ticks = DB[:my_ticks].to_hash(:name,:ask)

    @rising = PriceAnalz.find_tokens_with_rising_price(hours).take(15)
    VolumeAnalz.new.add_to_min_token(@rising)

    render 'rising'
    
  end
 

  get :day_prices, with:[:pair] do

    @pair = params[:pair]
    show_all = true
    @url = "https://bittrex.com/Market/Index?MarketName=#{@pair}"

    prices = Hst_btc_rates.filter(name:@pair).reverse_order(:date).limit(4000).select_map([:date, :ask])   
    
    last = prices.first[1]

    @days_prices=[]

    prices.select.with_index { |x, i|  (i % 10 == 0) }.group_by{|dd| dd[0].day}.each do |day, day_prices|
      res=[]
      day_prices.map do |dpp|   
      
        diff= dpp[1]/last*1000
        mark ="<<<" if diff<990
        res << "ask [#{dpp[0].strftime("%k:%M")}] #{'%0.8f' % (dpp[1])} ** #{'%0.0f' % diff}  #{mark}"  
      end
      @days_prices<<{day:day, prices: res.join("<br />")}

    end    
    
    render 'pair_prices'
  end
  get :chart_last_price, :provides => :json do
    mname = params[:market]
    hours = params[:hours].to_f
    otype = params[:otype]
    
    data = PriceAnalz.chart_prices(mname, hours)
    
    data.to_json
  end

  get :text_last_price do

    mname = params[:market]
    hours = params[:hours].to_f
    otype = params[:otype]

    from = date_now(hours)
    pump_from = date_now(0.5)

    p "---text_last_price #{mname} "
    prices = PriceAnalz.last_market_prices(mname,hours)

    ##.map{|k,v| [ [k.hour,k.min],[v[0],v[1]] ] }.to_h

    res=[]
    res<< "<b>Orders buy volume</b>"

    ##volumes
    if false
      VolumeAnalz.new.show_pump(mname)

      volumes = DB[:order_volumes].filter(Sequel.lit('name=?  and date > ? ', mname, pump_from))
      .reverse_order(:date).select(:name,:date,:vol,:count, :type).all

      volumes.group_by{|dd| dd[:date].min/2}.map do |mmin, dd| 
      
        vols_sell = dd.select{|x| x[:type]=="SELL"}.inject(0){|sum,x| sum+=(x[:vol]||0)}
        vols_buy = dd.select{|x| x[:type]=="BUY"}.inject(0){|sum,x| sum+=(x[:vol]||0)}
        
        diff = vols_buy-vols_sell

        if diff>0.1
          vols_html = "<b>vol: #{'%0.8f' % diff}</b>"
        else
          vols_html = "vol: #{'%0.8f' % diff}"            
        end
         
        res<< "(#{mmin*2}..) #{vols_html}"

      end

    end

    prices[:data].group_by{|dd| dd[:date].day}.each do |day, prices_data|  
      res << ""
      res << "******** DAY:#{day} type: #{otype}"
    
      prices_data.each do |pp| 
        
        if otype=="ask"
          curr =pp[:ask] 
          diff= curr/prices[:last_ask]*100
        else
          curr =pp[:bid] 
          diff= curr/prices[:last_bid]*100
        end
        low="<<<" if diff<100
      
        mark= "#{'|'.rjust((diff-50)/2,'.')} #{'%0.1f' % diff} "       
        time = "<b>#{'%0.8f' % curr} </b>"
        res << "[#{pp[:date].strftime("%k:%M")}] #{time} #{mark}"
      end

    end

    
    return res.join("<br />") 
  end

  get :last_price_grouped_by_hour, with:[:hours,:pair] do

    @hours = params[:hours].to_f
    @pair = params[:pair]

    prices = PriceAnalz.last_market_prices(@pair,@hours)
    res=[]
    bid=prices[:last_bid]    
    res << "<b>last bid</b> #{'%0.8f' %  bid}"  
    res <<"<br />"

    prices[:data].map do |pp|   
      res << "<b>hh:#{pp[0]}</b> #{pp[1]}"  
    end
    
    return res.join("<br />") 
  end


end
