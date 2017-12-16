Tweb::App.controllers :pump do
  
  get :index do
    data = PriceAnalz.checked_profile_tokens
    @falling = data.take(30)
    render 'index_pump'
    
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
