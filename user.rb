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
require 'image_size'
require 'fastimage_resize'

class User < CouchRest::ExtendedDocument

    @@avatar_att_name = "avatar"
    @@avatar_s_att_name = "avatar_s"

    property :username
    property :password
    property :roles,            [String]
    property :groups,           [String]
    property :avatar_modified,  Time

    view_by  :username

    unique_id :id_string

    def id_string
        return "user_"+self.username
    end

    def self.for_username(username)
        return by_username(:key => username).first
    end

    def check_password?(password)
        logger = Logger.new(STDERR)
        if self.password.nil? then
            logger.warn "No hash available for user #{self.username}"
            return false
        end
        bPass = BCrypt::Password.new(self.password)
        return bPass == password
    end

    def create_password(password)
        self.password=BCrypt::Password.create(password)
    end

    def displayname
        # Ruby 1.9: self.username.encode :xml => :text 
        CGI.escapeHTML(self.username)
    end

    def avatar=(file)
        if self.has_attachment? @@avatar_att_name then
            self.delete_attachment @@avatar_att_name
        end
        self.create_attachment :file => file, :name => @@avatar_att_name
        self.avatar_s=file
        self.avatar_modified = Time.now
    end

    def avatar_s=(file)

        # Resize the image to a maximum of 48 pixels wide or high
        imageSize = ImageSize.new(File.new(file.path))
        old_w = imageSize.width; old_h = imageSize.height
        if (imageSize.width > imageSize.height) then
            w = 48; h = old_h * ( 48.0 / old_w.to_f )
        else
            w = old_w * ( 48.0 / old_h.to_f ); h = 48
        end
        resized = Tempfile.new @@avatar_s_att_name
        FastImage.resize(file.path, resized.path, w, h)

        # Save the resized attachment, overwriting if one exists
        if self.has_attachment? @@avatar_s_att_name then
            self.delete_attachment @@avatar_s_att_name
        end
        self.create_attachment :file => resized, :name => @@avatar_s_att_name
    end

    def has_avatar?
        self.has_attachment? @@avatar_att_name and
            self.has_attachment? @@avatar_s_att_name
    end

    def avatar
        self.read_attachment @@avatar_att_name
    end

    def avatar_s
        self.read_attachment @@avatar_s_att_name
    end

    def has_role?(role)
        return self.roles.include? role
    end

    def in_group?(val)
        if val.instance_of? Array then
            val.each do |group|
                return true if self.groups.include? group
            end
        end
        return self.groups.include? val
    end

end
