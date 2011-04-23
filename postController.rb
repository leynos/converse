class PostController

    def usersForId(root_id)
        result = Post.by_first_ancestor :key => root_id, :reduce => true
        if result['rows'].nil? or result['rows'].count == 0 or 
           result['rows'][0]['value'].nil? then
            return []
        end
        names = result['rows'][0]['value']
        users = {};
        names.each do |username|
            result = User.by_username :key => username
            if result.empty? then
                next
            end
            user = result[0];
            users[username] = {
                :username => user.username,
                :displayname => 
                    if user.displayname.nil? then 
                        user.username 
                    else 
                        user.displayname 
                    end,
                :avatar => 'default'
            }
        end
        return users
    end

    def postsForId(root_id)

        logger = Logger.new(STDERR)

        result = Post.by_ancestor :startkey => [root_id], :endkey => [root_id, {}]

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

        # Return a list of posts sorted by date
        return tmpHash.values.sort do |a, b|
            a[:date] <=> b[:date]
        end
    end

end
