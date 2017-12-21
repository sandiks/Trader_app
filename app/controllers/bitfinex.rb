Tweb::App.controllers :bitfinex do

  get :big_tick do
    BF_SiteUtil.table_tick
  end  
  
  get :index do
    @title = "Bitfinex::trade"
    @symbols = Symbols.all
    @ticks = My_ticks.to_hash(:symb,[:BID,:ASK])

    render 'index'
  end

  get :refresh_balance do

    BitfinexBot.load_wallet
    BF_SiteUtil.table_tick
  end

  get '/buy_sell_info/:pair', :provides => :json do
    
    pair = params[:pair]

    rates = BF_SiteUtil.get_all_bid_ask
    symbols=BitfinexDB.symb_hash
    bid,ask = rates[symbols[pair]]

    data={
      balance:"balance_str", 
      operation_amount: "amount",
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

    pair="EOSETH"

    res=BitfinexBot.buy_pair(pair,qq,rate)
    
    return "[buy_curr] #{pair} quantity:#{qq} rate:#{rate} response:#{res}"
  end

  get '/sell_curr' do
    
    curr = params[:curr]
    qq = params[:q].to_i
    rate = BigDecimal.new(params[:r])

    pair="EOSETH"

    res=BitfinexBot.sell_pair(pair,qq,rate)

    return "[sell_curr] #{curr} quantity:#{'%0.4f' % q} rate:#{'%0.8f' %  rate} response:#{res}"
  end

end
