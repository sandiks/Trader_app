Tweb::Cryptopia.controllers :trade do
  
  get :table_tick do
    Cryptopia::SiteUtil.table_tick
  end  
  
  get :index do
    level = params[:level]||1

    @title = "cryptopia::trade"
    @markets = Cryptopia::PriceAnalz.find_tokens_with_min_price(level,48).take(100)

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
  
  ###rebalance
  get '/rebalance' do
    curr = params[:curr]
    quant = params[:quant]
    Cryptopia::BalanceUtil.rebalance(curr,quant)
    return "--rebalance curr:#{curr} quant:#{quant}"
  end  
  
  ### simulator
  get '/add_to_simul' do
    mid = params[:mid]
    Cryptopia::BalanceUtil.add_to_simul(mid)
    return "--add_to_simul #{mid}"
  end

  get '/delete_from_simul' do
    mid = params[:pair]
    Cryptopia::BalanceUtil.delete_from_simul(mid)
    return "deleted #{pair}"
  end  
  get '/set_new_simul_price_mark' do
    
    pair = params[:pair]
    Cryptopia::BalanceUtil.new_simul_price_mark(pair)
    return "[simul] new_price #{pair}"
  end 

  get '/currency_tick' do
    market_id = params[:pair]
    data = Cryptopia::Util.get_market(market_id)
    "#{market_id} [bid,ask] %0.8f  %0.8f" % [data['BidPrice'], data['AskPrice']]
  end   
end
