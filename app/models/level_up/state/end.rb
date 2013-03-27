module LevelUp
  class State::End < LevelUp::State
    def run
      job.ended_at = DateTime.now.utc
    end
  end
end