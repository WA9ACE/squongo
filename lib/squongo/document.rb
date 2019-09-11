class Squongo::Document
  attr_accessor :data

  def initialize(data: {})
    @data = data
  end

  def save
    Squongo.save({ table: table, data: data })
  end

  def self.first
    Squongo.connection.db.execute "SELECT * FROM #{table} ORDER BY id LIMIT 1"
  end

  def self.last
    Squongo.connection.db.execute "SELECT * FROM #{table} ORDER BY id DESC LIMIT 1"
  end

  def self.all
    Squongo.connection.db.execute "SELECT * FROM #{table}"
  end

  def table
    self.class.table
  end

  def self.table
    self.const_get :TABLE
  end
end
