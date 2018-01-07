Tweb::App.controllers :manage do
  
  @pid=2


  get :profile do
    @markets = Tprofiles.filter(pid:get_profile, group:1).all
    render 'profile'
  end


  
  get :copy_to_profile do
    copy_market_to_profile
  end  


  get '/enabled/:pair' do
    Tprofiles.where(pid:get_profile, name: params[:pair]).update(enabled: 1- Sequel[:enabled])    
    redirect "#{request.referrer}"    
  end

  get :set_pumped do
    curr = params[:curr]
    level = params[:level]

    Tprofiles.where(pid:get_profile, name: curr).update(pumped:level)
    "set_pumped #{curr} #{level}"  
  end

  get :get_my_trading_pair_info do
    curr = params[:curr]
    pair = "BTC-#{curr}"

    columns = [:step, :operation_amount, :sell_factor, :center_price]
    
    dd = DB[:my_trade_pairs].filter(pid:get_profile, name:pair).select_map(columns).first
    
    res = dd.each_with_index.map { |e,i|  "<tr><td>#{columns[i].to_s}</td> <td>#{'%0.8f' % (e||0)}</td></tr>" }.join("")
    
    bid,ask= TradeUtil.get_bid_ask_from_market(pair)
    amount = 13/(bid*TradeUtil.usdt_base).round(4) 

    return "<br /><b>#{pair} </b><br /> amount(13$): #{'%0.8f' % amount} <br /> <table class='forumTable' style='width:30%;' >#{res}</table>"
    
  end

  get :set_trading_pairs do
    curr = params[:curr]
    p column = params[:column]
    p value = params[:value]

    DB[:my_trade_pairs].filter(pid:get_profile, name:"#{base_crypto}-#{curr}").update(column.to_sym => value)
    return "set #{column}:#{value} for #{curr}"

  end


end
