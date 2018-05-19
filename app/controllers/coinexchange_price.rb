Tweb::App.controllers :coinexchange_price do
  
  get :text_last_price do

    p mid = params[:mid]
    hours = params[:hours].to_f
    otype = params[:otype]
    reverse = params[:reverse].to_i==1

    from = date_now(hours)

   
    prices = CoinExchange::PriceAnalz.last_market_prices(mid,hours)
    
    return "no data" until prices

    res=[]
    #res<< "<b>Orders buy volume</b>"

    prices[:data].group_by{|dd| dd[:date].day}.each do |day, prices_data|  

      res << "market:<b> #{mid}</b>"
      res << "******** DAY:#{day}"

      prices_data=prices_data.reverse if reverse
    
      prices_data.each do |pp| 
        diff_bid=100
        diff_ask=100
        
        bid,ask = pp[:bid],pp[:ask]

        if  prices[:last_ask]!=0
          diff_bid= bid/prices[:last_ask]*100
          diff_ask= ask/prices[:last_ask]*100
        end

        diff_bid_ask = ask/bid*100-100
         
        candle1 = '.'* ((diff_ask-50)/2)  
        candle2 = '.'* (diff_bid_ask/2)  

        percent_bid_ask = bid/ask*100
        
        candle= "#{candle1}|| ----#{'%0.0f' % diff_ask}"       
        title = " (#{pp[:date].strftime("%H_%M")}) <b>#{'%0.8f' % ask} (#{'%0.0f' % percent_bid_ask}) </b>"
        
        res << "#{title} #{candle}"
      end

    end

    
    return res.join("<br />") 
  end

end
