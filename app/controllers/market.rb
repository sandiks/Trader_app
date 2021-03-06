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


  get :market_info, :provides => :json do

    mname = params[:market]

    columns = [:name, :BaseVolume, :Created]
    
    dd = DB[:markets].filter(name:mname).select_map(columns).first
    p market_site = DB[:market_ids].first(name:mname)[:site]
    
    res = dd.each_with_index.map { |e,i|  "<tr><td>#{columns[i].to_s}</td> <td>#{e}</td></tr>" }.join("")

    {
      info: "<table class='forumTable' style='width:80%;' >#{res}</table>", 
      site: market_site
    
    }.to_json

  end


  post :set_market_column do
    p mname = params[:mname]
    p column = params[:column]
    p value = params[:value]

    DB[:market_ids].filter(name:mname).update(column.to_sym => value)
    return "set #{column}:#{value} for #{mname}"

  end  
end
