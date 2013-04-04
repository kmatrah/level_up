require 'test_helper'
require 'delayed_job_active_record'


module LevelUp
  class TestJob < Job
    job do
      task :start, transitions: :first_node
      task :first_node, transitions: [:second_node, :error_node, :timer_node, :task_node]
      task :second_node, transitions: [:end]
      task :error_node
      task :timer_node
      task :task_node
    end

    def second_node
      move_to! :end
    end
  end

  class CustomTaskJob < LevelUp::Job
    job do
      task :start, class_name: "CustomNode", transitions: :first_node
      task :first_node, class_name: "CustomNode", transitions: :end
      task :cancel, class_name: "CustomNode"
      task :end, class_name: "CustomNode"
    end

    def first_node
    end
  end

  class CustomTaskError < StandardError
  end

  class CustomTask < Task
    def run
      raise CustomTaskError.new("raised from task #{job.task}")
    end
  end

  class AbstractFirstNode < Task
    def run
      move_to! :second_node
    end
  end

  class TestJob::FirstNode < AbstractFirstNode
  end

  class TestJob::ErrorNode < Task
    def run
      raise "bad news"
    end
  end

  class TestJob::TimerNode < Task
    def run
      retry_in! 1.hour
    end
  end

  class TestJob::TaskNode < Task
    def run
      manual_task! "a lot of work"
    end
  end

  class LevelUpTest < ActiveSupport::TestCase
    def setup
      @job = TestJob.create
      @custom_task_job = CustomTaskJob.create
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

    test "should return the list of tasks" do
      assert_equal([:start, :first_node, :second_node, :error_node, :timer_node, :task_node, :end], @job.tasks)
    end

    test "should return list of transitions for a given task" do
      assert_equal([:first_node], @job.transitions(:start))
      assert_equal([:first_node], @job.task_transitions)

      @job.task = "first_node"
      assert_equal([:second_node, :error_node, :timer_node, :task_node], @job.transitions(:first_node))
      assert_equal([:second_node, :error_node, :timer_node, :task_node], @job.task_transitions)

      @job.task = "second_node"
      assert_equal([:end], @job.transitions(:second_node))
      assert_equal([:end], @job.task_transitions)

      @job.task = "error_node"
      assert_equal([], @job.transitions(:error_node))
      assert_equal([], @job.task_transitions)

      @job.task = "timer_node"
      assert_equal([], @job.transitions(:timer_node))
      assert_equal([], @job.task_transitions)

      @job.task = "task_node"
      assert_equal([], @job.transitions(:task_node))
      assert_equal([], @job.task_transitions)

      @job.task = "end"
      assert_equal([], @job.transitions(:end))
      assert_equal([], @job.task_transitions)
    end

    test "should raise a task not found error" do
      error = assert_raise(TaskNotFound) { @job.transitions(:unknown_task) }
      assert_match("unknown_task", error.message)
    end

    test "should set the started_at attribute when starting a job" do
      assert_nil(@job.started_at)
      @job.boot!
      assert_not_nil(@job.started_at)
    end

    test "should change task" do
      assert_equal(true, @job.task?(:start))
      @job.boot!
      assert_equal(true, @job.task?(:end))
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

      @job.task = "error_node"
      @job.boot!
      assert_equal(true, @job.error)
      assert_not_nil(@job.failed_at)
      assert_equal("error_node", @job.failed_in)
      assert_not_nil(@job.backtrace)
    end

    test "should set the backtrace attribute with the default backtrace size when rescuing from an error" do
      @job.task = "error_node"
      @job.boot!
      assert_not_nil(@job.backtrace)
      assert_equal(true, @job.backtrace.size <= Configuration::DEFAULT_BACKTRACE_SIZE)
    end

    test "should set the backtrace attribute with a custom backtrace size of 1 when rescuing from an error" do
      Rails.configuration.level_up.backtrace_size = 1
      @job.task = "error_node"
      @job.boot!
      assert_not_nil(@job.backtrace)
      assert_equal(true, @job.backtrace.size <= Configuration.backtrace_size)
    end

    test "should not set the backtrace attribute with a custom backtrace size of 0 when rescuing from an error" do
      Rails.configuration.level_up.backtrace_size = 0
      @job.task = "error_node"
      @job.boot!
      assert_nil(@job.backtrace)
    end

    test "should set the timer attribute when retrying a task" do
      assert_equal(false, @job.timer)
      assert_nil(@job.retry_at)
      assert_nil(@job.delayed_job_id)

      @job.task = "timer_node"
      @job.boot!
      assert_equal(true, @job.timer)
      assert_not_nil(@job.retry_at)
      assert_not_nil(@job.delayed_job_id)
    end

    test "should set the task and description attributes when falling in human manual task" do
      assert_equal(false, @job.manual_task)
      assert_nil(@job.manual_task_description)

      @job.task = "task_node"
      @job.boot!
      assert_equal(true, @job.manual_task)
      assert_not_nil(@job.manual_task_description)
    end

    test "should disallow transition" do
      assert_equal(true, @job.task?(:start))
      @job.event!(nil, false)
      assert_equal(true, @job.task?(:start))
    end

    test "should allow transition" do
      assert_equal(true, @job.task?(:start))
      @job.event!(nil, true)
      assert_equal(true, @job.task?(:end))
    end

    test "should disallow retry" do
      assert_equal(false, @job.timer)
      assert_nil(@job.retry_at)
      @job.task = "timer_node"

      @job.event!(nil, true, false)
      assert_equal(false, @job.timer)
      assert_nil(@job.retry_at)
      assert_nil(@job.delayed_job_id)
    end

    test "should allow retry" do
      assert_equal(false, @job.timer)
      assert_nil(@job.retry_at)
      @job.task = "timer_node"

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

    test "should have custom task classes" do
      assert_equal(true, @custom_task_job.class.task_classes.key?(:start))
      assert_equal("CustomNode", @custom_task_job.class.task_classes[:start])
      assert_equal(true, @custom_task_job.class.task_classes.key?(:first_node))
      assert_equal("CustomNode", @custom_task_job.class.task_classes[:first_node])
      assert_equal(true, @custom_task_job.class.task_classes.key?(:cancel))
      assert_equal("CustomNode", @custom_task_job.class.task_classes[:cancel])
      assert_equal(true, @custom_task_job.class.task_classes.key?(:end))
      assert_equal("CustomNode", @custom_task_job.class.task_classes[:end])
    end

    test "should use the custom task and raise an error" do
      %w[start end cancel].each do
        @custom_task_job.clear!(nil)
        assert_equal(false, @custom_task_job.error)
        @custom_task_job.boot!
        assert_equal(true, @custom_task_job.error)
        assert_equal("start", @custom_task_job.failed_in)
      end
    end

    test "should not use the custom task when a task method is defined" do
      assert_equal(false, @custom_task_job.error)
      @custom_task_job.task = "first_node"
      @custom_task_job.boot!
      assert_equal(false, @custom_task_job.error)
      assert_equal(true, @custom_task_job.task?(:first_node))
    end
  end
end
