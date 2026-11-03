module ApplicationCable
  # As atualizações em tempo real (Turbo Streams) também exigem login.
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = env["warden"]&.user(:user) || reject_unauthorized_connection
    end
  end
end
