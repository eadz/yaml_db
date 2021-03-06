module YamlDb
  def self.dump(filename, tables=[])
    ActiveRecord::Base.connection.yamldb_dump(File.new(filename, "w"), tables)
  end

  def self.load(filename, tables=[])
    ActiveRecord::Base.connection.yamldb_load(File.new(filename, "r"), tables)
  end
end

module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      ### Dump
      def yamldb_dump(io, only_tables=[])
        YAML.dump(yamldb_dump_structure(only_tables), io)
      end

      def yamldb_dump_structure(only_tables=[])
        hash = {}
        (only_tables.empty? ? tables : only_tables).each do |table|
          hash[table] = yamldb_dump_table(table)
        end
        hash
      end

      def yamldb_dump_table(table)
        out = {}
        out['columns'] = table_column_names(table)
        out['records'] = yamldb_dump_table_records(table)
        out
      end

      def yamldb_dump_table_records(table)
        rows = select_all("SELECT * FROM #{table}")
        rows.map do |row|
          unhash(row, table_column_names(table))
        end
      end

      def table_column_names(table)
        columns(table).map { |c| c.name }
      end

      def unhash(hash, keys)
        keys.map { |key| hash[key] }
      end

      ### Load
      def yamldb_load(io, only_tables=[])
        data = YAML::load(io)

        unless only_tables.empty?
          data.slice!(only_tables)
        end

        transaction do
          yamldb_load_structure(data)
        end
      end

      def yamldb_load_structure(structure)
        structure.each do |table_name, data|
          yamldb_load_table(table_name, data)
        end
      end

      def yamldb_load_table(table_name, data)
        column_names = data['columns']
        execute("TRUNCATE #{table_name}") rescue execute("DELETE FROM #{table_name}")
        yamldb_load_records(table_name, column_names, data['records'])
        reset_pk_sequence!(table_name)
      end

      def yamldb_load_records(table, column_names, records)
        records.each do |record|
          execute "INSERT INTO #{table} (#{column_names.join(',')}) VALUES (#{record.map { |r| quote(r) }.join(',')})" 
        end
      end

      def reset_pk_sequence!(table_name)
      end
    end
  end
end
