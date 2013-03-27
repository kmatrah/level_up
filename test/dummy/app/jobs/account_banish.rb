class AccountBanish < LevelUp::Job
  job do
    state :start, moves_to: :banish
    state :banish, moves_to: [:check_account, :email_notification]
    state :check_account, moves_to: [:banish, :report]
    state :report, moves_to: :end
    state :email_notification, moves_to: :end
  end


  def banish
    move_to :email_notification
  end

  def email_notification
    move_to :end
  end
end
