module RunningMan
  # Allow simple setup:
  #
  #   RunningMan.setup_on Test::Unit::TestCase, :ActiveRecordBlock
  #
  # See README for instructions on use.
  class ActiveRecordBlock < Block
    module TestClassMethods
      # Runs this block once, which should insert records through ActiveRecord.
      # Test Cases should only have one #fixtures call, and it should be at the
      # first run callback.
      def fixtures(&block)
        RunningMan::ActiveRecordBlock.new(block).setup(self)
      end
    end

    # Ensure the block is setup to run first, and that the test run is wrapped
    # in a database transaction.
    def setup(test_class)
      block = self
      test_class.setup    { block.run(self) }
      test_class.teardown { block.teardown_transaction }
    end

    # Clear the database before running the block.
    def run_once(binding)
      clear_database
      super
    end

    # Sets up an ActiveRecord transition before every test.
    def run(binding)
      super
      setup_transaction
    end

    # Open a new transaction before running any test.
    def setup_transaction
      ActiveRecord::Base.connection.increment_open_transactions
      ActiveRecord::Base.connection.begin_db_transaction
    end

    # Rollback our transaction, returning our fixtures to a pristine state.
    def teardown_transaction
      ActiveRecord::Base.connection.rollback_db_transaction
      ActiveRecord::Base.connection.decrement_open_transactions
      ActiveRecord::Base.clear_active_connections!
    end

    # reload any AR instances
    def set_ivar(binding, ivar, value)
      if value.class.respond_to?(:find)
        value = value.class.find(value.id)
      end
      super(binding, ivar, value)
    end

    def clear_database
      conn = ActiveRecord::Base.connection
      conn.tables.each do |table|
        conn.delete "DELETE FROM #{table}"
      end
    end
  end
end
