require 'rubygems'
require 'logger'
require 'sinatra'
require 'json'
require 'erector'

class PostController

    def initialize
        
        @posts = {
            4  => { :author => 1, :date => Time.utc(2008, 7, 8, 9, 10),
                :path => [],
                :body => "DoDonPachi is the greatest STG of all time" },
            5  => { :author => 2, :date => Time.utc(2008, 7, 8, 9, 12), 
                :path => [4],
                :body => "No way dude, danmaku sucks" },
            51 => { :author => 3, :date => Time.utc(2008, 7, 8, 9, 13), 
                :path => [4, 5],
                :body => "Yer ma sucks" },
            52 => { :author => 4, :date => Time.utc(2008, 7, 8, 9, 15), 
                :path => [4, 5],
                :body => "I respectfully disagree" },
            6  => { :author => 5, :date => Time.utc(2008, 7, 8, 9, 13), 
                :path => [4],
                :body => "Possibly, but it owes a lot to Batsugun" },
            61 => { :author => 1, :date => Time.utc(2008, 7, 8, 9, 16), 
                :path => [4, 6],
                :body => "Indeed, Toaplan is the grandaddy" },
            62 => { :author => 4, :date => Time.utc(2008, 7, 8, 9, 18), 
                :path => [4, 6],
                :body => "That may be so, but it takes the genre and makes it its own" },
            63 => { :author => 2, :date => Time.utc(2008, 7, 8, 9, 20), 
                :path => [4, 6],
                :body => "Batsugun is superior to DDP in every way shape and form" },
            7  => { :author => 3, :date => Time.utc(2008, 7, 8, 9, 16), 
                :path => [4],
                :body => "The prequel, DonPachi, is a more balanced game I think" },
            71 => { :author => 1, :date => Time.utc(2008, 7, 8, 9, 21), 
                :path => [4, 7],
                :body => "More balanced maybe, but it didn't redefine shooting like DDP did" }
        }

        @users = {
            1 => { :name => "Aldynes",   :avatar => "default.jpg" },
            2 => { :name => "Wesker",    :avatar => "default.png" },
            3 => { :name => "Yoshi",     :avatar => "default.jpg" },
            4 => { :name => "Near Dark", :avatar => "default.jpg" },
            5 => { :name => "Mr. Do!",   :avatar => "default.jpg" }
        }

    end

    def message
        post_id = params[:id]
        post = postForId(post_id)
        render :json => { 
            :post => post
        }
    end

    def usersForId(root_id)
        return @users
    end

    def postsForId(root_id)
        thread = @posts # Next time, fetch the thread from the database hahah
        tmpHash = {}
        thread.each do |(post_id, post)|
            tmpPost=tmpHash[post_id]
            tmpHash[post_id] = {
                :id => post_id,
                :date => post[:date],
                :author => post[:author],
                :body => post[:body], # tune database query to exclude body where not yet needed
                :prnt => post[:path].last
            }
            if tmpPost then
                tmpHash[post_id][:children] = tmpPost[:children]
            else
                tmpHash[post_id][:children] = []
            end
            if post[:path].length > 0 then
                parent_id = post[:path].last
                if !(tmpHash[parent_id]) then
                    tmpHash[parent_id] = {
                        :children => []
                    }
                end
            
                # logger.info "Pushing post #{post_id} #{parent_id}"
                tmpHash[parent_id][:children].push(post_id)
                # logger.info "Pushing root #{post_id}"
            end
        end
        return tmpHash.values.sort do |a, b|
            a[:date] <=> b[:date]
        end
    end
                    
    def postForId(post_id)

        post = @posts[post_id.to_i]
        if post then
            return { :id => post_id, :body => post[:body], :author => post[:author], :date => post[:date] }
        else 
            return nil;
        end
    end

end

controller = PostController.new()
logger = Logger.new(STDERR)

# set :public, File.dirname(__FILE__) + '/static'
enable :sessions

get '/post/:id' do
    content_type :json
    post_id = params[:id].to_i
    {
        :posts => controller.postsForId(post_id),
        :users => controller.usersForId(post_id)
    }.to_json
end

get '/' do
  File.read(File.join('public', 'index.html'))
end

# require 'bcrypt'
require 'couchrest_extended_document'
require './user'

db_url = if ENV['CLOUDANT_URL'] then 
    ENV['CLOUDANT_URL'] 
else 
    'http://127.0.0.1:5984/converse' 
end

DB = CouchRest.database(db_url)
CouchRest::Document::use_database DB

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
        
put '/user/:username' do # yes yes I know
    content_type :json
    username=params[:username]
    result = User.by_username(:key => username)
    if result.length==0 then
        user = User.new
        user.username = username
        user.create!
        201
    else
        [409, ['username'].to_json]
    end
end

class Toolbar < Erector::Widget
    def content
        div :class => 'toolbar-button', :id => 'logout' do
            img :src => 'images/logout.png'
            br
            span 'Log Out', :class => 'caption'
        end
        div :class => 'toolbar-button', :id => 'adduser' do
            img :src => 'images/adduser.png'
            br
            span 'Add User', :class => 'caption'
        end
    end
end

get '/toolbar' do
    Toolbar.new.to_html
end
