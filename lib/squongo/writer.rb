# frozen_string_literal: true

class Squongo::Writer
  attr_reader :reader, :writer, :response_writer

  def initialize(reader, writer, response_reader, response_writer, parent_pid)
    @reader = reader
    @writer = writer

    @response_reader = response_reader
    @response_writer = response_writer

    @parent_pid = parent_pid
  end

  def start
    monitor_parent

    while packet = @reader.gets
      model_information = Squongo.ipc_decode(packet)

      id = model_information['id']
      table = model_information['table']
      data  = model_information['data']

      if id.nil?
        id = insert(table, data)
        respond(id)
      else
        update(id, table, data)
      end
    end
  end

  def update(id, table, data)
    Squongo.connection.db.execute(
      "UPDATE #{table} SET data = json(?), updated_at = ? WHERE id = ?",
      [data.to_json, Squongo.timestamp, id]
    )
  end

  def insert(table, data)
    timestamp = Squongo.timestamp

    Squongo.connection.db.execute(
      "INSERT INTO #{table} (data, created_at, updated_at) VALUES(?, ?, ?)",
      [data.to_json, timestamp, timestamp]
    )

    Squongo.connection.db.last_insert_row_id
  end

  def respond(id)
    response_writer.puts id
  end

  def should_live
    Process.getpgid(@parent_pid)
    true
  rescue Errno::ESRCH
    false
  end

  def monitor_parent
    @monitor_thread = Thread.new do
      loop do
        exit unless should_live
        sleep 0.1
      end
    end
  end
end
