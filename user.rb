# Copyright © 2011, David McIntosh <dmcintosh@df12.net>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

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
