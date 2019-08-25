require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def table_name_for_insert
    self.class.table_name
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "PRAGMA table_info('#{table_name}')"

    table_columns = DB[:conn].execute(sql)
    column_names = []

    table_columns.each do |column|
      column_names << column["name"] # Name, gets the text, one of the columns properties
    end

    column_names.compact # Compact removes any nil columns
  end

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    values = []

    self.class.column_names.each do |column|
      values << "'#{send(column)}'" unless send(column).nil?
    end
    values.join(", ")
  end

#   def values_for_insert
#   values = []
#   self.class.column_names.each do |col_name|
#     values << "'#{send(col_name)}'" unless send(col_name).nil?
#   end
#   values.join(", ")
# end

  def save
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert});
    SQL

    DB[:conn].execute(sql)

    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

#   def save
#   sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
#
#   DB[:conn].execute(sql)
#
#   @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
#   end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM #{table_name} WHERE name = ?;
    SQL

    DB[:conn].execute(sql, name)
  end

  def self.find_by(hash)
    attribute = hash.first[0].to_s
    value = hash.first[1]

    if attribute == attribute.to_i
      attribute = attribute.to_i
    end

    sql = <<-SQL
        SELECT * FROM #{table_name} WHERE #{attribute} = "#{value}";
    SQL

    # select * from table where columnname =

    # inputs = []
    # hash.each do |attribute, value|
    #   inputs <<
    # end
    # key = "value"

    DB[:conn].execute(sql)

    # {name: "Susan"}
  end
end
