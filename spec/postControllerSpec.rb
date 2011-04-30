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

require 'couchrest_extended_document'

require './post.rb'
require './postController.rb'

samplePosts = [
    { :id => 'post4', :author => 'Aldynes', 
        :date => Time.utc(2008, 7, 8, 9, 10),
        :path => [],
        :body => "DoDonPachi is the greatest STG of all time",
        :subject => "The Best STG" },
    { :id => 'post5', :author => 'Wesker', 
        :date => Time.utc(2008, 7, 8, 9, 11),
        :path => ['post4'],
        :body => "No way dude, danmaku sucks" },
    { :id => 'post51', :author => 'Yoshi', 
        :date => Time.utc(2008, 7, 8, 9, 12),
        :path => ['post4', 'post5'],
        :body => "Yer ma sucks" },
    { :id => 'post52', :author => 'Near Dark', 
        :date => Time.utc(2008, 7, 8, 9, 13),
        :path => ['post4', 'post5'],
        :body => "I respectfully disagree" },
    { :id => 'post6', :author => 'Mr. Do!', 
        :date => Time.utc(2008, 7, 8, 9, 14),
        :path => ['post4'],
        :body => "Possibly, but it owes a lot to Batsugun" },
    { :id => 'post61', :author => 'Aldynes', 
        :date => Time.utc(2008, 7, 8, 9, 15),
        :path => ['post4', 'post6'],
        :body => "Indeed, Toaplan is the grandaddy" },
    { :id => 'post62', :author => 'Near Dark', 
        :date => Time.utc(2008, 7, 8, 9, 16),
        :path => ['post4', 'post6'],
        :body => "That may be so, but it takes the genre and makes it its own" },
    { :id => 'post63', :author => 'Wesker', 
        :date => Time.utc(2008, 7, 8, 9, 17),
        :path => ['post4', 'post6'],
        :body => "Batsugun is superior to DDP in every way shape and form" },
    { :id => 'post7', :author => 'Yoshi', 
        :date => Time.utc(2008, 7, 8, 9, 18),
        :path => ['post4'],
        :body => "The prequel, DonPachi, is a more balanced game I think" },
    { :id => 'post71', :author => 'Aldynes', 
        :date => Time.utc(2008, 7, 8, 9, 19),
        :path => ['post4', 'post7'],
        :body => "More balanced maybe, but it didn't redefine shooting like DDP did" }
]

sampleExpected = [
    { :id => 'post4', :author => 'Aldynes', 
        :date => Time.utc(2008, 7, 8, 9, 10),
        :prnt => nil, :children => ['post5', 'post6', 'post7'],
        :body => "DoDonPachi is the greatest STG of all time" },
    { :id => 'post5', :author => 'Wesker', 
        :date => Time.utc(2008, 7, 8, 9, 11),
        :prnt => 'post4', :children => ['post51', 'post52'],
        :body => "No way dude, danmaku sucks" },
    { :id => 'post51', :author => 'Yoshi', 
        :date => Time.utc(2008, 7, 8, 9, 12),
        :prnt => 'post5', :children => [],
        :body => "Yer ma sucks" },
    { :id => 'post52', :author => 'Near Dark', 
        :date => Time.utc(2008, 7, 8, 9, 13),
        :prnt => 'post5', :children => [],
        :body => "I respectfully disagree" },
    { :id => 'post6', :author => 'Mr. Do!', 
        :date => Time.utc(2008, 7, 8, 9, 14),
        :prnt => 'post4', :children => ['post61', 'post62', 'post63'],
        :body => "Possibly, but it owes a lot to Batsugun" },
    { :id => 'post61', :author => 'Aldynes', 
        :date => Time.utc(2008, 7, 8, 9, 15),
        :prnt => 'post6', :children => [],
        :body => "Indeed, Toaplan is the grandaddy" },
    { :id => 'post62', :author => 'Near Dark', 
        :date => Time.utc(2008, 7, 8, 9, 16),
        :prnt => 'post6', :children => [],
        :body => "That may be so, but it takes the genre and makes it its own" },
    { :id => 'post63', :author => 'Wesker', 
        :date => Time.utc(2008, 7, 8, 9, 17),
        :prnt => 'post6', :children => [],
        :body => "Batsugun is superior to DDP in every way shape and form" },
    { :id => 'post7', :author => 'Yoshi', 
        :date => Time.utc(2008, 7, 8, 9, 18),
        :prnt => 'post4', :children => ['post71'],
        :body => "The prequel, DonPachi, is a more balanced game I think" },
    { :id => 'post71', :author => 'Aldynes', 
        :date => Time.utc(2008, 7, 8, 9, 19),
        :prnt => 'post7', :children => [],
        :body => "More balanced maybe, but it didn't redefine shooting like DDP did" }
]

describe "sample input and output data" do
    it "should align" do
        samplePosts.each_index do |i|
            samplePosts[i][:date] == sampleExpected[i][:date]
            samplePosts[i][:id] == sampleExpected[i][:id]
            samplePosts[i][:author] == sampleExpected[i][:author]
            samplePosts[i][:body] == sampleExpected[i][:body]
        end
    end
end

describe "PostController" do                                              
    describe "#addParentsAndChildren" do                                              
        it "Returns an array with a single post hash when passed an array with a single post" do 
            pc = PostController.new
            input=[Post.new(samplePosts[0].clone)]
            output=pc.addParentsAndChildren(input)
            expected=sampleExpected[0].clone
            expected[:children]=[]
            output.should == [expected]
        end

        it "Adds parent and child references to posts when passed a tree of posts, " +
                "maintaining ordering" do 
            pc = PostController.new
            input = []
            samplePosts.each { |post| input.push Post.new(post.clone) }
            output=pc.addParentsAndChildren(input)
            output.should == sampleExpected
        end

        context "When a parent post is missing" do
            it "migrates the missing post's children to their grandparent" do
                pc = PostController.new
                input = []
                samplePostsMod = samplePosts.clone
                samplePostsMod.delete_at 1
                samplePostsMod.each { |post| input.push Post.new(post.clone) }
                output=pc.addParentsAndChildren(input)

                sampleExpectedMod = sampleExpected.clone
                sampleExpectedMod[0][:children] = ['post6', 'post7', 'post51', 'post52']
                sampleExpectedMod[2][:prnt] = 'post4'
                sampleExpectedMod[3][:prnt] = 'post4'
                sampleExpectedMod.delete_at 1
                output.should == sampleExpectedMod
            end
        end
    end
end

describe "Threads" do

    before(:all) do
        db_url = 'http://127.0.0.1:5984/converse_spec'
        DB = CouchRest.database!(db_url)
        CouchRest::Document::use_database DB
        Post.save_design_doc!
        samplePosts.each do |p|
            old_post = (Post.all :key => p[:id]).first
            old_post.destroy unless old_post.nil?
            post = Post.new p.clone
            post.save!
        end
    end

    it "should return an array of thread descriptions" do
        expected = [ 
            {
                :id => 'post4',
                :newest => Time.utc(2008, 7, 8, 9, 19).iso8601, 
                :replies => 9, 
                :newest_by => 'Aldynes', 
                :started_by => 'Aldynes', 
                :started => Time.utc(2008, 7, 8, 9, 10).iso8601, 
                :subject => 'The Best STG'
            }
        ]
        pc = PostController.new
        output=pc.threads 'main'
        output.should == expected
    end
end
