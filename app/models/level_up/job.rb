module LevelUp
  class StateNotFound < StandardError; end

  class Job < ActiveRecord::Base

    attr_accessible :key, :state, :timer, :task, :error, :created_at, :updated_at, :started_at, :ended_at, :canceled_at
    belongs_to :delayed_job, class_name: "::Delayed::Job"

    attr_accessor :next_state

    scope :queued, lambda { where("delayed_job_id is not null") }
    scope :error, lambda { where(error: true) }
    scope :timer, lambda { where(timer: true) }
    scope :task, lambda { where(task: true) }

    serialize :backtrace

    class << self
      def schema
        @schema ||= {}
      end

      def state_classes
        @state_classes ||= {}
      end

      def states
        self.schema.keys
      end

      def job(&block)
        if block_given?
          class_eval(&block)
          schema[:end] = []
        end
      end

      def state(name, options = {})
        options.reverse_merge!({moves_to: []})
        transitions = options[:moves_to].kind_of?(Symbol) ? Array(options[:moves_to]) : options[:moves_to]
        schema[name] = transitions
        state_classes[name] = options[:class_name] if options.key?(:class_name)
      end

      def transitions(state)
        if self.schema.has_key?(state)
          self.schema[state]
        else
          raise StateNotFound, state
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

      if next_state
        event!(next_state, allow_transition, allow_retry)
      elsif retry_at
        retry!
      end
    end

    def clear!(event_name)
      clear_timer_attributes
      clear_error_attributes
      clear_task_attributes

      self.next_state = nil
      self.retry_at = nil
      self.state = event_name if event_name
      save
    end

    def step!(event_name, allow_transition, allow_retry)
      begin
        run_state(event_name, allow_transition, allow_retry)
      rescue => ex
        set_error(ex)
      ensure
        save
      end
    end

    def retry!
      set_timer
      save
      boot_async!(nil, run_at: retry_at)
    end

    def boot_async!(event_name = nil, options = {})
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

    def state?(name)
      self.state == name.to_s
    end

    def cancellable?
      self.timer? or self.error? or self.delayed_job.nil?
    end

    def queued?
      !self.delayed_job.nil?
    end

    def states
      self.class.states
    end

    def transitions(state)
      self.class.transitions(state)
    end

    def state_transitions
      self.transitions(self.state.to_sym)
    end

    def schema
      self.class.schema
    end

    def move_to(state_name)
      throw :move_to, state_name
    end

    def retry_in(delay, error=nil)
      throw :retry_in, delay: delay, error: error
    end

    def manual_task(description)
      throw :task, description
    end

    protected
      def run_state(state_name, allow_transition, allow_retry)
        state_name ||= state

        if respond_to?(state_name)
          State.new(self, allow_transition, allow_retry).execute(self, state_name)
        else
          state_class = if self.class.state_classes.key?(state_name.to_sym)
            self.class.state_classes[state_name.to_sym].constantize
          elsif state?(:start)
            State::Start
          elsif state?(:end)
            State::End
          elsif state?(:cancel)
            State::Cancel
          else
            next_state_class(state_name)
          end
          state = state_class.new(self, allow_transition, allow_retry)
          state.execute(state, :run)
        end
      end

      def current_state_class
        "#{self.class.name}::#{state.camelize}".constantize
      end

      def next_state_class(state_name)
        "#{self.class.name}::#{state_name.camelize}".constantize
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
        self.failed_in = state
        self.backtrace = [error.message] | error.backtrace.take(5)
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
        self.task = false
        self.task_description = nil
      end
  end
end