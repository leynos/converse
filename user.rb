require 'couchrest_extended_document'
require 'bcrypt'
require 'cgi'
require 'logger'

class User < CouchRest::ExtendedDocument

    property :username
    property :password
    property :role
    property :rights

    view_by  :username

    unique_id :idString

    def idString
        return "user_"+self.username
    end

    def checkPassword?(password)
        logger = Logger.new(STDERR)
        if self.password.nil? then
            logger.warn "No hash available for user #{self.username}"
            return false
        end
        bPass = BCrypt::Password.new(self.password)
        return bPass == password
    end

    def createPassword(password)
        self.password=BCrypt::Password.create(password)
    end

    def displayname
        # Ruby 1.9: self.username.encode :xml => :text 
        CGI.escapeHTML(self.username)
    end

end
