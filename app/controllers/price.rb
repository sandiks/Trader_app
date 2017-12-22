Tweb::App.controllers :price do
  
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
    
    render 'daily_prices'
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
    reverse = params[:reverse].to_i==1

    from = date_now(hours)

   
    prices = PriceAnalz.last_market_prices(mname,hours)

    res=[]
    #res<< "<b>Orders buy volume</b>"

    prices[:data].group_by{|dd| dd[:date].day}.each do |day, prices_data|  

      res << "market:<b> #{mname}</b>"
      res << "******** DAY:#{day} type: #{otype}"

      prices_data=prices_data.reverse if reverse
      
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
        res << "(#{pp[:date].strftime("%k_%M")}) #{time} #{mark}"
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
