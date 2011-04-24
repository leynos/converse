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

# ##
# Note that this file is no longer needed

require 'erector'

class Toolbar < Erector::Widget

    def initialize(loggedin, username)
        @loggedin=loggedin
        @username=username
    end

    def content
        if @loggedin then
            div :class => 'toolbar-button' do
                span @username, :class => 'caption'
            end
            div :class => 'toolbar-button', :id => 'logout' do
                img :src => 'images/logout.png'
                br
                span 'Log Out', :class => 'caption'
            end
        else
            div :class => 'toolbar-button', :id => 'login' do
                img :src => 'images/login.png'
                br
                span 'Log In', :class => 'caption'
            end
        end
        div :class => 'toolbar-button', :id => 'adduser' do
            img :src => 'images/adduser.png'
            br
            span 'Create User', :class => 'caption'
        end
    end
end
