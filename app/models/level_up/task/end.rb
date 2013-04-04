module LevelUp
  class Task::End < LevelUp::Task
    def run
      job.ended_at = DateTime.now.utc
    end
  end
end