# What is it

The idea is to ultimately build a web forum with proper separation of concerns between the client and server. The initial implementation uses a client written in Javascript and a server in Ruby, but any conceivable combination should be possible (a native client for Android and iOS would seem the next logical step). The two talk using a pseudo-RESTful API (pseudo, because it uses JSON instead of XML).

Right now, all that works is a single thread view. The top pane is the thread map and the bottom pane is the messages. Ultimately, there will be multiple boards with multiple posts, but this is the prototype as it exists just now.

# Some bits you may (or may not) care about

The server is written in Ruby using Sinatra, with a CouchDB database. All of these elements are new to me, so I'm learning this as I go along. Similarly, I'm a novice at JavaScript in many ways.

The thread map is drawn using the cross-browser Raphael library, so it should work in IE as well (it did last time I tested it).

# Usage

Pre-requisites: Ruby, CouchDB, Bundler (optional, but it makes life easier)

Start CouchDB.

    git clone git://github.com/leynos/converse.git
    cd converse
    bundle
    ruby converse.rb
    firefox http://127.0.0.1:4567/

Or use Heroku with the Cloudant Oxygen add-on.
