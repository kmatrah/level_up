class AccountDowngrade < LevelUp::Job
  job do
    state :start, moves_to: :account_validation
    state :account_validation, moves_to: [:account_update, :service_delete]
    state :account_update, moves_to: [:service_delete, :mail_suspension]
    state :mail_suspension, moves_to: :service_update
    state :service_update, moves_to: :waiting_renewal
    state :waiting_renewal, moves_to: [:manual_deletion, :mail_activation]
    state :manual_deletion, moves_to: :account_update
    state :service_delete, moves_to: :mail_activation
    state :mail_activation, moves_to: :end
  end
end
