module LevelUp
  class Configuration
    DEFAULT_HTTP_LOGIN = 'admin'
    DEFAULT_HTTP_PASSWORD = 'password'

    def self.http_authentication
      @http_authentication ||= false
    end

    def self.http_authentication=(bool)
      @http_authentication = bool
    end

    def self.http_login
      @http_login ||= DEFAULT_HTTP_LOGIN
    end

    def self.http_login=(login)
      @http_login = login
    end

    def self.http_password
      @http_password ||= DEFAULT_HTTP_PASSWORD
    end

    def self.http_password=(password)
      @http_password = password
    end
  end
end
