namespace :db do
  desc "Dump schema and data to db/schema.rb and db/data.yml"
  task(:dump => [ "db:schema:dump", "db:data:dump" ])

  desc "Load schema and data from db/schema.rb and db/data.yml"
  task(:load => [ "db:schema:load", "db:data:load" ])

  namespace :data do
    def db_dump_data_file
      "#{RAILS_ROOT}/db/#{ENV['DATAFILE'] ? ENV['DATAFILE'] : RAILS_ENV}.yml"
    end

    def db_dump_tables
      ENV['TABLES'] ? ENV['TABLES'].split(/,\s?/) : []
    end

    desc "Dump contents of database to db/data.yml"
    task(:dump => :environment) do
      YamlDb.dump(db_dump_data_file, db_dump_tables)
    end

    desc "Load contents of db/data.yml into database"
    task(:load => :environment) do
      YamlDb.load(db_dump_data_file, db_dump_tables)
    end
  end
end
