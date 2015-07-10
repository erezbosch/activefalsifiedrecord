require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where!(params)
    where_line = params.keys.map { |key| "#{key} = ?" }.join(" AND ")
    parse_all(DBConnection.execute(<<-SQL, *params.values))
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_line}
    SQL
  end

  def where(params)
    Relation.new(self).where(params)
  end


  class Relation < BasicObject
    def initialize(obj_class)
      @klass = obj_class
    end

    def where(params)
      conditions.merge!(params)
      self
    end

    def conditions
      @conditions ||= {}
    end

    def method_missing(method_name, *args)
      execute_search.send(method_name, *args)
    end

    def execute_search
      @klass.where!(conditions)
    end
  end
end

class SQLObject
  extend Searchable
end
