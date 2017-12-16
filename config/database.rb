#Sequel::Model.plugin(:schema)
Sequel::Model.raise_on_save_failure = false # Do not throw exceptions on failure
Sequel::Model.db = case Padrino.env
  when :development then Sequel.connect(YAML::load(File.open('config/database-mysql.yml')), :loggers => [logger])
  when :production  then Sequel.connect(YAML::load(File.open('config/database-mysql.yml')),  :loggers => [logger])
end
DB_FBOT = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bittalk', user: 'root')
DB_BF = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitfinex', user: 'root')
