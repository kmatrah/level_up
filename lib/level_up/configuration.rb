module LevelUp
  class Configuration
    def self.http_authentication
      @http_authentication ||= false
    end

    def self.http_authentication=(bool)
      @http_authentication = bool
    end

    def self.http_login
      @http_login ||= 'admin'
    end

    def self.http_login=(login)
      @http_login = login
    end

    def self.http_password
      @http_password ||= 'password'
    end

    def self.http_password=(password)
      @http_password = password
    end
  end
end
