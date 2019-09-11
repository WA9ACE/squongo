class Squongo::Writer
  attr_reader :reader, :writer

  def initialize(reader, writer, parent_pid)
    @reader = reader
    @writer = writer
    @parent_pid = parent_pid
  end

  def start
    monitor_parent

    while packet = @reader.gets
      model_information = Squongo.ipc_decode(packet)

      table = model_information['table']
      data  = model_information['data']

      insert(table, data)
    end
  end

  def insert(table, data)
    Squongo.connection.db.execute "INSERT INTO #{table} (data, updated_at) VALUES(?, ?)", data.to_json, Squongo.timestamp
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
