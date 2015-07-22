require_relative 'db_connection'

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

  def find_by(search_str)
    data = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{table_name}
    WHERE
      #{search_str}
    SQL

    data.empty? ? nil : parse_all(data)
  end

  def method_missing(method_name, *args)
    if method_name[0..7] == "find_by_"
      cols = method_name[8..-1].split("_and_")
      raise "You can't search by that" unless check_ivar?(cols)
      find_by(make_search_str(cols,args))
    end
  end

  def check_ivar?(cols)
    cols.all? { |col| columns.include?(col) }
  end

  def make_search_str(cols, values)
    search_arr = []
    cols.length.times do |idx|
      if values[idx].is_a?(Fixnum)
        search_arr << "#{cols[idx]} = #{values[idx]}"
      else
        search_arr << "#{cols[idx]} = '#{values[idx]}'"
      end
    end
    search_str = search_arr.join(" AND ")
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
