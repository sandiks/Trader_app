Tweb::App.controllers :pump do
  
  get :index do
    data = PriceAnalz.checked_profile_tokens
    @falling = data.take(30)
    render 'index_pump'
    
  end

  get :falling, with:[:hours] do
    hours = params[:hours].to_f
    @title = "price/falling #{hours}"

    @falling = PriceAnalz.find_tokens_with_min_price(hours).take(33)
    VolumeAnalz.new.add_to_min_token(@falling)
    
    @my_balance = BalanceUtil.get_balance.select{|k,v| v[:usdt]>2 }

    render 'falling'
    
  end

  get :all do
    @title = "price-all"

    @all = DB[:my_ticks].filter(base:base_group).select(:name,:bid, :ask).all
    @my_balance = BalanceUtil.get_balance.select{|k,v| v[:usdt]>2 }

    render 'all'
  end

  get :rising,  with:[:hours]do
    
    hours = params[:hours].to_f
    @title="price/rising #{hours}"
    @ticks = DB[:my_ticks].filter(base:base_group).to_hash(:name,:ask)

    @rising = PriceAnalz.find_tokens_with_rising_price(hours).take(15)
    VolumeAnalz.new.add_to_min_token(@rising)

    render 'rising'
    
  end  
  get :check_pump do
    type = params[:type]
    hours = params[:hours]

    @title="pump/"+type
    
    if type=="tracked"

      data = PriceAnalz.checked_profile_tokens.map{|tt| tt[:name]}
      @text=VolumeAnalz.new.show_pump_report_for_group(data).map{ |k,vv| vv.join("<br />") }.join("<br />")
    
    elsif type=="min_prices"

      data = PriceAnalz.find_tokens_with_min_price(24).take(30).map{|tt| tt[:name]}
      @text=VolumeAnalz.new.show_pump_report_for_group(data).map{ |k,vv| vv.join("<br />") }.join("<br />")
      @text="48 hours back, 50 first<br />"+@text
    end

    render 'list_pump', layout:false
    
  end
    

  get :show_pump, with:[:market] do

    @market = params[:market]
    @url = "https://bittrex.com/Market/Index?MarketName=#{@market}"
    @enable = Tprofiles.filter(name:@market).select_map(:enabled)[0]
    
    data=VolumeAnalz.new.show_pump(@market)
    
    @text = data.join("<br />")
    render 'pump'
  end  
end
