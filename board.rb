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
require './user'

class Board < CouchRest::ExtendedDocument

    property :name
    property :title
    property :description
    property :owners,       [String]
        # A list of users who may moderate 
    property :mod_groups,   [String]
        # Additional groups who may moderate
    property :status
        # One of the following:
        #   'locked' - only the owner or admin may post (assumed if null)
        #   'limited' - only members of #groups may post
        #   'tiered' - only members of #groups may start new threads. 
        #       All may reply
        #   'open' - all may post
    property :groups,       [String]
    property :private
        # Only viewable by members of :groups and admin
    property :moderated
        # If #status is:
        #   'locked' - all posts require moderation
        #   'limited' - non-members of #groups always require moderation
        #   'tiered' - non-members of #groups require moderation when 
        #       starting threads
        #   'open' - no effect - client should disable this option

    view_by  :name

    unique_id :id_string

    def id_string
        return "board_"+self.name
    end

    def self.for_name(name)
        return by_name(:key => name).first
    end

    def self.permitted_status(status)
        permitted = ['locked', 'limited', 'tiered', 'open']
        return permitted.include? status
    end

    def user_may_post?(user, reply=false)
        return true if user.has_role? :admin
        return true if self.owners.include? user.username 
        return true if user.in_group? self.mod_groups
        case self.status
            when 'locked'
                return false
            when 'limited'
                return user.in_group? self.groups
            when 'tiered'
                return (reply or user.in_group? self.groups)
            else
                return true
        end
    end

end
