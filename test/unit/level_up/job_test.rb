require 'test_helper'
require 'delayed_job_active_record'


module LevelUp
  class TestJob < Job
    job do
      state :start, moves_to: :first_node
      state :first_node, moves_to: [:second_node, :error_node, :timer_node, :task_node]
      state :second_node, moves_to: [:end]
      state :error_node
      state :timer_node
      state :task_node
    end

    def second_node
      move_to :end
    end
  end

  class CustomStateJob < LevelUp::Job
    job do
      state :start, class_name: "CustomNode", moves_to: :first_node
      state :first_node, class_name: "CustomNode", moves_to: :end
      state :cancel, class_name: "CustomNode"
      state :end, class_name: "CustomNode"
    end

    def first_node
    end
  end

  class CustomNodeError < StandardError
  end

  class CustomNode < LevelUp::State
    def run
      raise CustomNodeError.new("raised from state #{job.state}")
    end
  end

  class AbstractFirstNode < State
    def run
      move_to :second_node
    end
  end

  class TestJob::FirstNode < AbstractFirstNode
  end

  class TestJob::ErrorNode < State
    def run
      raise "bad news"
    end
  end

  class TestJob::TimerNode < State
    def run
      retry_in 1.hour
    end
  end

  class TestJob::TaskNode < State
    def run
      manual_task "a lot of work"
    end
  end

  class LevelUpTest < ActiveSupport::TestCase
    def setup
      @job = TestJob.create
      @custom_state_job = CustomStateJob.create
    end

    test "should return the schema" do
      assert_equal({
        start: [:first_node],
        first_node: [:second_node, :error_node, :timer_node, :task_node],
        second_node: [:end],
        error_node: [],
        timer_node: [],
        task_node: [],
        end: []
      }, @job.schema)
    end

    test "should return the list of states" do
      assert_equal([:start, :first_node, :second_node, :error_node, :timer_node, :task_node, :end], @job.states)
    end

    test "should return list of transitions for a given state" do
      assert_equal([:first_node], @job.transitions(:start))
      assert_equal([:first_node], @job.state_transitions)

      @job.state = "first_node"
      assert_equal([:second_node, :error_node, :timer_node, :task_node], @job.transitions(:first_node))
      assert_equal([:second_node, :error_node, :timer_node, :task_node], @job.state_transitions)

      @job.state = "second_node"
      assert_equal([:end], @job.transitions(:second_node))
      assert_equal([:end], @job.state_transitions)

      @job.state = "error_node"
      assert_equal([], @job.transitions(:error_node))
      assert_equal([], @job.state_transitions)

      @job.state = "timer_node"
      assert_equal([], @job.transitions(:timer_node))
      assert_equal([], @job.state_transitions)

      @job.state = "task_node"
      assert_equal([], @job.transitions(:task_node))
      assert_equal([], @job.state_transitions)

      @job.state = "end"
      assert_equal([], @job.transitions(:end))
      assert_equal([], @job.state_transitions)
    end

    test "should raise a state not found error" do
      error = assert_raise(StateNotFound) { @job.transitions(:unknown_state) }
      assert_match("unknown_state", error.message)
    end

    test "should set the started_at attribute when starting a job" do
      assert_nil(@job.started_at)
      @job.boot!
      assert_not_nil(@job.started_at)
    end

    test "should change state" do
      assert_equal(true, @job.state?(:start))
      @job.boot!
      assert_equal(true, @job.state?(:end))
    end

    test "should set the end_at attribute when ending a job" do
      assert_nil(@job.ended_at)
      @job.boot!
      assert_not_nil(@job.ended_at)
    end

    test "should set the error attribute when rescuing from an error" do
      assert_equal(false, @job.error)
      assert_nil(@job.failed_at)
      assert_nil(@job.failed_in)
      assert_nil(@job.backtrace)

      @job.state = "error_node"
      @job.boot!
      assert_equal(true, @job.error)
      assert_not_nil(@job.failed_at)
      assert_equal("error_node", @job.failed_in)
      assert_not_nil(@job.backtrace)
    end

    test "should set the timer attribute when retrying a state" do
      assert_equal(false, @job.timer)
      assert_nil(@job.retry_at)
      assert_nil(@job.delayed_job_id)

      @job.state = "timer_node"
      @job.boot!
      assert_equal(true, @job.timer)
      assert_not_nil(@job.retry_at)
      assert_not_nil(@job.delayed_job_id)
    end

    test "should set the task and description attributes when falling in human manual task" do
      assert_equal(false, @job.task)
      assert_nil(@job.task_description)

      @job.state = "task_node"
      @job.boot!
      assert_equal(true, @job.task)
      assert_not_nil(@job.task_description)
    end

    test "should disallow transition" do
      assert_equal(true, @job.state?(:start))
      @job.event!(nil, false)
      assert_equal(true, @job.state?(:start))
    end

    test "should allow transition" do
      assert_equal(true, @job.state?(:start))
      @job.event!(nil, true)
      assert_equal(true, @job.state?(:end))
    end

    test "should disallow retry" do
      assert_equal(false, @job.timer)
      assert_nil(@job.retry_at)
      @job.state = "timer_node"

      @job.event!(nil, true, false)
      assert_equal(false, @job.timer)
      assert_nil(@job.retry_at)
      assert_nil(@job.delayed_job_id)
    end

    test "should allow retry" do
      assert_equal(false, @job.timer)
      assert_nil(@job.retry_at)
      @job.state = "timer_node"

      @job.event!(nil, true, true)
      assert_equal(true, @job.timer)
      assert_not_nil(@job.retry_at)
      assert_not_nil(@job.delayed_job_id)
    end

    test "should have a delayed_job" do
      assert_nil(@job.delayed_job_id)
      delay = @job.boot_async!
      assert_equal(true, delay)
      assert_not_nil(@job.delayed_job_id)
    end

    test "should destroy a delayed_job" do
      delay = @job.boot_async!
      assert_equal(true, delay)
      assert_not_nil(@job.delayed_job_id)

      @job.unqueue!
      assert_nil(@job.delayed_job_id)
    end

    test "should have custom state classes" do
      assert_equal(true, @custom_state_job.class.state_classes.key?(:start))
      assert_equal("CustomNode", @custom_state_job.class.state_classes[:start])
      assert_equal(true, @custom_state_job.class.state_classes.key?(:first_node))
      assert_equal("CustomNode", @custom_state_job.class.state_classes[:first_node])
      assert_equal(true, @custom_state_job.class.state_classes.key?(:cancel))
      assert_equal("CustomNode", @custom_state_job.class.state_classes[:cancel])
      assert_equal(true, @custom_state_job.class.state_classes.key?(:end))
      assert_equal("CustomNode", @custom_state_job.class.state_classes[:end])
    end

    test "should use the custom state and raise an error" do
      %w[start end cancel].each do
        @custom_state_job.clear!(nil)
        assert_equal(false, @custom_state_job.error)
        @custom_state_job.boot!
        assert_equal(true, @custom_state_job.error)
        assert_equal("start", @custom_state_job.failed_in)
      end
    end

    test "should not use the custom state when a state method is defined" do
      assert_equal(false, @custom_state_job.error)
      @custom_state_job.state = "first_node"
      @custom_state_job.boot!
      assert_equal(false, @custom_state_job.error)
      assert_equal(true, @custom_state_job.state?(:first_node))
    end
  end
end
