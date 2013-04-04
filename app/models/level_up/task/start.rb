module LevelUp
  class Task::Start < LevelUp::Task
    def run
      job.started_at = DateTime.now.utc
      move_to! job.transitions(:start).first
    end
  end
end