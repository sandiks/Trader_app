require 'sequel'
require_relative 'db_util'

class SimulatorUtil

  DB = get_db
  GROUP=config(:group)

  def self.date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end

  def self.set_new_balance
    pid =get_profile
    return if pid>1

    DB[:my_balances].filter(pid: pid).delete
    DB[:my_hst_orders].filter(pid: pid).delete

    DB[:my_balances].insert({pid:pid, currency:'BTC', Balance:1})
    DB[:my_balances].insert({pid:pid, currency:'ETH', Balance:10})

  end

  def self.buy_simulate(mname, q, r)

    curr = mname.sub('BTC-','')
    amount = q*r
    
    DB.transaction do
      curr_bal = DB[:my_balances].first(pid:get_profile,currency:curr)

      DB[:my_balances].insert({pid:get_profile, currency:curr, Balance:0}) unless curr_bal

      DB[:my_balances].filter(pid:get_profile,currency:curr).update(Balance: Sequel[:Balance]+q)
      DB[:my_balances].filter(pid:get_profile,currency:base_crypto).update(Balance: Sequel[:Balance]-amount)

      ##hist
      DB[:my_hst_orders].insert(pid:get_profile, OrderUuid:"sim-#{date_now(0).strftime("%F %k:%M ")}", 
          Exchange:mname, OrderType:'LIMIT_BUY', TimeStamp: date_now(0), Closed: date_now(0),Limit:r,Quantity:q )

    end
    "buy_simulate #{mname} q #{q}"
  end

  def self.sell_simulate(mname, q, r)

    curr = mname.sub('BTC-','')
    amount = q*r

    DB.transaction do
      curr_bal = DB[:my_balances].first(pid:get_profile,currency:curr)
      if curr_bal[Balance]>amount
        DB[:my_balances].filter(pid:get_profile,currency:curr).update(Balance: Sequel[:Balance]-q)
        DB[:my_balances].filter(pid:get_profile,currency:base_crypto).update(Balance: Sequel[:Balance]+amount)
        ##hist
        DB[:my_hst_orders].insert(pid:get_profile, OrderUuid:"sim-#{date_now(0).strftime("%F %k:%M ")}", 
          Exchange:mname, OrderType:'LIMIT_SELL', TimeStamp: date_now(0), Closed: date_now(0),Limit:r,Quantity:q )

      end

    end

  end

end