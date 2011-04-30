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

controller = PostController.new()
logger = Logger.new(STDERR)

logger.info "\033]0;Sinatra (Converse)\007"

enable :sessions

helpers do
    def not_loggedin_e(msg='You are not logged in') [403, msg] end
    def loggedin?() session[:loggedin] end
    def username?(u) session[:username]==u end
    def yes_or_true?(v) v=='yes' or v=='true' end
end

get '/' do
    File.read(File.join('public', 'index.html'))
end

get '/user/:username' do
    username=params[:username]
    user = User.for_username username
    if user.nil? then
        return [404, 'No user by that name here']
    end
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
    logger.info "User created: #{username}, #{password}"
    user.create!
    201
end

get %r{/user/([^/]*)/avatar(/small)?} do |username, small|

    user = User.for_username username
    if user.nil? then
        break [404, 'The specified user does not exists']
    end

    unless user.has_avatar? then
        if small
            redirect '/images/no_avatar_s.png'
        else
            redirect '/images/no_avatar.png'
        end
        break
    end

    if small then
        avatar = user.avatar_s
    else
        avatar = user.avatar
    end

    avatarIO = StringIO.new avatar
    mime = MimeMagic.by_magic avatarIO
    content_type mime.type
    avatar
end

# Upload a new avatar for the currently logged in used
post '/avatar' do

    return not_loggedin_e unless loggedin?

    unless params[:file] && (tmpfile = params[:file][:tempfile]) then
        break [400, 'A file must be supplied with this request']
    end

    username = session[:username]
    user = User.for_username username
    if user.nil? then
        break [404, 'The specified user does not exists']
    end

    max_size = [128, 128]
    imageSize = ImageSize.new(File.new(tmpfile.path))
    if (imageSize.width > max_size[0] || imageSize.height > max_size[1]) then
        break [400, {
            :error => :image_too_large,
            :max_size => max_size
        }.to_json]
    end

    max_bytes = 40960
    if tmpfile.size > max_bytes then
        break [400, {
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
    threads = controller.threads params[:board_id]
    return 404 if threads.nil?
    content_type :json
    {
        :threads => threads
    }.to_json
end

post '/post/:post_id/reply' do 

    return not_loggedin_e unless loggedin?

    post_id = params[:post_id]
    parent = Post.for_id post_id

    if parent.nil? then
        break [404, 'The post to which you are replying does not exists']
    end

    post = Post.new(
        :subject => params[:subject], 
        :body => params[:body], 
        :author => session[:username],
        :date => Time.now
    )
    post.setParent(parent)
    post.create!
    
    200
end

post '/post' do 

    return not_loggedin_e unless loggedin?

    post = Post.new(
        :subject => params[:subject], 
        :body => params[:body], 
        :author => session[:username],
        :date => Time.now)
    post.create!
    
    200
end

get '/post/:post_id' do
    content_type :json
    post_id = params[:post_id]

    {
        :posts => controller.postsForId(post_id),
        :users => controller.usersForId(post_id)
    }.to_json
end

delete '/post/:post_id' do

    return not_loggedin_e unless loggedin?
#
#    if yes_or_true? params[:recursive] then
#        result = Post.by_ancestor :startkey => [post_id], :endkey => [post_id, {}]
#    else
#        result = Post.all :key => :post_id
#    end
#
#    if result.empty? then
#        break [404, "The post you wish to delete no longer exists"]
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
        if user.nil? then
            return [500, "Could not retrieve user details from database"]
        end

        {
            :loggedin => true,
            :username => username,
            # These are placeholder rights until this is supported
            :rights => [:post, :reply, :manage_users],
        }.to_json
    else
        {   
            :loggedin => false,
            :username => nil,
            # These are placeholder rights until this is supported
            :rights => [:manage_users],
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
