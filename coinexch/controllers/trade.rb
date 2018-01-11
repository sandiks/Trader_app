Tweb::Coinexch.controllers :trade do

  get :table_tick do
    CoinExchange::SiteUtil.table_tick
  end  
  
  get :index do
    p level = params[:level]||2

    @title = "coinexchange::trade"
    #@markets = CE_DB[:markets].join(:pump, :mid=>:MarketID).filter(BaseCurrencyCode:'BTC', level:1).all
    @markets = CoinExchange::PriceAnalz.find_tokens_with_min_price(level,72).take(100)

    render 'index'
  end

  get :refresh_balance do
    BG::BGBot.new.balance
 
  end



  get :load_hist_trades do
    BG::BGBot.new.last_trades
    "loaded last trades"
  end

  get :hist_orders, with:[:pair] do
    @pair = params[:pair]
    @title = "order::hist_orders #{@pair}"
    
    kk = "my_hist_orders_date-#{@pair}"
    
    trades = BG::Util.get_hist_trades(@pair)
      
    @bought = trades.select{|dd| dd[:type]=='buy'}
    @sold = trades.select{|dd| dd[:type]=='sell'}
    
    render '_hist_orders', :layout => false
  end


  get :set_pumped do
    mid = params[:mid]
    level = params[:level]
    CoinExchange::PriceAnalz.set_pump_level(mid,level)

    "set_pumped #{mid} #{level}"  
  end

  get '/rebalance' do
    curr = params[:curr]
    quant = params[:quant]
    CoinExchange::BalanceUtil.rebalance(curr,quant)
    return "--rebalance curr:#{curr} quant:#{quant}"
  end

  get '/add_to_simul' do
    mid = params[:mid]
    CoinExchange::BalanceUtil.add_to_simul(mid)
    return "--add_to_simul #{mid}"
  end

  get '/delete_from_simul' do
    mid = params[:pair]
    CoinExchange::BalanceUtil.delete_from_simul(mid)
    return "deleted #{mid}"
  end  

  get '/set_new_simul_price_mark' do
    
    pair = params[:pair]
    TradeUtil.new_simul_price_mark(pair)
    return "[simul] new_price #{pair}"
  end  

  get '/currency_tick' do
    market_id = params[:pair]
    data = CoinExchange::Client.new.get_market_summary(market_id)
    "#{market_id} [ask bid] %0.8f  %0.8f" % [data['AskPrice'], data['BidPrice']]
  end  

end
