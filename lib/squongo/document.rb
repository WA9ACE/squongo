require 'date'

class Squongo::Document
  attr_accessor :data
  attr_reader :id, :created_at, :updated_at

  def initialize(data: {}, id: nil, created_at: nil, updated_at: nil)
    @data = data
    @id = id
    @created_at = created_at
    @updated_at = updated_at
  end

  def save
    id = Squongo.save(id: id, table: table, data: data)
    document = self.class.find(id)

    @id = document.id
    @created_at = document.created_at
    @updated_at = document.updated_at
  end

  def self.from_row(fields)
    id, data, created_at, updated_at = fields

    new(
      data: JSON.parse(data),
      id: id,
      created_at: DateTime.parse(created_at),
      updated_at: DateTime.parse(updated_at)
    )
  end

  def self.find(id)
    query = "SELECT * FROM #{table} WHERE id = ?"
    Squongo.connection.db.execute(query, id).map { |row| from_row(row) }.first
  end

  def self.find_by(set)
    field = set.keys.first
    value = set.values.first
    query = "SELECT * FROM #{table} WHERE "

    terms = paths(set)

    terms.each_with_index do |term, index|
      if index == 0
        query << "json_extract(data, ?) = ? "
      else
        query << "AND json_extract(data, ?) = ? "
      end
    end

    params = terms.map do |x|
      if x[:value].is_a?(Array)
        ["$.#{x[:path]}", "[#{x[:value] * ','}]"]
      else
        ["$.#{x[:path]}", x[:value]]
      end
    end.flatten(1)

    rows = Squongo.connection.db.execute(query, params)
    documents = rows.map { |row| from_row(row) }

    return documents.first if documents.length == 1

    documents
  end

  def self.first
    Squongo.connection.db.execute("SELECT * FROM #{table} ORDER BY id LIMIT 1")
           .map { |row| from_row(row) }.first
  end

  def self.last
    Squongo.connection.db.execute("SELECT * FROM #{table} ORDER BY id DESC LIMIT 1")
           .map { |row| from_row(row) }.first
  end

  def self.all
    Squongo.connection.db.execute("SELECT * FROM #{table}")
           .map { |row| from_row(row) }
  end

  def table
    self.class.table
  end

  def self.table
    const_get :TABLE
  end

  def self.descend(hash, acc: nil)
    hash.map do |k, v|
      if v.is_a? Hash
        descend(v, acc: "#{acc}.#{k}")
      else
        path = "#{acc}.#{k}"
        { path: path, value: v }
      end
    end
  end
  
  def self.paths(hash)
    descend(hash).flatten.map { |x|
      {
        path: x[:path][1..-1],
        value: x[:value]
      }
    }
  end
end
