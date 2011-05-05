require 'rubygems'
require 'couchrest_extended_document'

require './post.rb'

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

