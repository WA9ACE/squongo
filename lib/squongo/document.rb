# frozen_string_literal: true

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
    query = "SELECT * FROM #{table} WHERE json_extract(data, ?) = ?"
    rows = Squongo.connection.db.execute(query, ["$.#{field}", value])
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
end
