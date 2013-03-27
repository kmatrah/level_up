module LevelUp
  class State::Cancel < LevelUp::State
    def run
      job.canceled_at = DateTime.now.utc
    end
  end
end