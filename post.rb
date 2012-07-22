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

class Post < CouchRest::ExtendedDocument

    property :subject,  String
    property :date,     DateTime
    property :author
    property :path,     [String]
    property :body
    property :board

    #  CouchDB views consisting of a map and reduce function
    view_by  :author, :date,
        # Retrieve a list of posts for a given author ordered by date and time
        :map => "function(doc) {
            if ((doc['couchrest-type'] == 'Post') && (doc['author'] != null) && (doc['date'] != null)) {
                emit([doc['author'], doc['date']], null);
            }
        }",
        # Calculate the number of posts by a given user (Group by level 1 for this)
        :reduce => "function(key, values, rereduce) {
            var sum = [0, ''];
            if (rereduce)
            {
                values.forEach(function(val) {
                    sum[0] += val[0];
                    // If a newer post exists
                    if (val[1] > sum[1]) {
                        sum[1]=val[1];
                    }
                });
            } else {
                key.forEach(function(k) {
                    sum[0]++;
                    // If a newer post exists
                    if (k[0][1] > sum[1]) {
                        sum[1]=k[0][1];
                    }
                });
            }
            return sum;
        }"

    view_by  :thread,
        # Retrieves the posts for a given thread, ordered by date
        # This is used both for building thread maps and as an intermediate form
        # for building board thread lists
        :map => "function(doc) {
            if (doc['couchrest-type'] == 'Post') 
            {
                if (doc.path.length == 0)
                {
                    // post
                    emit([doc.board, doc._id, doc.date, 0, doc.subject], doc);
                } else {
                    // reply
                    emit([doc.board, doc.path[0], doc.date, 1], doc, null);
                }
            }
        }",
        # Returns an array for each thread in a given board: 
        # [ date of most recent post, 
        #   reply count, 
        #   most recent author, 
        #   originating author, 
        #   starting date,
        #   opening subject ]
        :reduce => "function(key, values, rereduce) {
            var sum = ['', 0, null, null, null];
            if (rereduce)
            {
                values.forEach(function(val) {
                    sum[1] += val[1];
                    if (val[0] > sum[0])
                    {
                        sum[0] = val[0];
                        sum[2] = val[2];
                    }
                    if (val[3]) sum[3] = val[3];
                    if (val[4]) sum[4] = val[4];
                    if (val[5]) sum[5] = val[5];
                });
            } else {
                var i = 0;
                key.forEach(function(k) {
                    var doc = values[i];
                    i++;
                    // if this is a reply
                    if (k[0][3] > 0)
                    {
                        sum[1]++;
                    } else {
                        // else capture the author and date
                        sum[3] = doc.author;
                        sum[4] = k[0][2];
                        sum[5] = doc.subject;
                    }
                    // if this is the newest reply (or post), 
                    // capture the date and author
                    if (k[0][2] > sum[0])
                    {
                        sum[0] = k[0][2];
                        sum[2] = doc.author;
                    }
                });
            }
            return sum;
        }"

    view_by  :first_ancestor,
        :map => "function(doc) {
            if (doc['couchrest-type'] == 'Post') {
                if (doc.path.length > 0) {
                    emit(doc.path[0], doc.author);
                } else {
                    emit(doc._id, doc.author);
                }
            } 
        }", 
        # Returns all authors for a given root
        :reduce => "function(key, values, rereduce) {
            var result = [];
            var ival;
            function cond_push(arr, elem) {
                if (arr.indexOf(elem) < 0) 
                    arr.push(elem);
            }
                
            values.forEach(function (val) {
                if (rereduce) {
                    val.forEach(function (ival) {
                        cond_push(result, ival);
                    });
                } else {
                    cond_push(result, val);
                }
            });
            return result;
        }"

    view_by :ancestor,
        # Allows the selection of the n most 
        # recent posts for a given ancestor
        :map => "function(doc) {
            if (doc['couchrest-type'] == 'Post') {
                doc.path.forEach(function (anc) {
                    emit([anc, doc.date], doc);
                });
                emit([doc._id, doc.date], doc);
            } 
        }"

    def self.for_id(post_id)
        return all(:key => post_id).first
    end

    def set_parent(parent)
        # Inherit the parent's path
        self.path = parent.path + [parent.id]
    end

    def self.post_history_for_user(user)
        username = if user.is_a? User then user.username else user end
        result = Post.by_author_and_date :startkey => [user.username],
                :endkey => [user.username, {}], :reduce => true, :group_level => 1
        begin 
            return result['rows'][0]['value']
        rescue NoMethodError
            return []
        end
    end

end
