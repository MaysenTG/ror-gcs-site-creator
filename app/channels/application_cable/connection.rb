module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_account

    def connect
      self.current_account = find_verified_account
    end

    private

    def find_verified_account
      account = env["warden"]&.user(:account)
      return account if account

      reject_unauthorized_connection
    end
  end
end
