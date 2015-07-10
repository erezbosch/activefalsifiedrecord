require_relative '02_searchable'
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
    define_method(name) do
      p_key_val = send(options.primary_key)
      options.model_class.where(options.foreign_key => p_key_val)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
