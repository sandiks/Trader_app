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

  get :index do
    @title = "Bitfinex::trade"

    render 'index'
  end

end
