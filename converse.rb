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

require './converseHelpers'

db_name = 'converse'

db_url = if ENV['CLOUDANT_URL'] then 
    "#{ENV['CLOUDANT_URL']}/#{db_name}"
else 
    "http://127.0.0.1:5984/#{db_name}" 
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

get '/' do
    File.read(File.join('public', 'index.html'))
end

get '/user/:username' do
    username=params[:username]
    user = User.for_username username
    user_not_found if user.nil?
    {
        :username => user.username,
        :displayname => user.displayname
    }.to_json
end
        
put '/user/:username' do 

    check_parameters do
        required_parameter :username
        required_parameter :password
    end

    username=params[:username]
    password=params[:password]
    old_user = User.for_username username
    unless old_user.nil? then
        error 409, 'A user of that name already exists'
    end
    user = User.new
    user.username = username
    user.create_password password
    logger.info "User created: #{username}"
    user.create!
    201
end

# Get the avatar image for a given user
# Optionally, this may be the small version
get %r{/user/([^/]*)/avatar(/small)?} do |username, small|

    user = User.for_username username
    user_not_found if user.nil?

    unless user.has_avatar? then
        if small then
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

    begin
        tmpfile = params[:file][:tempfile]
    rescue NoMethodError
        json_req_error :file_required
    end

    username = session[:username]
    user = User.for_username username
    user_not_found if user.nil?

    max_bytes = 40960
    if tmpfile.size > max_bytes then
        json_req_error :file_too_large, :max_bytes => max_bytes
    end

    max_size = [128, 128]
    imageSize = ImageSize.new(File.new(tmpfile.path))
    if (imageSize.width > max_size[0] || imageSize.height > max_size[1]) then
        json_req_error :image_too_large, :max_size => max_size
    end

    user.avatar = tmpfile
    user.save
end

# A simple idempotent setup route which will create a "main" board
get '/setup' do
    board = Board.for_name 'main'
    halt 200 unless board.nil?
    main = Board.new(
        :name => 'main',
        :title => 'General Discussion',
        :description => 'It\'s all happening here',
        :owners => [],
        :status => :open,
        :groups => [],
        :private => false,
        :moderated => false
    )
    main.save
    redirect to('/board/main')
end

get '/board' do
    redirect '/board/main'
end

get '/board/:board_id' do
    board = Board.for_name params[:board_id]
    if board.nil? then
        if params[:board_id] = 'main' then
            redirect to('/setup')
        else
            board_not_found 
        end
    end

    may_post = false
    if loggedin? then
        user = User.for_username session[:username]
        user_db_error if user.nil?
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
    user_db_error if user.nil?
    error 403 unless user.has_role? :admin
    old_board = Board.for_name params[:board_id]
    unless old_board.nil? then
        error 409, 'A board with that name already exists'
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
    board.save
end

delete '/board/:board_id' do
    
    must_be_loggedin

    user = User.for_username session[:username]
    user_db_error if user.nil?
    error 403 unless user.has_role? :admin
    board = board.for_name params[:board_id]
    board_not_found if board.nil?
    board.destroy unless board.nil?
end

post '/board/:board_id/post' do

    must_be_loggedin

    check_parameters do
        required_parameter :subject, :min_len => 5
        required_parameter :body
    end

    board = Board.for_name params[:board_id]
    board_not_found if board.nil?

    user = User.for_username session[:username]
    user_db_error if user.nil?

    must_have_waited 20, controller.secs_ago_posted(user)

    unless board.user_may_post? user
        error 403, 'You may not post here'
    end

    controller.post(
        :subject => params[:subject], 
        :body => params[:body], 
        :author => session[:username],
        :board => params[:board_id]
    )

    200
end

post '/post/:post_id/reply' do 

    must_be_loggedin

    check_parameters do
        required_parameter :body
    end

    post_id = params[:post_id]
    parent = Post.for_id post_id

    if parent.nil? then
        not_found 'The post to which you are replying does not exists'
    end

    board = Board.for_name parent.board
    board_db_error if board.nil?
    user = User.for_username session[:username]
    user_db_error if user.nil?

    must_have_waited 20, controller.secs_ago_posted(user)

    unless board.user_may_post? user, true
        error 403, 'You may not post here'
    end

    controller.post(
        :subject => params[:subject], 
        :body => params[:body], 
        :author => session[:username],
        :parent => parent
    )
    
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
    error 403 unless user.has_role? :admin

    if yes_or_true? params[:recursive] then
        result = Post.by_ancestor :startkey => [post_id], :endkey => [post_id, {}]
    else
        result = Post.all :key => :post_id
    end

    if result.empty? then
        not_found "The post you wish to delete no longer exists"
    end

    result.each do |post|
        post.destroy
    end

    200
end

#TODO: editing by board moderator
#      version control
post '/post/:post_id' do

    must_be_loggedin

    delete = yes_or_true? params[:delete]

    post = Post.for_id post_id
    not_found "The post you wish to edit no longer exists" if post.nil?

    user = User.for_username session[:username]
    user_db_error if user.nil?
    user_is_author = username? post.author

    unless user_is_author or user.has_role? :admin then
        error 403
    end

    if delete then
        if user_is_author then
            post.body = "[b]This post has been deleted by the author[/b]"
        else
            post.body = "[b]This post has been deleted by an administrator[/b]"
        end
    else
        is_root = post.path.empty?
        check_parameters do
            required_parameter :body
            required_parameter :subject if is_root
        end
        
        post.body = params[:body]
        if is_root then post.subject = params[:subject] end
    end
    post.save
    200
end

#get '/post/:post_id/authors' do
#    #content_type :json
#    post_id=params[:post_id]
#    Post.by_author(:key => post_id, :reduce => true)
#    200
#end

get '/loggedin' do
    username = session[:username]
    content_type :json
    if loggedin? then
        user = User.for_username username
        user_db_error if user.nil?
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
    username = params[:username] or ""
    password = params[:password] or ""
    rememberme = yes_or_true? params[:rememberme]

    user = User.for_username username
    if user.nil? then
        error 403, 'Incorrect username or password'
    end

    if not user.check_password? password then
        error 403, 'Incorrect username or password'
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

require './dbRepair.rb'

get '/dbrepair' do
    content_type 'text/plain'
    db_repair
end
