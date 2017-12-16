Tweb::App.controllers :trade do
  
  get :big_tick do
    SiteUtil.table_tick
  end  

  get :toggle_real_simalte do
    toggle_real_simulate
  end  

  get :line_tick do
    SiteUtil.line_tick
  end

  get 'currency_tick/:curr' do
    curr = params[:curr]
    "#{curr} BID %0.8f  ASK %0.8f" % TradeUtil.get_bid_ask(curr)
  end 


  get :index do
    @title = "trade::index"

    @balance = BalanceUtil.get_balance_for_site 

    tracked = nil       #{title: "TRACKED", pairs:SiteUtil.get_tracked_markets(1)}

    super_tracked ={title: "SUPER HOT!!! SOLD!!", pairs:SiteUtil.get_tracked_markets(2)}
    @tracked_data= [super_tracked, tracked]


    @usdt_sum =@balance.inject(0){|ss,x| ss+=x[:usdt]} 
    @btc_sum =@balance.inject(0){|ss,x| ss+=x[:btc]} 
    @btc_rate= TradeUtil.usdt_base
    
    render 'index'
  end


  get :refresh_balance do
    system "cd '/home/kilk/work/0my_ruby/Trader-app/trade-bots'; ruby balance_upd.rb"
    SiteUtil.table_tick
  end

  
  get :set_new_balance do
    SimulatorUtil.set_new_balance
    redirect "#{request.referrer}"
  end

  get :my_trade_pairs do
    render "my_trade_pairs"
  end  


  get '/buy_sell_info/:mname', :provides => :json do
    
    mname = params[:mname]
    
    max_buy = SiteUtil.calc_max_buy(mname)
    item_price = SiteUtil.calc_price_for_one_token(mname)
    
    #OrderUtil.get_my_open_orders(mname)
    balance_str ="USDT price: #{'%0.4f' % item_price} <br /><br /> Max buy: #{'%0.8f' % max_buy}<br /><br /> "
    amount =  TradeUtil.get_operation_amount(mname)
    bid, ask = TradeUtil.get_bid_ask(mname)
    
    data={
      balance:balance_str, 
      operation_amount: ('%0.4f' % amount),
      bid: bid,
      ask: ask,
      orders_history: OrderUtil.my_hist_orders_from_db(mname),
    }
    data.to_json
  end
  get '/orderbook/:mname', :provides => :json do
    
    mname = params[:mname]
    
    data = SiteUtil.order_book_both(mname)
    #bal = bot.update_curr_balance(curr.sub('BTC-',''))

    @open_orders = OrderUtil.get_my_open_orders(mname)
    opened_orders_html = partial('order/open_orders', object: @open_orders) 

    max_buy = SiteUtil.calc_max_buy(mname)
    item_price = SiteUtil.calc_price_for_one_token(mname)

    balance_ss ="USDT price: #{'%0.4f' % item_price} <br /><br /> Max buy: #{'%0.8f' % max_buy}<br /><br /> "
    amount =  DB[:my_trade_pairs].first( name:mname)[:operation_amount]||0

    data={table1:data[0], table2:data[1], balance:balance_ss, operation_amount: ('%0.4f' % amount) , opened_orders:opened_orders_html}
    data.to_json
  end

  get '/buy_curr' do
    curr = params[:curr]
    qq = params[:q].to_f
    rate = BigDecimal.new(params[:r])

    res=TradeUtil.buy_curr(curr,qq,rate)
    #OrderUtil.get_my_open_orders(curr)

    return "[buy_curr] #{curr} q:#{qq} rate:#{rate} response:#{res}"
  end

  get '/sell_curr' do
    curr = params[:curr]
    qq = params[:q].to_f
    rate = BigDecimal.new(params[:r])

    res=TradeUtil.sell_curr(curr,qq,rate)
    return "[sell_curr] #{curr} q:#{qq} rate:#{rate} response:#{res}"
  end

  get '/fast_buy_curr' do
    curr = params[:curr]
    quant = params[:quant].to_f

    res=TradeUtil.fast_buy_curr(curr,quant)
    return "[fast_buy_curr]: #{res}"
  end  

  get '/fast_sell_curr' do
    curr = params[:curr]
    quant = params[:quant].to_f

    res=TradeUtil.fast_sell_curr(curr,quant)
    return "[fast_sell_curr]:#{res}"
  end

  get '/add_to_simul' do
    curr = params[:curr]
    TradeUtil.add_to_simul(curr)
    return "added"
  end

  get '/delete_from_simul' do
    pair = params[:pair]
    TradeUtil.delete_from_simul(pair)
    return "deleted #{pair}"
  end  
end
