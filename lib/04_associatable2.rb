require_relative '03_associatable'

module Associatable
  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      through_table = through_options.model_class.table_name
      through_p_key = through_options.primary_key

      source_table = source_options.model_class.table_name
      source_f_key = source_options.foreign_key
      source_p_key = source_options.primary_key

      f_key_value = send(through_options.foreign_key)

      result = DBConnection.execute(<<-SQL, f_key_value).first
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table}
        ON
          #{through_table}.#{source_f_key} = #{source_table}.#{source_p_key}
        WHERE
          #{through_table}.#{through_p_key} = ?
      SQL

      source_options.model_class.new(result)
    end
  end

  # SCENARIOS
  # many => many: house has many humans which have many cats
  # belongs => many: cat belongs to human which has dogs
  # many => belongs: house has many cats which belong to human
  # 1 down
  # 2...

  def has_many_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      through_table = through_options.model_class.table_name
      through_f_key = through_options.foreign_key

      source_table = source_options.model_class.table_name
      source_f_key = source_options.foreign_key
      source_p_key = source_options.primary_key

      through_many = through_options.instance_of? HasManyOptions
      source_many = source_options.instance_of? HasManyOptions

      if through_many && source_many
        p_key_value = send(through_options.primary_key)

        results = DBConnection.execute(<<-SQL, p_key_value)
          SELECT
            #{source_table}.*
          FROM
            #{through_table}
          JOIN
            #{source_table}
          ON
            #{through_table}.#{source_p_key} = #{source_table}.#{source_f_key}
          WHERE
            #{through_table}.#{through_f_key} = ?
        SQL

      elsif source_many
        through_p_key = through_options.primary_key
        f_key_value = send(through_options.foreign_key)

        results = DBConnection.execute(<<-SQL, f_key_value)
          SELECT
            #{source_table}.*
          FROM
            #{through_table}
          JOIN
            #{source_table}
          ON
            #{through_table}.#{through_p_key} = #{source_table}.#{source_f_key}
          WHERE
            #{through_table}.#{through_p_key} = ?
        SQL
      end

      results.map { |result| source_options.model_class.new(result) }
    end
  end

  # def execute_sql_query(params)
end
