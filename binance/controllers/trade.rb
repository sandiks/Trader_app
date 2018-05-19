Tweb::Binance.controllers :trade do

  get :table_tick do
    Binance::SiteUtil.table_tick
  end  
  
  get :index do
    level = params[:level]||2

    @title = "Binance::trade"
    @markets = Binance::PriceAnalz.find_tokens_with_min_price(level,24).take(20)

    render 'index'
  end

  get :refresh_balance do
  end



  get :load_hist_trades do
    "loaded last trades"
  end


  get :set_pumped do
    mid = params[:mname]
    level = params[:level]
    CoinExchange::PriceAnalz.set_pump_level(mid,level)

    "set_pumped #{mid} #{level}"  
  end

  get '/rebalance' do
    curr = params[:curr]
    quant = params[:quant]
    Binance::BalanceUtil.rebalance(curr,quant)
    return "--rebalance curr:#{curr} quant:#{quant}"
  end

  get '/add_to_simul' do
    mname = params[:mname]
    Binance::BalanceUtil.add_to_simul(mname)
    return "--add_to_simul #{mname}"
  end

  get '/delete_from_simul' do
    mname = params[:mname]
    Binance::BalanceUtil.delete_from_simul(mname)
    return "deleted #{mname}"
  end  


  get '/currency_tick' do
    market_id = params[:pair]
    data = Binance::Client.new.get_market_summary(market_id)
    "#{market_id} [ask bid] %0.8f  %0.8f" % [data['AskPrice'], data['BidPrice']]
  end  

end
