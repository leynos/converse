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

require 'rubygems'
require 'logger'
require 'sinatra'
require 'json'
require 'mimemagic'
require 'image_size'

require './user'
require './post'
require './board'
require './postController'

db_url = if ENV['CLOUDANT_URL'] then 
    "#{ENV['CLOUDANT_URL']}/converse"
else 
    'http://127.0.0.1:5984/converse' 
end

DB = CouchRest.database!(db_url)
CouchRest::Document::use_database DB

Post.save_design_doc!
User.save_design_doc!
Board.save_design_doc!

controller = PostController.new()
logger = Logger.new(STDERR)

logger.info "\033]0;Sinatra (Converse)\007"

enable :sessions

helpers do
    def user_not_found_e(msg='The specified user does not exist') error 404, msg end
    def user_db_e(msg='Error retrieving user from database') error 500, msg end
    def board_db_e(msg='Error retrieving board from database') error 500, msg end
    def board_not_found_e(msg='The specified board does not exist') error 404, msg end
    def loggedin?() session[:loggedin] end
    def must_be_loggedin() 
        if not loggedin? then error 403, 'You are not logged in' end
    end
    def username?(u) session[:username]==u end
    def yes_or_true?(v) not v.nil? and ((v.casecmp 'yes')==0 or (v.casecmp 'true')==0) end
    def request_headers
        env.inject({}){|acc, (k,v)| acc[$1.downcase] = v if k =~ /^http_(.*)/i; acc}
    end
end

get '/' do
    File.read(File.join('public', 'index.html'))
end

get '/user/:username' do
    username=params[:username]
    user = User.for_username username
    user_not_found_e if user.nil?
    {
        :username => user.username,
        :displayname => user.displayname
    }.to_json
end
        
put '/user/:username' do 
    username=params[:username]
    password=params[:password]
    old_user = User.for_username username
    unless old_user.nil? then
        return [409, 'A user of that name already exists']
    end
    user = User.new
    user.username = username
    user.create_password password
    logger.info "User created: #{username}"
    user.create!
    201
end

get %r{/user/([^/]*)/avatar(/small)?} do |username, small|

    user = User.for_username username
    user_not_found_e if user.nil?

    logger.info request_headers.inspect

    unless user.has_avatar? then
        if small
            redirect '/images/no_avatar_s.png'
        else
            redirect '/images/no_avatar.png'
        end
        return
    end

    if small then
        avatar = user.avatar_s
    else
        avatar = user.avatar
    end

    if user.avatar_modified.nil? then
        last_modified Time.utc(1970, 1, 1)
    else
        last_modified user.avatar_modified
    end

    avatarIO = StringIO.new avatar
    mime = MimeMagic.by_magic avatarIO
    content_type mime.type
    avatar
end

# Upload a new avatar for the currently logged in user
post '/avatar' do

    must_be_loggedin

    unless params[:file] && (tmpfile = params[:file][:tempfile]) then
        return [400, 'A file must be supplied with this request']
    end

    username = session[:username]
    user = User.for_username username
    user_not_found_e if user.nil?

    max_size = [128, 128]
    imageSize = ImageSize.new(File.new(tmpfile.path))
    if (imageSize.width > max_size[0] || imageSize.height > max_size[1]) then
        return [400, {
            :error => :image_too_large,
            :max_size => max_size
        }.to_json]
    end

    max_bytes = 40960
    if tmpfile.size > max_bytes then
        return [400, {
            :error => :file_too_large,
            :max_bytes => max_bytes
        }.to_json]
    end

    user.avatar = tmpfile
    user.save!
end

get '/board' do
    redirect '/board/main'
end

get '/board/:board_id' do
    board = Board.for_name params[:board_id]
    board_not_found_e if board.nil?

    may_post = false
    if loggedin? then
        user = User.for_username session[:username]
        user_db_e if user.nil?
        may_post = board.user_may_post? user
    end

    threads = controller.threads params[:board_id]

    content_type :json
    {
        :title => board.title,
        :description => board.description,
        :may_post => may_post,
        :threads => threads
    }.to_json
end

put '/board/:board_id' do
    
    must_be_loggedin

    user = User.for_username session[:username]
    user_db_e if user.nil?
    return 403 unless user.has_role? :admin
    old_board = Board.for_name params[:board_id]
    unless old_board.nil? then
        return [409, 'A board with that name already exists']
    end

    board = Board.new(
        :name => params[:board_id],
        :title => params[:title],
        :description => params[:description],
        :owners => [user.username],
        :status => 
            if Board.permitted_status? params[:status] then 
                params[:status] 
            else 
                :open 
            end,
        :groups => [],
        :private => params[:private]?true:false,
        :moderated => params[:moderated]?true:false
    )
    board.save!

end

delete '/board/:board_id' do
    
    must_be_loggedin

    user = User.for_username session[:username]
    user_db_e if user.nil?
    return 403 unless user.has_role? :admin
    board = board.for_name params[:board_id]
    board_not_found_e if board.nil?
    board.destroy unless board.nil?
end

post '/board/:board_id/post' do

    must_be_loggedin

    board = Board.for_name params[:board_id]
    board_not_found_e if board.nil?

    user = User.for_username session[:username]
    user_db_e if user.nil?
    unless board.user_may_post? user
        return 403
    end

    post = Post.new(
        :subject => params[:subject], 
        :body => params[:body], 
        :author => session[:username],
        :board => params[:board_id],
        :date => Time.now
    )
    post.save!
end

post '/post/:post_id/reply' do 

    must_be_loggedin

    post_id = params[:post_id]
    parent = Post.for_id post_id

    if parent.nil? then
        return [404, 'The post to which you are replying does not exists']
    end

    board = Board.for_name parent.board
    board_db_e if board.nil?
    user = User.for_username session[:username]
    user_db_e if user.nil?

    unless board.user_may_post? user
        return 403
    end

    post = Post.new(
        :subject => params[:subject], 
        :body => params[:body], 
        :author => session[:username],
        :board => parent.board,
        :date => Time.now
    )
    post.set_parent(parent)
    post.create!
    
    200
end

get '/post/:post_id' do
    content_type :json
    post_id = params[:post_id]

    {
        :posts => controller.posts_for_id(post_id),
        :users => controller.users_for_id(post_id)
    }.to_json
end

delete '/post/:post_id' do

    must_be_loggedin

#    if yes_or_true? params[:recursive] then
#        result = Post.by_ancestor :startkey => [post_id], :endkey => [post_id, {}]
#    else
#        result = Post.all :key => :post_id
#    end
#
#    if result.empty? then
#        return [404, "The post you wish to delete no longer exists"]
#    end
#
#    result.each do |post|
#        post.destroy
#    end

    200
end

get '/post/:post_id/authors' do
    #content_type :json
    post_id=params[:post_id]
    Post.by_author(:key => post_id, :reduce => true)
    200
end

get '/loggedin' do
    username = session[:username]
    content_type :json
    if loggedin? then
        user = User.for_username username
        user_db_e if user.nil?
        {
            :loggedin => true,
            :username => username,
            # These are placeholder rights until this is supported
            :rights => user.roles
        }.to_json
    else
        {   
            :loggedin => false,
            :username => nil,
            # These are placeholder rights until this is supported
            :rights => [],
        }.to_json
    end
end

post '/login' do
    username = params[:username]
    password = params[:password]
    rememberme = yes_or_true? params[:rememberme]

    user = User.for_username username
    if user.nil? then
        return [403, 'Incorrect username or password']
    end

    if not user.check_password? password then
        return [403, 'Incorrect username or password']
    end

    session[:username] = username
    session[:loggedin] = true
    content_type :json
    {
        :loggedin => true,
        :username => username,
        # These are placeholder rights until this is supported
        :rights => [:post, :reply, :manage_users],
    }.to_json
end

post '/logout' do
    session[:username] = nil
    session[:loggedin] = false
    content_type :json
    {
        :loggedin => false,
        :username => nil,
        # These are placeholder rights until this is supported
        :rights => [:manage_users],
    }.to_json
end
