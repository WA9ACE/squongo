# frozen_string_literal: true

require 'sqlite3'

class Squongo::Connection
  WAL_QUERY = 'PRAGMA journal_mode=WAL;'

  attr_reader :db, :path

  def initialize(path)
    @path = path
    @db = SQLite3::Database.open(path)
    ensure_mode
  end

  def reconnect
    @db = SQLite3::Database.open(path)
  end

  def self.connect(path)
    new(path)
  end

  def ensure_mode
    return unless first_connection

    wal_mode
  end

  def wal_mode
    @db.execute WAL_QUERY
  end

  def first_connection
    !File.exist?(path)
  end
end
