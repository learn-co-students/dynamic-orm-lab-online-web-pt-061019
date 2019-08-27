require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    table_info = DB[:conn].execute("PRAGMA table_info('#{self.table_name}')")
    column_names = []
    table_info.each do |column|
      column_names << column["name"]
    end
    column_names.compact()
  end

  def initialize(attributes={})
    attributes.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    array = self.class.column_names.delete_if {|col| col == "id"}
    array.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |column_name|
      values << "'#{send(column_name)}'" unless send(column_name).nil?
      values.compact
    end
    values.join(", ")
  end

  def save
    sql = <<-SQL
    INSERT into #{table_name_for_insert}
    (#{col_names_for_insert})
    VALUES (#{values_for_insert})
    SQL
    DB[:conn].execute(sql)

    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = <<-SQL
    SELECT *
    FROM #{self.table_name}
    WHERE name = ?
    SQL
    @id = DB[:conn].execute(sql, name)
  end

  def self.find_by(attribute_hash)
    sql = <<-SQL
    SELECT *
    FROM #{self.table_name}
    WHERE #{attribute_hash.keys[0]} = '#{attribute_hash[attribute_hash.keys[0]]}'
    SQL
    answer = DB[:conn].execute(sql)
  end

end
