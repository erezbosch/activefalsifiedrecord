require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    options = {
      primary_key: :id,
      foreign_key: "#{name}_id".to_sym,
      class_name: name.to_s.camelcase
    }.merge(options)

    self.primary_key, self.foreign_key, self.class_name =
      options.values_at(:primary_key, :foreign_key, :class_name)
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options = {
      primary_key: :id,
      foreign_key: "#{self_class_name.underscore.downcase}_id".to_sym,
      class_name: name.to_s.singularize.camelcase
    }.merge(options)

    self.primary_key, self.foreign_key, self.class_name =
      options.values_at(:primary_key, :foreign_key, :class_name)
  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method(name) do
      f_key_val = send(options.foreign_key)
      options.model_class.where(options.primary_key => f_key_val).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    assoc_options[name] = options

    define_method(name) do
      p_key_val = send(options.primary_key)
      options.model_class.where(options.foreign_key => p_key_val)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end

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

  def has_many_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      through_table = through_options.model_class.table_name
      through_f_key = through_options.foreign_key
      through_p_key = through_options.primary_key

      source_table = source_options.model_class.table_name
      source_f_key = source_options.foreign_key
      source_p_key = source_options.primary_key

      params = { one: source_table, two: through_table }

      through_many = through_options.instance_of? HasManyOptions
      source_many = source_options.instance_of? HasManyOptions

      if through_many && source_many
        params[:one_k] = source_f_key
        params[:two_k] = source_p_key
        params[:three_k] = through_f_key
        value = send(through_options.primary_key)
      elsif source_many
        params[:one_k] = source_f_key
        params[:two_k] = through_p_key
        params[:three_k] = through_p_key
        value = send(through_options.foreign_key)
      end

      results = self.class.execute_sql_query(params, value)

      results.map { |result| source_options.model_class.new(result) }
    end
  end

  def execute_sql_query(params, value)
    DBConnection.execute(<<-SQL, value)
      SELECT
        #{params[:one]}.*
      FROM
        #{params[:two]}
      JOIN
        #{params[:one]}
      ON
        #{params[:one]}.#{params[:one_k]} = #{params[:two]}.#{params[:two_k]}
      WHERE
        #{params[:two]}.#{params[:three_k]} = ?
    SQL
  end
end
