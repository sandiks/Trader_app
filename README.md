INSERT INTO stat_market_volumes(name) SELECT name FROM markets where name LIKE 'BTC-%';
INSERT INTO my_trade_pairs(name,bid,ask) SELECT name,Bid,Ask FROM markets where name LIKE 'BTC-%';

DB[:items].update_sql(price: 100, category: 'software')

          <a href='/order/map_hist_orders/BTC-<%=item[:currency] %>' >MAP SELL/BUY <%=item[:currency]%></a>

require_relative 'bittrex_api'
require_relative 'price_analz'
require_relative 'db_util'
require_relative 'order_util'
require_relative 'simul_util'