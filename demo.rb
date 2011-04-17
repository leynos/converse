
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
