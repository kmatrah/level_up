module LevelUp
  class State::Start < LevelUp::State
    def run
      job.started_at = DateTime.now.utc
      next_state = job.transitions(:start).first
      move_to next_state
    end
  end
end