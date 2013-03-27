module LevelUp
  class State

    attr_accessor :job, :allow_transition, :allow_retry

    def initialize(job, allow_transition, allow_retry)
      self.job = job
      self.allow_transition = allow_transition
      self.allow_retry = allow_retry
    end

    def execute(receiver, method_name)
      next_state = retry_params = task_description = nil
      ActiveRecord::Base.transaction do
        next_state = catch(:move_to) do
          retry_params = catch(:retry_in) do
            task_description = catch(:task) do
              receiver.send(method_name)
              nil
            end
            nil
          end
          nil
        end
      end

      if self.allow_transition
        self.job.next_state = next_state
      end

      if retry_params and self.allow_retry
        self.job.retry_at = retry_params[:delay].from_now
      end

      if task_description
        self.job.task = true
        self.job.task_description = task_description
      end
    end

    def move_to(state_name)
      self.job.move_to(state_name)
    end

    def retry_in(delay, error=nil)
      self.job.retry_in(delay, error)
    end

    def manual_task(description)
      self.job.manual_task(description)
    end
  end
end