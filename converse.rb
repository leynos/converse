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

get '/' do
  File.read(File.join('public', 'index.html'))
end

get '/user/:username' do
    username=params[:username]
    result = User.by_username(:key => username)
    if result.empty? then
        [404, 'No user by that name here']
    else
        user = result.first
        {
            :username => user.username,
            :displayname => user.displayname
        }.to_json
    end
end
        
put '/user/:username' do 

    username=params[:username]
    password=params[:password]
    result = User.by_username(:key => username)
    if not result.empty? then
        break [409, 'A user of that name already exists']
    end
    user = User.new
    user.username = username
    user.createPassword password
    logger.info "User created: #{username}, #{password}"
    user.create!
    201
end

get '/user/:username/avatar' do
    username = params[:username]
    result = User.by_username(:key => username)
    if result.empty? then
        break [404, 'The specified user does not exists']
    end
    user = result.first
    attName = "avatar"
    if not user.has_attachment? attName
        break [404, 'The specified user has no avatar']
    end
    avatar = user.read_attachment attName
    avatarIO = StringIO.new avatar
    mime = MimeMagic.by_magic avatarIO
    content_type mime.type
    avatar
end

post '/avatar' do
    unless session[:loggedin] then
        break [403, 'You must be logged in to upload an avatar']
    end

    unless params[:file] && (tmpfile = params[:file][:tempfile]) then
        break [400, 'A file must be supplied with this request']
    end

    username = session[:username]
    result = User.by_username(:key => username)
    if result.empty? then
        break [404, 'The specified user does not exists']
    end

    user = result.first
    attName = "avatar"
    imageSize = ImageSize.new(File.new(tmpfile.path))
    if (imageSize.width > 128 || imageSize.height > 128) then
        break [400, {
            :error => :image_too_large,
            :max_size => [128, 128]
        }.to_json]
    end

    if tmpfile.size > 20480 then
        break [400, {
            :error => :file_too_large,
            :max_bytes => 20480
        }.to_json]
    end

    if user.has_attachment? attName then
        user.delete_attachment attName
    end

    user.create_attachment :file => tmpfile, :name => attName
    user.save!
end

get '/threads' do
    content_type :json
    result = Post.by_thread
    result.to_json
end

get '/board' do
    redirect '/board/default'
end

get '/board/:board_id' do
    result = Post.by_thread

    posts = []
    result.each do |post|
        tmpPost = {}
        tmpPost[:subject] = post.subject
        tmpPost[:date] = post.date
        tmpPost[:author] = post.author
        posts.push tmpPost
    end
    content_type :json
    posts.to_json
end

post '/post/:post_id/reply' do 

    unless session[:loggedin] then
        break [403, 'You are not logged in']
    end

    post_id = params[:post_id]
    result = Post.all :key => post_id

    logger.info result.to_json

    if result.empty? then
        break [404, 'The post to which you are replying does not exists']
    end

    parent = result.first
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

    unless session[:loggedin] then
        break [403, 'You are not logged in']
    end

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
    if params[:recursive] == "yes" or params[:recursive] == "true" then
        result = Post.by_ancestor :startkey => [post_id], :endkey => [post_id, {}]
    else
        result = Post.all :key => :post_id
    end
    if result.empty? then
        break [404, "The post you wish to delete no longer exists"]
    end
    result.each do |post|
        post.destroy
    end
    200
end

get '/post/:post_id/authors' do
    #content_type :json
    post_id=params[:post_id]
    Post.by_author(:key => post_id, :reduce => true)
    200
end


get '/toolbar' do
    Toolbar.new(session[:loggedin], session[:username]).to_html
end

get '/loggedin' do
    loggedin = session[:loggedin]
    username = session[:username]
    if (loggedin) then
        result = User.by_username :key => username
        if result.empty? then
            break [500, "Could not retrieve user details from database"]
        end
        content_type :json
        {
            :loggedin => true,
            :username => username,
            # These are placeholder rights until this is supported
            :rights => [:post, :reply, :manage_users],
        }.to_json
    else
        content_type :json
        {   
            :loggedin => false,
            :username => nil,
            :rights => [:manage_users],
        }.to_json
    end
end

post '/login' do
    username=params[:username]
    password=params[:password]
    rememberme=params[:rememberme]

    result = User.by_username(:key => username)
    if result.empty? then
        break 403
    end

    user = result.first
    if user.checkPassword? password then
        session[:username]=username
        session[:loggedin]=true
        content_type :json
        {
            :loggedin => true,
            :username => username,
            # These are placeholder rights until this is supported
            :rights => [:post, :reply, :manage_users],
        }.to_json
        
    else
        403
    end
end

post '/logout' do
    session[:username]=nil
    session[:loggedin]=false
    content_type :json
    {
        :loggedin => false,
        :username => nil,
        # These are placeholder rights until this is supported
        :rights => [:manage_users],
    }.to_json
end
