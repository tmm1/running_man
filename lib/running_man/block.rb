module RunningMan
  class Block
    module TestClassMethods
      # Runs the given block 
      def setup_once(&block)
        test_block = RunningMan::Block.new(block)
        setup { test_block.run(self) }
      end
    end

    # block_arg - Optional Proc of code that runs only once for the test case.
    # &block    - The default Proc of code that runs only once.  Falls back to 
    #             block_arg if provided.
    #
    # Returns RunningMan::Block instance.
    def initialize(block_arg = nil, &block)
      @block = block || block_arg
      @run   = false
      @ivars = {}
      if !@block
        raise ArgumentError, "needs a block."
      end
    end

    # Public: This is what is run in the test/unit callback.  #run_once is 
    # called only the first time, and #run_always is always called.
    #
    # binding - Object that is running the test (usually a Test::Unit::TestCase).
    #
    # Returns nothing.
    def run(binding)
      if !run_once?
        @run = true
        run_once(binding)
      end
      run_always(binding)
    end

    # This runs the block and stores any new instance variables that were set.
    #
    # binding - The same Object that is given to #run.
    #
    # Returns nothing.
    def run_once(binding)
      @ivars.clear
      before = instance_variables
      instance_eval(&@block)
      (instance_variables - before).each do |ivar|
        @ivars[ivar] = instance_variable_get(ivar)
      end
    end

    # This sets the instance variables set from #run_once on the test case.
    # 
    # binding - The same Object that is given to #run.
    #
    # Returns nothing.
    def run_always(binding)
      @ivars.each do |ivar, value|
        set_ivar(binding, ivar, value)
      end
    end

    # Sets the given instance variable to the test case.
    #
    # binding - The same Object that is given to #run.
    # ivar    - String name of the instance variable to set.
    # value   - The Object value of the instance variable.
    def set_ivar(binding, ivar, value)
      binding.instance_variable_set(ivar, value)
    end

    # Determines whether #run_once has already been called.
    #
    # Returns a Boolean.
    def run_once?
      !!@run
    end
  end
end