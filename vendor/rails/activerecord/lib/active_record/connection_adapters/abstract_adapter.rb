require 'benchmark'
require 'date'
require 'bigdecimal'
require 'bigdecimal/util'

require 'active_record/connection_adapters/abstract/schema_definitions'
require 'active_record/connection_adapters/abstract/schema_statements'
require 'active_record/connection_adapters/abstract/database_statements'
require 'active_record/connection_adapters/abstract/quoting'
require 'active_record/connection_adapters/abstract/connection_pool'
require 'active_record/connection_adapters/abstract/connection_specification'
require 'active_record/connection_adapters/abstract/query_cache'

module ActiveRecord
  module ConnectionAdapters # :nodoc:
    # All the concrete database adapters follow the interface laid down in this class.
    # You can use this interface directly by borrowing the database connection from the Base with
    # Base.connection.
    #
    # Most of the methods in the adapter are useful during migrations.  Most
    # notably, SchemaStatements#create_table, SchemaStatements#drop_table,
    # SchemaStatements#add_index, SchemaStatements#remove_index,
    # SchemaStatements#add_column, SchemaStatements#change_column and
    # SchemaStatements#remove_column are very useful.
    class AbstractAdapter
      include Quoting, DatabaseStatements, SchemaStatements
      include QueryCache
      include ActiveSupport::Callbacks
      define_callbacks :checkout, :checkin
      checkout :reset!
      @@row_even = true

      def initialize(connection, logger = nil) #:nodoc:
        @connection, @logger = connection, logger
        @runtime = 0
        @last_verification = 0
        @query_cache_enabled = false
      end

      # Returns the human-readable name of the adapter.  Use mixed case - one
      # can always use downcase if needed.
      def adapter_name
        'Abstract'
      end

      # Does this adapter support migrations?  Backend specific, as the
      # abstract adapter always returns +false+.
      def supports_migrations?
        false
      end

      # Does this adapter support using DISTINCT within COUNT?  This is +true+
      # for all adapters except sqlite.
      def supports_count_distinct?
        true
      end

      # Does this adapter support DDL rollbacks in transactions?  That is, would
      # CREATE TABLE or ALTER TABLE get rolled back by a transaction?  PostgreSQL,
      # SQL Server, and others support this.  MySQL and others do not.
      def supports_ddl_transactions?
        false
      end

      # Should primary key values be selected from their corresponding
      # sequence before the insert statement?  If true, next_sequence_value
      # is called before each insert to set the record's primary key.
      # This is false for all adapters but Firebird.
      def prefetch_primary_key?(table_name = nil)
        false
      end

      def reset_runtime #:nodoc:
        rt, @runtime = @runtime, 0
        rt
      end

      # QUOTING ==================================================

      # Override to return the quoted table name. Defaults to column quoting.
      def quote_table_name(name)
        quote_column_name(name)
      end

      # REFERENTIAL INTEGRITY ====================================

      # Override to turn off referential integrity while executing <tt>&block</tt>.
      def disable_referential_integrity(&block)
        yield
      end

      # CONNECTION MANAGEMENT ====================================

      # Is this connection active and ready to perform queries?
      def active?
        @active != false
      end

      # Close this connection and open a new one in its place.
      def reconnect!
        @active = true
      end

      # Close this connection
      def disconnect!
        @active = false
      end

      # Reset the state of this connection, directing the DBMS to clear
      # transactions and other connection-related server-side state. Usually a
      # database-dependent operation; the default method simply executes a
      # ROLLBACK and swallows any exceptions which is probably not enough to
      # ensure the connection is clean.
      def reset!
        # this should be overridden by concrete adapters
      end

      # Returns true if its safe to reload the connection between requests for development mode.
      # This is not the case for Ruby/MySQL and it's not necessary for any adapters except SQLite.
      def requires_reloading?
        false
      end

      # Verify this connection by calling <tt>active?</tt> and reconnecting if
      # the connection is no longer active.
      def verify!(*ignored)
        reconnect! unless active?
      end

      # Provides access to the underlying database connection. Useful for
      # when you need to call a proprietary method such as postgresql's lo_*
      # methods
      def raw_connection
        @connection
      end

      def open_transactions
        @open_transactions ||= 0
      end

      def increment_open_transactions
        @open_transactions ||= 0
        @open_transactions += 1
      end

      def decrement_open_transactions
        @open_transactions -= 1
      end

      def log_info(sql, name, seconds)
        if @logger && @logger.debug?
          name = "#{name.nil? ? "SQL" : name} (#{sprintf("%.1f", seconds * 1000)}ms)"
          @logger.debug(format_log_entry(name, sql.squeeze(' ')))
        end
      end

      protected
        def log(sql, name)
          if block_given?
            result = nil
            seconds = Benchmark.realtime { result = yield }
            @runtime += seconds
            log_info(sql, name, seconds)
            result
          else
            log_info(sql, name, 0)
            nil
          end
        rescue Exception => e
          # Log message and raise exception.
          # Set last_verification to 0, so that connection gets verified
          # upon reentering the request loop
          @last_verification = 0
          message = "#{e.class.name}: #{e.message}: #{sql}"
          log_info(message, name, 0)
          raise ActiveRecord::StatementInvalid, message
        end

        def format_log_entry(message, dump = nil)
          if ActiveRecord::Base.colorize_logging
            if @@row_even
              @@row_even = false
              message_color, dump_color = "4;36;1", "0;1"
            else
              @@row_even = true
              message_color, dump_color = "4;35;1", "0"
            end

            log_entry = "  \e[#{message_color}m#{message}\e[0m   "
            log_entry << "\e[#{dump_color}m%#{String === dump ? 's' : 'p'}\e[0m" % dump if dump
            log_entry
          else
            "%s  %s" % [message, dump]
          end
        end
    end
  end
end