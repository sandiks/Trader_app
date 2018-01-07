require 'dotenv'
require 'sequel'
require 'rest-client'

require_relative 'client'

Dotenv.load('.env')

module BG

  class BGBot

    BTG_DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitgrail', user: 'root')

    def initialize
      auth = {key:ENV["BG_KEY"], secret:ENV["BG_SECRET"] }
      @client = BG::Client.new(auth) 
    end

    def date_now(hours=0)
       DateTime.now.new_offset(0/24.0)- hours/(24.0)
    end
    
    def init_my_ticks
      BTG_DB.run("truncate table my_ticks")
      
      symbols = ["BTC-XRB"]
      
      symbols.each do |symb|
        BTG_DB[:my_ticks].insert({name:symb})
      end
    end

    def save_to_ticks(symb,bid,ask)

      rr = {bid:bid, ask:ask }
      BTG_DB[:my_ticks].filter(name:symb).update(rr)
    end

    def save_to_rates(symb, bid,ask)

        rr = {name:symb, bid:bid, ask:ask, date:date_now(0)}
        BTG_DB[:hst_rates].insert(rr)
    end

    def show_order_book(symb="")
        symb="BTC-CFT"
        orders = get_order_book(symb)

        orders['asks'].take(10).each do |ord| 
            p "price: %0.8f  amount: %0.8f" % [ ord['price'], ord['amount'] ]
        end

    end


    def find_last_hist_order_not_sold(hist_orders)
      
      amount=0
      orders=[]

      hist_orders.each do|ord|
      
        amount -=ord[:amount] if ord[:type]=='sell'
        if amount>0
          orders<<ord 
        end
        amount += ord[:amount] if ord[:type]=='buy' 
      end  
      
      orders
    end

    def ticker(symb)
      @client.get("#{symb}/ticker")
    end
    
    def buy_order(mname, amount, price)
      data = {market:mname, amount: amount, price: price}
      @client.post('buyorder',data)
    end    

    def sell_order(mname,amount,price)
      data = {market:mname, amount: amount, price: price}
      @client.post('sellorder',data)
    end    

    def balance
      balance = @client.post('balances')
      BTG_DB.run("truncate table balances")  
      balance.each do |bb|
        BTG_DB[:balances].insert( bb[1].merge({curr: bb[0]}) )      
      end
    end

    def last_trades
      BTG_DB.transaction do
        
        #BTG_DB.run("truncate table hst_trades") 
        exist=BTG_DB[:hst_trades].select_map(:tid)
        
        trades =  @client.post('lasttrades') 
        trades.each do |tr|
          
          if !exist.include?(tr[0].to_i)
            tr[1]['date'] = Time.at(tr[1]['date'].to_i)  
            BTG_DB[:hst_trades].insert( tr[1].merge({tid: tr[0]}) )
          end        
        end

      end
    end

  end

end