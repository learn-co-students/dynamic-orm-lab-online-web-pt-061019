require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    table_columns = DB[:conn].execute("PRAGMA table_info(#{table_name})")
    column_names = []

    table_columns.each do |column|
      column_names << column["name"]
    end
    column_names.compact
  end

  def initialize(options={})
    options.each do |project, value|
      self.send("#{project}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    values = []

    self.class.column_names.each do |column_name|
      values << "'#{send(column_name)}'" unless send(column_name).nil?
    end
    values.join(", ")
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert}(#{col_names_for_insert}) VALUES (#{values_for_insert})"

    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{table_name} WHERE name = ?"

    DB[:conn].execute(sql, name)
  end

  def self.find_by(attribute)
    column_name = attribute.keys[0].to_s
    value_of_column = attribute.values[0]

    sql = "SELECT * FROM #{table_name} WHERE #{column_name} = ?"

    DB[:conn].execute(sql, value_of_column)
  end
end
