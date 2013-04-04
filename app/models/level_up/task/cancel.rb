module LevelUp
  class Task::Cancel < LevelUp::Task
    def run
      job.canceled_at = DateTime.now.utc
    end
  end
end