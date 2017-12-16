require 'sequel'
require_relative 'db_util'



class PriceAnalz

  PID=2
  DB = get_db
  GROUP= config(:group)
  
  def self.date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end
  
  def self.checked_profile_tokens(hours_back=48)
    markets = DB[:tprofiles].filter(pid:get_profile, check:2, group: 1, enabled:1).select(:name).all
  end

  def self.get_crypto_rates_with_minutes(from, market_list)
    now = date_now(0)

    mins = 10.times.map {|i| i<5 ? (now.min+i)%60 : (30+now.min+i)%60 }
    #hours = 12.times.map {|hh| (now.hour+ hh*2) % 24} 

    if GROUP==1
    
    all_data = DB[:hst_btc_rates]
      .filter(Sequel.lit(" (date > ? and name in ? and MINUTE(date) in ? )", from, market_list, mins))
      .reverse_order(:date).select(:name,:date,:bid,:ask).all
    elsif GROUP==2
     all_data = DB[:hst_eth_rates]
      .filter(Sequel.lit(" (date > ? and name in ? and MINUTE(date) in ? )", from, market_list, mins))
      .reverse_order(:date).select(:name,:date,:bid,:ask).all   
    end

  end
  def self.get_crypto_rates(from, market_list)

    if GROUP==1
      all_data = DB[:hst_btc_rates].filter( Sequel.lit(" (date > ? and name in ?)", from, market_list) )
      .reverse_order(:date).select(:name,:date,:bid,:ask).all
    elsif GROUP==2
      all_data = DB[:hst_eth_rates].filter( Sequel.lit(" (date > ? and name in ?)", from, market_list) )
      .reverse_order(:date).select(:name,:date,:bid,:ask).all
    end
    
  end

  def self.find_tokens_with_min_price(hours_back=48)

    p "find_tokens_with_min_price -- hours_back:#{hours_back}"

    markets = DB[:tprofiles].filter(pid:get_profile, group: GROUP, pumped:[1,2]).select_map([:name,:pumped])
    markets_names = markets.map { |dd| dd[0] }
    

    now = date_now(0)
    from = date_now(hours_back.to_i)
    ind = 0
    ress=[]

    all_data = get_crypto_rates_with_minutes(from,markets_names)

    markets.each do |mname, pumped|

      ind+=1

      data = all_data.select{|dd|dd[:name] == mname }
      next if data.size==0 

      res=[]

      last_bid=data[0][:bid]
      last_ask=data[0][:ask]
      next if last_bid==0
      
      prices = data.map { |dd| (dd[:bid]/last_bid*1000) }
      minp = prices.min  
      maxp = prices.max
      next if maxp-minp ==0 

      ### calculate factor
      ff=nil
      
      first_max = prices.first(2).max
      ff=(first_max-minp)/(maxp-minp)

      title ="#{mname}"

      #sparse_data=data.select.with_index { |x, i| (i<4) || (i % 10 == 0) }.group_by{|dd| dd[:date].day}
      #hist = sparse_data.map { |d, d_rates| [d, d_rates.map { |dd| "#{'%3.0f' % (dd[:bid]/last_bid*1000)}" } ].join(' ') }.join("<br />")
      
      hist=""

      #sparse_data = data.select.with_index { |x, i| (i<5) || (i % 20 == 0) }.group_by{|dd| [dd[:date].day,dd[:date].hour/4]}
      #hist = sparse_data.map { |d_hh, hour_rates| 
      #  ["d-#{d_hh[0]} [#{d_hh[1]}]", hour_rates.map { |dd| "#{'%3.0f' % (dd[:bid]/last_ask*1000)}" } ].join(' ') 
      #}.join("<br />")
      
      ress<< { name: mname, title: title, price_factor: ff, 
        bid: last_bid, ask:last_ask, pumped:pumped, hist_prices:hist }
      
    end

    ress.sort_by{|tt| tt[:price_factor]} 
  end

  ########interval 1-3 hours

  def self.find_tokens_with_rising_price(hours_back=2)

    p "--find_tokens_with_rising_price --hours_back:#{hours_back}"

    markets = DB[:tprofiles].filter(pid:get_profile, group:GROUP, pumped:1).select_map([:name,:pumped])
    market_names = markets.map { |e| e[0]  }

    now = date_now(0)
    from = date_now(hours_back)
    ind = 0

    rising_out=[]

    all_data = get_crypto_rates(from,  market_names)

    markets.each do |m_name,pumped|

      ind+=1

      data = all_data.select{|dd|dd[:name] == m_name }
      next if data.size==0 

      res=[]

      last_bid=data[0][:bid]
      last_ask=data[0][:ask]
      next if last_bid==0
      
      prices = data.map { |dd| (dd[:bid]/last_bid*1000) }
      minp = prices.min rescue p(data.map { |e| e[:bid]  }) 
      maxp = prices.max
      next if maxp-minp ==0 

      ### calculate factor
      ff=nil
      
      first_min = prices.first
      last_max = prices.last(2).max
      ff=(first_min-last_max)/(first_min+last_max)
      
      ff_str = "ff=#{'%0.1f' % ff }"

      title ="#{m_name}"

      sparse_data=data.select.with_index { |x, i| (i<2) || (i % 2 == 0) }.group_by{|dd| dd[:date].hour}
      hist = sparse_data.map { |hh, hour_rates| 
        [hh, hour_rates.map { |dd| "#{'%3.0f' % (dd[:bid]/last_bid*1000)}" } ].join(': ') 
      }.join("<br />")
      
      rising_out<< { name: m_name, pumped:pumped, title: title, price_factor: ff, bid: last_bid, ask:last_ask, hist_prices:hist }
      
    end

    rising_out.sort_by{|tt| -tt[:price_factor]} 
  end

  def self.last_market_prices(mname, hours_back)## for pirce controller


    from = date_now(hours_back)
    prices = get_crypto_rates(from,[mname])   

    last_bid = prices.first[:bid]
    last_ask = prices.first[:ask]
    
    #sparse_data=prices.select.with_index { |x, i| (i<3) || (i % 5 == 0) }.group_by{|dd| dd[:date].hour}
    #hist = sparse_data.map { |hh, hour_rates| [hh, hour_rates.map { |dd| "#{'%3.0f' % (dd[:bid]/last_bid*1000)}" }.join(' ') ] }
    
    prices=prices.select.with_index { |x, i| (i % 2 == 0) }
    {last_bid:last_bid, last_ask:last_ask, data:prices}
  end
  
  def self.chart_prices(mname, hours_back)## for pirce controller

    now = date_now(0)
    from = date_now(hours_back)
    mins = 10.times.map {|i| i<5 ? (now.min+i)%60 : (30+now.min+i)%60 }
    hours = 12.times.map {|hh| (now.hour+ hh*2) % 24} 

    ##  and HOUR(date) in ?
    data = get_crypto_rates_with_minutes(from,[mname])
    last_bid = data.last[:bid]

    data.group_by{|dd| [dd[:date].day, dd[:date].hour]}
    .map { |k,v| {dd:k[0], hh:k[1], bid: v.first[:bid]/last_bid*100-50 }  }    

  end

  @@last_rised=[]
  def self.get_balance(usdt_rate)

    balances = DB[:my_balances].to_hash(:currency,:Balance)
    curr_ = balances.keys.map { |rr| "BTC-#{rr}" }
    bids = DB[:my_ticks].filter(Sequel.lit(" name in ? ", curr_)).to_hash(:name,:bid) 

    res={}

    balances.each do |k,v|
      next if k=='BTC'
       bid=bids["BTC-#{k}"] 
       btc_bal = v*bid rescue 0
       usdt_bal = btc_bal*usdt_rate
       res[k]={ btc:btc_bal, usdt:usdt_bal}
    end
    res
  end  

  def self.show_falling_and_rising_prices(hours_back=24,group=1)

    market_names = DB[:tprofiles].filter(pid:get_profile, group: group, enabled:1).select_map(:name)
    tracked_pairs = DB[:tprofiles].filter(pid:get_profile,group: group, enabled:1, check:1).select_map(:name)

    usd_btc_bid = DB[:hst_usdt_rates].filter(name:'USDT-BTC').reverse_order(:date).limit(1).select_map(:bid)[0]
    balances = get_balance(usd_btc_bid)

    now = date_now(0)
    from = date_now(hours_back)
    ress={}
    ind=0
    tracked=[]
    
    curr_rising =[]
    all_data = get_crypto_rates_with_minutes(from,market_names)

    market_names.each do |m_name|

      currency = m_name.sub('BTC-','')
      
      data = all_data.select{|dd|dd[:name] == m_name }
      ind+=1
      next if data.size<2
    
      last_bid=data.first[:bid]
      last_ask=data.first[:ask]

      bid_prices = data.map { |dd| dd[:bid]/last_bid}
      ask_prices = data.map { |dd| dd[:ask]/last_ask}

      rise_ff=nil
      fall_ff=nil

      ### find rising and falling factors
      ff = bid_prices[0,3]
      rr = ask_prices[0,3]
      if (rr[0]>rr[1] && rr[1]>rr[2])
       rise_ff=(rr[0]-rr[2])/rr[0]
      end
      if (ff[0]<ff[1] && ff[1]<ff[2])
       fall_ff=(ff[2]-ff[0])/ff[2]
      end

      if fall_ff || rise_ff 
        is_tracked = tracked_pairs.include?(m_name) ? "**" : ""
        title ="(#{ind.to_s.ljust(3)})--#{m_name} #{is_tracked} "
        
        data2=data.select.with_index { |x, i|  (i % 2 == 0) }.group_by{|dd| dd[:date].day}
        
        ## when falling  divide by --last_bid
        base= fall_ff ? last_ask : last_bid 
        hist = data2.map { |d, d_rates| [d,d_rates.map { |dd| "#{'%3.0f' % (dd[:bid]/base*1000)} " }] }

        ress[m_name] = { info:{title: title,bid: last_bid, ask:last_ask, hist_prices:hist } }
        ress[m_name][:rising_factor] = rise_ff||0 
        ress[m_name][:falling_factor] = fall_ff||100 
      end

      if tracked_pairs.include?(m_name)
        bal = balances[currency]
        bal_usdt = bal ? bal[:usdt] : 0

        last3=data.select.with_index { |x, i| (i<5)|| (i % 5 == 0) }.map{ |dd| "#{'%4d' % (dd[:bid]/last_bid*1000)}" }.join(' ') 
        tracked<<{mname: m_name, usdt: bal_usdt, last_bid: last_bid, ask:last_ask, history_prices: last3 } 
      end  
    end

    rising_markets = []
    ress.sort_by{|k,v| -v[:rising_factor]}.take(10).each {|k,vv| curr_rising<<k; rising_markets<<vv[:info]  }

    rising_prev_now= (curr_rising & @@last_rised)
    .map { |dd| "https://bittrex.com/Market/Index?MarketName=#{dd}   #{dd}"  }
    @@last_rised = curr_rising

    falling_markets =ress.sort_by{|k,v| v[:falling_factor]}.take(30).map {|k,vv| vv[:info]  }
    
    usd_rate = "USDT-BTC bid #{'%0.0f' % usd_btc_bid} "
    {falling: falling_markets, rising: rising_markets, tracked:tracked, usd:usd_rate }
  end

end
