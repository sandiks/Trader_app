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
    @simul = BalanceUtil.get_simul_tokens 

    super_tracked ={
      title: "SUPER HOT!!!",
      markets: PriceAnalz.get_tracked_markets(2)
    }
    tracked = nil       #{title: "TRACKED", pairs:SiteUtil.get_tracked_markets(1)}
    
    @tracked_data= [super_tracked]

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
    
    p mname = params[:mname]
    return if mname==base_crypto
    
    bid, ask = TradeUtil.get_bid_ask_from_tick(mname)
    p max_buy = 0.019/ask #SiteUtil.calc_max_buy(ask)
    item_price = ask*TradeUtil.usdt_base
    
    balances = BalanceUtil.balance_table
    curr = mname.sub("#{base_crypto}-",'')
    pair_balance = balances[curr]

    if pair_balance
      balance = ' bal: %0.8f  avaiable: %0.8f' % pair_balance 
    end

    #OrderUtil.get_my_open_orders(mname)
    balance_str ="Balance:#{balance}  <br/>USDT price: #{'%0.4f' % item_price}<br/> Max buy: #{'%0.8f' % max_buy}"
    amount =  TradeUtil.get_operation_amount(mname)
    
    #@open_orders=OrderUtil.get_my_open_orders(mname)
    orders_history = "" #partial('order/open_orders', :object => @open_orders)
    
    data={
      currency:mname, 
      balance:balance_str, 
      operation_amount: ('%0.4f' % amount),
      bid: bid,
      ask: ask,
      orders_history: orders_history,
    }
    data.to_json
  end

  get '/orderbook/:mname', :provides => :json do
    
    mname = params[:mname]
    
    data = SiteUtil.order_book_both(mname)
    #bal = bot.update_curr_balance(curr.sub('BTC-',''))

    bid, ask = TradeUtil.get_bid_ask_from_tick(mname)
    p max_buy = SiteUtil.calc_max_buy(ask)
    item_price = ask*TradeUtil.usdt_base

    balance_str ="USDT price: #{'%0.4f' % item_price} <br /><br /> Max buy: #{'%0.8f' % max_buy}<br /><br /> "
    amount = TradeUtil.get_operation_amount(mname)

    data={table1:data[0], table2:data[1], balance:balance_str, operation_amount: ('%0.4f' % amount) , opened_orders:""}
    data.to_json
  end

  get '/buy_curr' do
    curr = params[:curr]
    qq = params[:q].to_f
    rate = BigDecimal.new(params[:r])

    res=TradeUtil.buy_curr(curr,qq,rate)
    #OrderUtil.get_my_open_orders(curr)

    return "#{curr} q:#{'%0.4f' % qq} rate:#{'%0.8f' % rate} response:#{res}"
  end

  get '/sell_curr' do
    curr = params[:curr]
    qq = params[:q].to_f
    p rate = BigDecimal.new(params[:r])

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
