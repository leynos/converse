require 'rubygems'
require 'logger'
require 'sinatra'
require 'json'
require 'erector'

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

enable :sessions

get '/loggedin' do
    content_type :json
    {
        :loggedin => session[:loggedin]
    }.to_json
end

get '/' do
  File.read(File.join('public', 'index.html'))
end

get '/user/:username' do
    username=params[:username]
    result = User.by_username(:key => username)
    if result.empty? then
        [404, 'No user by that name here']
    else
        user = result[0];
        {
            :username => user.username,
            :displayname => user.displayname
        }.to_json
    end
end
        
put '/user/:username' do 
    content_type :json
    username=params[:username]
    password=params[:password]
    result = User.by_username(:key => username)
    if result.empty? then
        user = User.new
        user.username = username
        user.createPassword password
        logger.info "User created: #{username}, #{password}"
        user.create!
        201
    else
        [409, ['username'].to_json]
    end
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

    parent = result[0]
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

get '/toolbar' do
    Toolbar.new(session[:loggedin], session[:username]).to_html
end

post '/login' do
    username=params[:username]
    password=params[:password]
    rememberme=params[:rememberme]

    result = User.by_username(:key => username)
    if result.empty? then
        break 403
    end

    user = result[0]
    if user.checkPassword? password then
        session[:username]=username
        session[:loggedin]=true
        200
    else
        403
    end
end

post '/logout' do
    session[:username]=nil
    session[:loggedin]=false
end
