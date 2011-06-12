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

# Build a random database for testing purposes

require 'rubygems'
require 'couchrest_extended_document'
require 'random_data'
require 'logger'

require './board.rb'
require './post.rb'
require './user.rb'

db_url = 'http://127.0.0.1:5984/converse_random'
DB = CouchRest.database!(db_url)
CouchRest::Document::use_database DB
DB.recreate!
[Board, Post, User].each {|k| k.save_design_doc!}

logger = Logger.new(STDERR)

USER_COUNT = 20
names = []
until names.count == USER_COUNT do 
    name = Random.first_name
    names.push name unless names.include? name
end

logger.info names.inspect

avtr_files = []
avtr_dir = Dir.new './scratch/avatar'
avtr_dir.entries.shuffle.each do |fn|
    path = avtr_dir.path + '/' + fn
    next unless File.file? path
    file = File.new(path)
    avtr_files.push file
end

first = true
users = []
names.each do |name|
    user = User.new(:username => name, :joined => Random.date, 
        :roles => if first then [:admin] else [] end, :groups => [])
    user.avatar=avtr_files.pop
    user.create_password 'f00f'
    user.save
    users.push user
    first = false;
end

Board.new(:name => 'main', :title => 'General Discussion', :owners => [names.first],
    :mod_groups => [], :status => 'open', :groups => [], :private => false, 
    :moderated => false).save

CHANCE = 4
REPLIES = 6
THREADS = 98

def reply (users, post)
    return unless (rand CHANCE) == 0 
    replies = (rand REPLIES)+1
    author = users[rand users.count]
    date = post.date
    replies.times do 
        date = date.next_day
        r = Post.new( :body => (Random.paragraphs rand(5)+1), :date => date,
            :author => author.username,
            :path => [],
            :board => 'main')
        r.set_parent post
        r.save
        reply(users, r)
    end
end
    

root_date = Random.date_between Date.parse('2001-01-01')..Date.parse('2002-01-01')
THREADS.times do
    author = users[rand USER_COUNT]
    root = Post.new(
        :subject => ((Random.paragraphs 1).chomp.chomp.split ' ')[0..rand(12)+3].join(' '),
        :body => (Random.paragraphs rand(5)+1), :date => root_date, 
        :author => author.username,
        :path => [],
        :board => 'main')
    root.save
    reply(users, root)
    root_date = root_date.next_day
end

