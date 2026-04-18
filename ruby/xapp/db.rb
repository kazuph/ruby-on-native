# backtick_javascript: true
module XApp
  # Thin Ruby wrapper around `expo-sqlite` exposed via `__RN__.SQLite`. We
  # let the JS side own the connection handle and statement lifetime so the
  # Ruby call sites read like sqlite3-ruby (`db.exec`, `db.run`, `db.all`)
  # without any `prepareSync/finalizeSync` boilerplate leaking through.
  class DB
    def self.open(name = 'xapp.db')
      new(name)
    end

    def initialize(name)
      @name = name
      @handle = `__RN__.SQLite.open(#{name})`
    end

    attr_reader :name

    # Execute one or more statements. Use for schema / DDL.
    def exec(sql)
      `__RN__.SQLite.exec(#{@handle}, #{sql})`
      nil
    end

    # Run a prepared statement with bound parameters. Returns a Ruby Hash
    # like `{ changes: 1, last_insert_rowid: 42 }`.
    def run(sql, *params)
      js_params = XApp::UI.deep_to_native(params)
      res_js = `__RN__.SQLite.run(#{@handle}, #{sql}, #{js_params})`
      {
        changes: `#{res_js}.changes`,
        last_insert_rowid: `#{res_js}.lastInsertRowId`
      }
    end

    # Fetch all rows as `[{ :col_a => value, :col_b => value }, ...]`.
    def all(sql, *params)
      js_params = XApp::UI.deep_to_native(params)
      rows_js = `__RN__.SQLite.all(#{@handle}, #{sql}, #{js_params})`
      XApp::UI.js_to_rb(rows_js)
    end

    # Convenience for `SELECT COUNT(*) ...` style one-cell queries.
    def scalar(sql, *params)
      row = all(sql, *params).first
      row && row.values.first
    end

    def first(sql, *params)
      all(sql, *params).first
    end
  end
end
