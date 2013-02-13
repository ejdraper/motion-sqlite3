module SQLite3
  class Database
    def initialize(filename)
      @handle = Pointer.new(Sqlite3.type)

      result = sqlite3_open(filename, @handle)
      raise DatabaseError.from_last_error(@handle) if result != SQLITE_OK
    end

    def execute(sql, params = nil, &block)
      raise ArgumentError if sql.nil?

      prepare(sql, params) do |statement|
        results = statement.execute

        if block_given?
          results.each do |result|
            yield result
          end
        end
      end
    end

    def execute_scalar(*args)
      result = {}

      execute(*args) do |row|
        result[:value] ||= row.values.first
      end

      result[:value]
    end

    def transaction(&block)
      execute("BEGIN TRANSACTION")

      begin
        yield
      rescue
        execute("ROLLBACK TRANSACTION")
        raise
      else
        execute("COMMIT TRANSACTION")
      end
    end

    def sqlite_version
      sqlite3_libversion
    end

    private
    def prepare(sql, params, &block)
      statement = Statement.new(@handle, sql, params)

      begin
        yield statement

      ensure
        statement.finalize
      end
    end
  end
end
