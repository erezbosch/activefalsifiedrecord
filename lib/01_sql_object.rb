require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns
    DBConnection.execute2(<<-SQL).first.map(&:to_sym)
      SELECT
        *
      FROM
        #{table_name}
    SQL
  end

  def self.finalize!
    define_method(:attributes) do |key = nil, value = nil|
      @attributes ||= {}
      @attributes[key] = value if key && value
      @attributes
    end

    columns.each do |col|
      define_method(col) { attributes[col] }
      define_method("#{col}=") { |value| attributes(col, value) }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    parse_all(DBConnection.execute("SELECT * FROM #{table_name}"))
  end

  def self.parse_all(results)
    results.map { |result| new(result) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id: id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = :id
    SQL

    return nil if results.empty?
    new(results.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      unless self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      end

      send("#{attr_name}=", value)
    end
  end

  def attribute_values
    self.class.columns.map { |col| send(col) }
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * self.class.columns.length).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    attributes(:id, DBConnection.last_insert_row_id)
  end

  def update
    attr_equalities = self.class.columns.map { |col| "#{col} = ?"}.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{attr_equalities}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
