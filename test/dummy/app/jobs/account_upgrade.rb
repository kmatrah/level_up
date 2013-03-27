class AccountUpgrade < LevelUp::Job
  job do
    state :start, moves_to: :upgrade
    state :upgrade, moves_to: :email_notification
    state :email_notification, moves_to: :end
  end

  def upgrade
    move_to :email_notification
  end

  def email_notification
    move_to :end
  end
end
