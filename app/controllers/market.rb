Tweb::App.controllers :market do
  

  get :index do
    
    #@markets = Market.filter(Sequel.like(:name, 'BTC-%')).reverse_order(:BaseVolume).all
    
    @markets = Market.filter(Sequel.like(:name, 'BTC-%')).reverse_order(:Created).all
    @tracked = []
    render 'index'

  end
  get :chart do
    render 'chart'

  end

  get :summaries do
    @markets = Market.filter(Sequel.like(:name, 'BTC-%')).reverse_order(:BaseVolume).all
    @tracked = []
  
    render 'summaries'
  end

  get :last_volumes, with:[:market], :provides => :json do
    from = DateTime.now.new_offset(0/24.0)-2/24.0
    sym = params[:market]
    #prices = Hst_btc_rates.filter(name:@pair).reverse_order(:date).limit(4000).select_map([:date, :ask])   

    data = OrderVolumes.filter(Sequel.lit("date > ? and name=? and type=?", from, sym,"BUY" ))
    data.reverse_order(:date).select(:date,:vol,:count)
    .map { |dd| {h:dd[:date].hour, m:dd[:date].min, vol:dd[:vol], count:dd[:count] } }.to_json
  end  
  
  get :last_prices, with:[:market], :provides => :json do
    from = DateTime.now.new_offset(0/24.0)-24/24.0
    sym = params[:market]
    #prices = Hst_btc_rates.filter(name:@pair).reverse_order(:date).limit(4000).select_map([:date, :ask])   

    data = OrderVolumes.filter(Sequel.lit("date > ? and name=? and type=?", from, sym,"BUY" ))
    data.reverse_order(:date).select(:date,:vol,:count)
    .map { |dd| {h:dd[:date].hour, m:dd[:date].min, vol:dd[:vol], count:dd[:count] } }.to_json
  end   

  get :last_price_grouped_by_hour, with:[:pair],:provides => :json do

    @hours = 72
    @pair = params[:pair]

    data = PriceAnalz.chart_prices(@pair, @hours)
    
    data = data.map { |xx| {dd: xx[:date].day, hh:xx[:date].hour, mm:xx[:date].min, bid: xx[:bid] } }.to_json
  end

end
