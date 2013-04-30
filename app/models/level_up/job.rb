module LevelUp
  class TaskNotFound < StandardError; end

  class Job < ActiveRecord::Base

    attr_accessible :key, :task, :timer, :manual_task, :manual_task_description, :error,
                    :created_at, :updated_at, :started_at, :ended_at, :canceled_at

    belongs_to :delayed_job, class_name: '::Delayed::Job'

    attr_accessor :next_task

    scope :queued, lambda { where('delayed_job_id is not null') }
    scope :error, lambda { where(error: true) }
    scope :timer, lambda { where(timer: true) }
    scope :manual_task, lambda { where(manual_task: true) }

    serialize :backtrace

    class << self
      def schema
        @schema ||= {}
      end

      def task_classes
        @task_classes ||= {}
      end

      def tasks
        self.schema.keys
      end

      def job(&block)
        if block_given?
          class_eval(&block)
          schema[:end] = []
        end
      end

      def task(name, options = {})
        options.reverse_merge!({transitions: []})
        transitions = options[:transitions].kind_of?(Symbol) ? Array(options[:transitions]) : options[:transitions]
        schema[name] = transitions
        task_classes[name] = options[:class_name] if options.key?(:class_name)
      end

      def transitions(task_name)
        if self.schema.has_key?(task_name)
          self.schema[task_name]
        else
          raise TaskNotFound, task_name
        end
      end
    end

    def boot!
      event!(nil)
    end

    def event!(event_name, allow_transition=true, allow_retry=true)
      event_name = event_name.to_s if event_name
      clear!(event_name)
      step!(event_name, allow_transition, allow_retry)

      if next_task
        event!(next_task, allow_transition, allow_retry)
      elsif retry_at
        retry!
      end
    end

    def retry!
      set_timer
      save
      boot_async!(nil, run_at: retry_at)
    end

    def boot_async!(event_name=nil, options={})
      begin
        Delayed::Job.transaction do
          self.delayed_job = delay(options).event!(event_name)
          save
        end
        true
      rescue
        false
      end
    end

    def unqueue!
      if self.delayed_job
        self.delayed_job.destroy
        self.delayed_job = nil
      end
      clear_timer_attributes
      save
    end

    def task?(name)
      self.task == name.to_s
    end

    def cancellable?
      self.timer? or self.error? or self.delayed_job.nil?
    end

    def queued?
      !self.delayed_job.nil?
    end

    def tasks
      self.class.tasks
    end

    def transitions(task_name)
      self.class.transitions(task_name)
    end

    def task_transitions
      self.transitions(self.task.to_sym)
    end

    def schema
      self.class.schema
    end

    def move_to!(task_name)
      throw :move_to, task_name
    end

    def retry_in!(delay, error=nil)
      throw :retry_in, delay: delay, error: error
    end

    def manual_task!(description)
      throw :manual_task, description
    end

    protected
      def step!(event_name, allow_transition, allow_retry)
        begin
          run_task(event_name, allow_transition, allow_retry)
        rescue => ex
          set_error(ex)
        ensure
          save
        end
      end

      def clear!(event_name)
        clear_timer_attributes
        clear_error_attributes
        clear_task_attributes

        self.next_task = nil
        self.retry_at = nil
        self.task = event_name if event_name
        save
      end

      def run_task(task_name, allow_transition, allow_retry)
        task_name ||= self.task

        if respond_to?(task_name)
          Task.new(self, allow_transition, allow_retry).execute(self, task_name)
        else
          task_class = if self.class.task_classes.key?(task_name.to_sym)
            self.class.task_classes[task_name.to_sym].constantize
          elsif task?(:start)
            Task::Start
          elsif task?(:end)
            Task::End
          elsif task?(:cancel)
            Task::Cancel
          else
            next_task_class(task_name)
          end

          task_instance = task_class.new(self, allow_transition, allow_retry)
          task_instance.execute(task_instance, :run)
        end
      end

      def next_task_class(task_name)
        "#{self.class.name}::#{task_name.camelize}".constantize
      end

      def set_error(error=nil)
        self.error = true
        self.delayed_job = nil
        set_error_details(error) if error
      end

      def set_timer
        self.timer = true
      end

      def set_error_details(error)
        self.failed_at = DateTime.now.utc
        self.failed_in = self.task
        if Configuration.backtrace_size > 0
          self.backtrace = [error.message] | error.backtrace.take(Configuration.backtrace_size - 1)
        end
      end

      def clear_error_attributes
        self.error = false
        self.failed_at = nil
        self.failed_in = nil
        self.backtrace = nil
      end

      def clear_timer_attributes
        self.timer = false
      end

      def clear_task_attributes
        self.manual_task = false
        self.manual_task_description = nil
      end
  end
end