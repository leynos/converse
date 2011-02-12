require 'couchrest_extended_document'

class User < CouchRest::ExtendedDocument

    property :username
    property :password
    property :displayname
    property :role
    property :rights

    view_by  :username

    def login(username, password)
        # bPass = Password.new(self.password);
    end

end
