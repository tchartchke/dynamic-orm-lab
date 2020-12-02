require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    table_info = DB[:conn].execute("PRAGMA table_info('#{table_name}')")
    column_names = []
    table_info.each do |col|
      column_names << col["name"]
    end
    column_names.compact
  end

  def initialize(options={})
    options.each { |key, val| send("#{key}=", val) }
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if { |col| col == 'id' }.join(', ')
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |attr|
      values << "'#{send(attr)}'" unless send(attr).nil?
    end
    values.join(', ')
  end

  def save
    DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})")
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(val)
    DB[:conn].execute("SELECT * FROM #{table_name} WHERE name = ?", val)
  end

  def self.find_by(hash)
    key = hash.keys.first
    value = hash.values.first
    DB[:conn].execute("SELECT * FROM #{table_name} WHERE #{key} = ?", value)
  end
end