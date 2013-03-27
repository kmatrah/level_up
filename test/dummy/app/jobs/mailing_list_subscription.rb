class MailingListSubscription < LevelUp::Job
  job do
    state :start, moves_to: :mail_server_request
    state :mail_server_request, moves_to: :email_notification
    state :email_notification, moves_to: :end
  end

  def mail_server_request
    move_to :email_notification
  end

  def email_notification
    move_to :end
  end
end
