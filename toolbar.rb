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
