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

get '/post/:id' do
    content_type :json
    post_id = params[:id]

    {
        :posts => controller.postsForId(post_id),
        :users => controller.usersForId(post_id)
    }.to_json
end

get '/' do
  File.read(File.join('public', 'index.html'))
end

get '/user/:username' do
    username=params[:username]
    result = User.by_username(:key => username)
    if result.length==0 then
        [404, 'No user by that name here']
    else
        user = result[0];
        {
            :username => user.username,
            :displayname => user.displayname,
        }.to_json
    end
end
        
put '/user/:username' do 
    content_type :json
    username=params[:username]
    password=params[:password]
    result = User.by_username(:key => username)
    if result.length==0 then
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

post '/post/:id/reply' do 

    unless session[:loggedin] then
        break [403, 'You are not logged in']
    end

    parent = Post.find(id)

    unless parent.nil? then
        break [404, 'The post to which you are replying does not exists']
    end

    post = post.new(
        :subject => params[:subject], 
        :body => params[:body], 
        :author => session[:username])
    post.setParent(parent)
    post.create!
    
    201
end

post '/post' do 

    unless session[:loggedin] then
        break [403, 'You are not logged in']
    end

    post = post.new(
        :subject => params[:subject], 
        :body => params[:body], 
        :author => session[:username])
    post.create!
    
    201
end

get '/post/:postid/authors' do
    #content_type :json
    postid=params[:postid]
    Post.by_author(:key => postid, :reduce => true)
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
            span 'Add User', :class => 'caption'
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
    if result.length == 0 then
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
