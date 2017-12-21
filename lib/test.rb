require 'sequel'
require 'json'
require_relative 'db_util'
require_relative 'util_trade'
require_relative 'util_balance'
require_relative 'arr_helper'


#p data = BalanceUtil.get_balance.sort_by{|k,v| v[:usdt]}

now = date_now(0)
from = date_now(24)
tracked_pairs = ["BTC-XVG"]

p hours = 8.times.map {|hh| (24+now.hour - hh) % 24}.take(4) 

data = DB[:hst_btc_rates].filter(Sequel.lit(" date > ? and name in ? and HOUR(date) in ? ", from, tracked_pairs,hours))
.reverse_order(:date).select(:name,:date,:bid,:ask).all

last_bid=data.first[:bid]

prices = data
.group_by{|dd| dd[:date].hour}
.select{|k,vv| hours.include? k }
.map { |k,vv| { hour: k, avg: vv.map { |x|  x[:bid]}.mean } }


for i in 0..(prices.size-1) do 

  diff = prices[0][:avg]/prices[i][:avg]*100
  p  "hour:#{prices[i][:hour]} diff:%0.1f" % diff
  
end