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

require  './post.rb'
require  './user.rb'

class PostController

    @@logger = Logger.new(STDERR)

    def initialize
        @user_last_posted = {}
    end

    def users_for_id(root_id)
        result = Post.by_first_ancestor :key => root_id, :reduce => true
        if result['rows'].nil? or result['rows'].count == 0 or 
           result['rows'][0]['value'].nil? then
            return []
        end
        names = result['rows'][0]['value']

        usersHash = {};
        result = User.by_username :keys => names
        result.each do |user|
            hist= Post.post_history_for_user user
            usersHash[user.username] = {
                :username => user.username,
                :joined => user.joined,
                :post_count => hist[0],
                :last_posted => hist[1]
            }
        end
        return usersHash
    end

    def posts_for_id(root_id)
        result = Post.by_ancestor :startkey => [root_id], :endkey => [root_id, {}]
        add_parents_and_children(result)
    end

    def add_parents_and_children(result)

        tmpHash = {}
        result.each do |post|

            post_id=post.id

            # Store the post hash currently in the temp hash
            tmpPost=tmpHash[post_id]

            # Record the values from the current post from the db
            tmpHash[post_id] = {
                :id => post_id,
                :date => post.date,
                :author => post.author,
                :body => post.body,
                :prnt => post.path.last
            }

            # If tmpPost existed, then use its child list else create a new child list
            if tmpPost then
                tmpHash[post_id][:children] = tmpPost[:children]
            else
                tmpHash[post_id][:children] = []
            end

            # If the post is a reply
            unless post[:path].empty? then
                parent_id = post[:path].last

                # If necessary, create a dummy parent in the temp hash
                unless tmpHash.member? parent_id then
                    tmpHash[parent_id] = {
                        :children => []
                    }
                end
            
                tmpHash[parent_id][:children] << post_id
            end
        end

        posts = []
        result.each do |post|
            tmpPost = tmpHash[post.id]
            # If this post is a reply and its parent has been deleted
            if nil != (prnt = post.path.last) and tmpHash[prnt][:id].nil? then
                tmpPost[:prnt] = nil
                # Look at each ancestor in turn for a post that exists
                post.path.reverse.take_while do |anc|
                    if not tmpHash[anc][:id].nil? then
                        tmpPost[:prnt] = anc
                        tmpHash[anc][:children].push tmpPost[:id]
                        false
                    else
                        true
                    end
                end
            end
            posts.push tmpPost
        end

        return posts
    end

    def threads(board)
        result = Post.by_thread :startkey => [:board], :endkey => [board, {}], :reduce => true, :group_level => 2
        rows = result["rows"]

        posts = []                                                   
        rows.each do |row|                                        
            post = row['value']
            id = row['key'][1]
            posts.push({
                :id => id,
                :newest => post[0],
                :replies => post[1],
                :newest_by => post[2],
                :started_by => post[3],
                :started => post[4],
                :subject => post[5]
            })
        end                                                          
        return posts
    end

    # Return the number of seconds since the specified user last posted
    # === Parameters
    # * _user_ = a User object or a username String
    def secs_ago_posted(user)
        username = if user.is_a? User then user.username else user end
        last_post = @user_last_posted[username]
        if last_post.nil? then
            result = Post.by_author_and_date :startkey => [username, {}], 
                :endkey => [username] , :descending => true,  :limit => 1
            return Time.now.to_f if result.empty?
            last_post = result.first.date
            return Time.now.to_f if last_post.nil?
        end
        Time.now - last_post.to_time
    end

    def post(params = {})

        @user_last_posted[:username] = DateTime.now
        post = Post.new(
            :body => params[:body],
            :author => params[:author],
            :date => (params.key? :date) ? params[:date] : DateTime.now
        )
        post.subject = params[:subject] if params.key? :subject
        if params.key? :parent then
            parent=params[:parent]
            post.set_parent parent
            post.board = parent.board
        elsif params.key? :board then
            post.board = params[:board]
        end
        post.save!

    end

end
