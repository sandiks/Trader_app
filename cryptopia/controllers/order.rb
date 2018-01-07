Tweb::Cryptopia.controllers :order do
  
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
