Tweb::Cryptopia.controllers :trade do
  
  get :table_tick do
    Cryptopia::SiteUtil.table_tick
  end  
  
  get :index do
    level = params[:level]||1

    @title = "cryptopia::trade"
    @markets = Cryptopia::PriceAnalz.find_tokens_with_min_price(level,24).take(100)

    render 'index'
  end

  get :refresh_balance do
    #BG::BGBot.new.balance
 
  end

  get :load_hist_trades do
    #BG::BGBot.new.last_trades
    "loaded last trades"
  end


  get :set_pumped do
    mid = params[:mid]
    level = params[:level]
    Cryptopia::PriceAnalz.set_pump_level(mid,level)

    "set_pumped #{mid} #{level}"  
  end
  

end
