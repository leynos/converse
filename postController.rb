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
            if result.count == 0 then
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
            
                tmpHash[parent_id][:children].push(post_id)
            end
        end
        return tmpHash.values.sort do |a, b|
            a[:date] <=> b[:date]
        end
    end

end
