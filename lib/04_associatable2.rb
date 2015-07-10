require_relative '03_associatable'

module Associatable
  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      thru_table = through_options.model_class.table_name
      thru_p_key = through_options.primary_key

      source_table = source_options.model_class.table_name
      source_f_key = source_options.foreign_key
      source_p_key = source_options.primary_key

      f_key_value = send(through_options.foreign_key)

      result = DBConnection.execute(<<-SQL, f_key_value).first
        SELECT
          #{source_table}.*
        FROM
          #{thru_table}
        JOIN
          #{source_table}
        ON
          #{thru_table}.#{source_f_key} = #{source_table}.#{source_p_key}
        WHERE
          #{thru_table}.#{thru_p_key} = ?
      SQL

      source_options.model_class.new(result)
    end
  end
end
