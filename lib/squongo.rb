# frozen_string_literal: true

require 'json'
require 'base64'

require 'squongo/namespace'
require 'squongo/version'
require 'squongo/connection'
require 'squongo/document'
require 'squongo/writer'

module Squongo
  TABLES_QUERY = 'SELECT name FROM sqlite_master WHERE type="table";'
  TABLE_SCHEMA = '(
    id INTEGER PRIMARY KEY NOT NULL,
    data JSON NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  );'

  def self.connect(path)
    @@connection = Connection.connect(path)
    migrate_database
    start_writer
  end

  def self.reconnect
    @@connection.reconnect
  end

  def self.migrate_database
    missing_tables.each do |table|
      create_table table
    end
  end

  def self.missing_tables
    document_types - tables
  end

  def self.document_types
    ObjectSpace.each_object(Class)
               .select { |klass| klass < Squongo::Document }
               .map(&:table)
  end

  def self.tables
    connection.db.execute(TABLES_QUERY).flatten.map(&:to_sym)
  end

  def self.create_table(name)
    create_table_query = "CREATE TABLE #{name} #{TABLE_SCHEMA}"
    connection.db.execute create_table_query
  end

  def self.connection
    @@connection
  end

  def self.save(model_information)
    @@writer.puts ipc_encode(model_information)

    id = @@response_reader.gets
    id.to_i
  end

  def self.ipc_encode(data)
    Base64.strict_encode64 data.to_json.to_s
  end

  def self.ipc_decode(packet)
    JSON.parse Base64.decode64(packet)
  end

  def self.start_writer
    @@reader, @@writer = IO.pipe

    @@response_reader, @@response_writer = IO.pipe

    @@squongo_writer = Squongo::Writer.new(
      @@reader,
      @@writer,
      @@response_reader,
      @@response_writer,
      Process.pid
    )

    Squongo.connection.close

    @@pid = fork do
      @@squongo_writer.start
    end

    Squongo.reconnect
  end

  def self.timestamp
    DateTime.now.strftime('%Y-%m-%d %H:%M:%S')
  end
end
