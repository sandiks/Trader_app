require 'sequel'


module CoinExchange

  class PriceAnalz

    PID=2
    DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'coinexch', user: 'root')
    GROUP=1
    
    def self.date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end
    
    def self.set_pump_level(mid,level)

      DB[:pump].filter(mid:mid ).delete
      DB[:pump].insert(mid:mid,level:level)
    end

    def self.get_crypto_rates_with_minutes(from, market_list)
      now = date_now(0)
      mins = 12.times.map {|i| i<6 ? (now.min+i)%60 : (30+now.min+i)%60 }

      all_data = DB[:hst_rates]
        .filter(Sequel.lit(" (date > ? and mid in ? and MINUTE(date) in ? )", from, market_list, mins))
        .reverse_order(:date).select(:mid,:date,:bid,:ask).all
    end


    def self.get_crypto_rates(from, market_list)

      all_data = DB[:hst_rates].filter( Sequel.lit(" (date > ? and mid in ?)", from, market_list) )
      .reverse_order(:date).select(:mid,:date,:bid,:ask).all
      
    end

    def self.last_market_prices(mid, hours_back)## for pirce controller

      from = date_now(hours_back)
      prices = get_crypto_rates(from,[mid])   
      return nil if  prices.size==0

      last_bid = prices.first[:bid]
      last_ask = prices.first[:ask]
      
      if hours_back>=48
       prices=prices.select.with_index { |x, i| (i<120 && i % 4 == 0) || (i>120 && i % 10 == 0) }
      elsif hours_back>=24
       prices=prices.select.with_index { |x, i| (i<5) || (i % 5 == 0) }
      elsif hours_back>=6
       prices=prices.select.with_index { |x, i| (i<5) || (i % 2 == 0) }
      end
      
      {last_bid:last_bid, last_ask:last_ask, data:prices}
    end
    

    def self.find_tokens_with_min_price(level=1,hours_back=24)

      p "find_tokens_with_min_price -- hours_back:#{hours_back}"

      #markets_hash = DB[:markets].join(:pump, :mid=>:MarketID).filter(BaseCurrencyCode:'BTC', level:[1,2])
      markets_hash = DB[:markets].join(:pump, :mid=>:MarketID).filter(BaseCurrencyCode:'BTC', level:level)
      .to_hash(:MarketID, :MarketAssetCode)
      
      markets = markets_hash.keys

      now = date_now(0)
      from = date_now(hours_back.to_i)
      ind = 0
      ress=[]

      all_data = get_crypto_rates_with_minutes(from, markets) 

      markets.each do |mid|

        ind+=1

        data = all_data.select{|dd| dd[:mid] == mid }
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
        ff=(first_max-minp)/(maxp-minp) + (last_ask/last_bid)

        title = markets_hash[mid]
        hist=""
  
        sparse_data = data.select.with_index { |x, i| (i<2) || (i % 10 == 0) }
        .group_by{|dd| [dd[:date].day,dd[:date].hour/6]}
        
        hist = sparse_data.map { |d_hh, hour_rates| 
          ["d-#{d_hh[0]} [#{d_hh[1]}]", hour_rates.map { |dd| "#{'%3.0f' % (dd[:bid]/last_ask*1000)}" } ].join(' ') 
        }.join("<br />")

        ress<< { mid: mid, title: title, price_factor: ff, 
          bid: last_bid, ask:last_ask, hist_prices:hist }
        
      end

      ress.sort_by{|tt| tt[:price_factor]} 
    end

  end

end
