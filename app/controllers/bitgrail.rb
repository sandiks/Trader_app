Tweb::App.controllers :bitgrail do

  get :table_tick do
    BG::SiteUtil.table_tick
  end  
  
  get :index do
    @title = "BitGrail::trade"
    @pairs = BG::My_ticks.to_hash(:name,[:bid,:ask])

    render 'index'
  end

  get :refresh_balance do
    BG::BGBot.new.balance
 
  end

  get '/buy_sell_info/:pair', :provides => :json do
    
    pair = params[:pair]

    ticks = BG::Util.get_all_bid_ask 
    bid,ask = ticks[pair]

    item_price = ask*BG::Util.btc_usd[:bid]
    
    max_buy = BG::Util.my_btc/ask 

    balance_str ="<br/>USDT price: #{'%0.4f' % item_price}<br/> Max buy: #{'%0.8f' % max_buy}"
    
    amount = BG::Util.last_buy_trade(pair)[:amount]

    data={
      balance: balance_str, 
      operation_amount: '%0.4f' %amount,
      bid: bid,
      ask: ask,
      orders_history: "",
    }
    data.to_json
  end



  get '/buy_curr' do
    pair = params[:curr]
    qq = params[:q].to_f
    rate = BigDecimal.new(params[:r])

    res=buy_pair(pair,qq,rate)
    
    return "[buy_curr] #{pair} quantity:#{qq} rate:#{rate} response:#{res}"
  end

  get '/sell_curr' do
    
    curr = params[:curr]
    qq = params[:q].to_i
    rate = BigDecimal.new(params[:r])

    #pair="EOSETH"

    res=sell_pair(pair,qq,rate)

    return "[sell_curr] #{curr} quantity:#{'%0.4f' % q} rate:#{'%0.8f' %  rate} response:#{res}"
  end

######fast buy sell

  get '/fast_buy_curr' do
    curr = params[:curr]
    quant = params[:quant].to_f

    p res=BG::Util.fast_buy_curr(curr,quant)
    return "[fast_buy_curr]: #{res}"
  end  

  get '/fast_sell_curr' do
    curr = params[:curr]
    quant = params[:quant].to_f

    res=BG::Util.fast_sell_curr(curr,quant)
    return "[fast_sell_curr]:#{res}"
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

end
