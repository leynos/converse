/*
 * Copyright © 2011, David McIntosh <dmcintosh@df12.net>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

(function (window, undefined) {


var root_id = "38bd0a3ccf69621c9695281050000ab2";

var logged_in = false;

// From http://delete.me.uk/2005/03/iso8601.html
Date.prototype.setISO8601 = function (string) {
    var regexp = "([0-9]{4})(-([0-9]{2})(-([0-9]{2})" +
        "(T([0-9]{2}):([0-9]{2})(:([0-9]{2})(\.([0-9]+))?)?" +
        "(Z|(([-+])([0-9]{2}):([0-9]{2})))?)?)?)?";
    var d = string.match(new RegExp(regexp));

    var offset = 0;
    var date = new Date(d[1], 0, 1);

    if (d[3]) { date.setMonth(d[3] - 1); }
    if (d[5]) { date.setDate(d[5]); }
    if (d[7]) { date.setHours(d[7]); }
    if (d[8]) { date.setMinutes(d[8]); }
    if (d[10]) { date.setSeconds(d[10]); }
    if (d[12]) { date.setMilliseconds(Number("0." + d[12]) * 1000); }
    if (d[14]) {
        offset = (Number(d[16]) * 60) + Number(d[17]);
        offset *= ((d[15] == '-') ? 1 : -1);
    }

    offset -= date.getTimezoneOffset();
    time = (Number(date) + (offset * 60 * 1000));
    this.setTime(Number(time));
}

// Replace quotes with an appropriate escape sequence to allow 
// placing text in a js event
function escapeQuotes(value) 
{
    if(!value) return "";
    return value.replace(/\\/g, '\\\\')
        .replace(/'/g, '\\\'').replace(/"/g, '\\\"');
}

function htmlSpecialChars(value) {
    if(!value) return "";
    return String(value).replace(/&/g, "&amp;").replace(/</g, "&lt;")
        .replace(/>/g, "&gt;").replace(/"/g, "&quot")
        .replace(/'/g, "&#039");
}

function ThreadUI(delegate) 
{

    var me = this;

    var mul=20;
    var vmul=25;

    Raphael.fn.dash = function(x, y) {
        x1=(x-0.5)*mul;
        y1=(y)*vmul;
        x2=(x+0.5)*mul;
        y2=(y)*vmul;
        p = this.path(sprintf("M%d %d L%d %d", x1, y1, x2, y2));
        setPathAttrs(p);
        return p;
    }

    Raphael.fn.tee = function(x, y) {
        s = this.set();
        s.push(this.dash(x, y));
        x1=(x)*mul;
        y1=(y)*vmul;
        x2=(x)*mul;
        y2=(y+0.5)*vmul;
        p = this.path(sprintf("M%d %d L%d %d", x1, y1, x2, y2));
        setPathAttrs(p);
        return p;
    }

    Raphael.fn.el = function(x, y) {
        x1=(x)*mul;
        y1=(y-0.5)*vmul;
        x2=(x)*mul;
        y2=(y)*vmul;
        x3=(x+0.5)*mul;
        y3=(y)*vmul;
        p = this.path(sprintf("M%d %d L%d %d L%d %d", x1, y1, x2, y2, x3, y3));
        setPathAttrs(p);
        return p;
    }

    Raphael.fn.bar = function(x, y) {
        x1=(x)*mul;
        y1=(y-0.5)*vmul;
        x2=(x)*mul;
        y2=(y+0.5)*vmul;
        p = this.path(sprintf("M%d %d L%d %d", x1, y1, x2, y2));
        setPathAttrs(p);
        return p;
    }

    Raphael.fn.rtee = function(x, y) {
        s = this.set()
        s.push(this.bar(x, y));
        x1=(x)*mul;
        y1=(y)*vmul;
        x2=(x+0.5)*mul;
        y2=(y)*vmul;
        p = this.path(sprintf("M%d %d L%d %d", x1, y1, x2, y2))
        setPathAttrs(p);
        s.push(p);
        return s;
    }

    // Add the view components
    $('#view').children().remove();
    $('#view').append('<div id="notepad"></div>');
    $('#view').append('<div id="messagepane"></div>');

    var paper = Raphael("notepad", 400, 300);

    var circles = {};

    var selection;

    // Select a post and draw the selection circle
    this.select = function(id) {
        var messageCell = $(".selected-message")
        if (messageCell) {
            messageCell.removeClass("selected-message");
        }
        messageCell = $("#post-"+id)
        if (messageCell) {
            messageCell.addClass("selected-message");
        }

        // If a delection exists already, remove it and draw a new one
        if (selection)
            selection.remove();
        var c = circles[id];
        if (c) {
            cx = c.attr("cx");
            cy = c.attr("cy");
            selection = paper.circle(cx, cy, mul*0.2);
            selection.attr("fill", "black");
        }

        // Scroll to the post in the message pane
        var post_off = $("#post-"+id).position().top;
        $("#messagepane").scrollTo( "#post-"+id , 400, {axis:'y'} );

        selected_id = id;
    }

    var select = this.select;

    function setPathAttrs(p) {
        p.attr("stroke-width", mul/8);
        p.attr("stroke", "gray");
    }

    function drawTree(post, x, y) {
        if (!x) x=1;
        if (!y) y=1;

        var c = paper.circle(x*mul, y*vmul, mul*0.4);
        var id = post.id;
        var onclick = function () {
            select(id, paper);
        };
        circles[id] = c;
        c.attr("fill", "white");
        c.node.onclick = onclick;
        $(c.node).qtip({
            content: 'id: '+post.id+'<br />author: '+users[post.author].displayname+'<br />date: '+post.date,
            show: 'mouseover',
            hide: 'mouseout',
            position: {
                target: 'mouse', 
                corner: {
                    target: 'rightBottom',
                    tooltip: 'leftTop'
                }
            }
        });
        
        var i=0;
        var count=1;

        _(post.children).each(function (child) {
            var last = (count==post.children.length);
            if (last && count==1) {
                paper.dash(x+1, y+i);
            } else if (count==1) {
                paper.tee(x+1, y+i);
            } else if (last) {
                paper.el(x+1, y+i);
            } else {
                paper.rtee(x+1, y+i);
            }
            dy = drawTree(postsHash[child], x+2, y+i);
            if (dy > 1 && !last) {
                for (j=1; j<dy; j++) {
                    paper.bar(x+1, y+i+j);
                }
            }
            i += dy;
            count += 1;
        });
        return (i==0) ? 1 : i;
    }

    this.redrawTree = function (post_id, x, y) {
        if (selection) {
            selection.remove();
            selection = null;
        }
        paper.clear();
        drawTree(postsHash[post_id]);
    }

    var postsHash = {};
    var orderedPosts = [];
    var users = {};
    var parser = new BBCodeParser();

    this.addPost = function (post) {
        // Skip this post if we have it already
        // Layer, maybe update the body if needs be
        if (null != postsHash[post.id]) {
            postsHash[post.id].children = post.children;
            return;
        }

        postsHash[post.id] = post;

        // Determine where the post should be inserted
        var ind = _(orderedPosts).chain()
            .pluck(orderedPosts, "date") 
            .sortedIndex(post.date);

        // Insert the post at ind
        orderedPosts.splice(ind, 0, post);

        // Assemble a div object for the post
        var div = $('<div>', {
            id: "post-"+post.id,
            class: "message-cell"
        });
        div.dblclick(function(e) {
            select(post.id, paper);
        });
        if (null != post.body)
        {
            div.html(parser.format(post.body));
        }
        var author_id = post.author;
        var author = users[author_id];
        if (author) {
            div.prepend('<h3>'+author.displayname+'</h3>');
            div.prepend('<img src="user/'+encodeURIComponent(author_id)+
                '/avatar" class="avatar" class="avatar" />');
        }

        var messageToolbar = $('<div />', {
            'class': 'message-toolbar',
        });
        var deleteButton = $('<img />', {
            src: 'images/deletepost_s.png',
            'class': 'message-control delete-button',
        });
        messageToolbar.append(deleteButton);
        var replyButton = $('<img />', {
            src: 'images/reply_s.png',
            'class': 'message-control reply-button',
        });
        replyButton.click(function () {
            showReply(post.id);
        });
        messageToolbar.append(replyButton);
        div.append(messageToolbar);
    

        // Insert into message pane to reflect array
        var prnt = $("#messagepane");
        if (prnt) {
            var children = prnt.children();
            if (children.length > ind) {
                children[ind].before(div);
            } else {
                prnt.append(div);
            }
        }
    }

    this.addUsers = function (data) {
        $.extend(users, data);
    }

    var selected_id;

    function par(id) {
        return postsHash[id].prnt;
    }

    this.selectParent = function () {
        var id=par(selected_id);
        if (id) {
            select(id, paper);
        }
    }

    function firstChild(id) {
        return _(postsHash[id].children).first();
    }

    this.selectFirstChild = function () {
        var id=firstChild(selected_id);
        if (id) {
            select(id, paper);
        }
    }

    function nextCousin(id) {
        var prnt = id;
        var depth = 0;
        var cand = null;
        while (!cand) {
            var old_prnt = prnt;
            prnt = par(old_prnt);
            if (!prnt)
                return null; // we've hit the root and still not found a cousin
            depth++;
            cand = prnt;
            var j = 0;
            while (j < depth) {
                var children = postsHash[cand].children;
                var i= _(children).indexOf(old_prnt);
                cand = children[i+1];
                if (!cand)
                    break; // reached a leaf before finding a cousin
                j++;
            }
        }
        return cand;
    }

    this.selectNextCousin = function () {

        var id=nextCousin(selected_id);
        if (id) {
            select(id, paper);
        }
    }

    function prevCousin(id) {
        var prnt = id;
        var depth = 0;
        var cand = null;
        while (!cand) {
            var old_prnt = prnt;
            prnt = par(old_prnt);
            if (!prnt)
                return null; // we've hit the root and still not found a cousin
            depth++;
            cand = prnt;
            var j = 0;
            while (j < depth) {
                var children = postsHash[cand].children;
                var i= _(children).indexOf(old_prnt);
                cand = i<0?children[children.length-1]:children[i-1];
                if (!cand)
                    break; // reached a leaf before finding a cousin
                j++;
            }
        }
        return cand;
    }

    this.selectPrevCousin = function () {
        var id=prevCousin(selected_id);
        if (id) {
            select(id, paper);
        }
    }

    this.handleResize = function () {
        $("#messagepane").height( $(window).height() - $("#notepad").outerHeight() -8 );
        $("#notepad").width( $(window).width() - 16 );
    }

    function replyCallback (req) {
        if (req.status == 200) {
            $( '#reply-dialog' ).remove();
            delegate.reloadCurrentThread();
        } else if (req.status == 403) {
            $('#reply-form')
                .before('<div class="error" id="reply-form-error">You are not permitted to reply here</div>');
        } else if (req.status == 404) {
            $('#reply-form')
                .before('<div class="error" id="reply-form-error">The post your are replying to no longer exists</div>');
        } else {
            $('#reply-form')
                .before('<div class="error" id="reply-form-error">An error occurred posting this reply</div>');
        }
    }

    function showReply(postId) {
        if ($('#reply-dialog').length != 0 ) {
            return false;
        }
        var editor;
        $('<div id="reply-dialog">').load("panels/reply.html", function () {
            editor = $('#reply-body-field').cleditor({
                width: "100%", height: "80%", 
                controls: "bold italic underline strikethrough | " +
                    "| bullets numbering " + "| undo redo | " +
                    "rule image link unlink | source",})[0];
        }).dialog( {
            resizable: true, 
            width: 640, 
            title: 'Post a Reply',
            close: function() { $( this ).remove(); },
            buttons: {
                "Reply": function() {
                    editor.updateTextArea();
                    $('#reply-dialog div.error').remove();
                    $.ajax( {
                        url: 'post/'+encodeURIComponent(postId)+'/reply',
                        data: { 
                            body: $('#reply-body-field').val() 
                        },
                        type: 'POST',
                        complete: replyCallback,
                    } );
                },
                "Cancel": function() {
                    $( this ).remove();
                }
            }
        } );
    }

    this.noPosts = function() {
        $("#messagepane").html("No post found! :o");
    }

    $("#messagepane").height( $(window).height() - $("#notepad").outerHeight() -8 );

    $('#notepad').resizable({
        containment: 'document',
        handles: 's'
    });

    $(window).resize( function() {
        me.handleResize();
    });

    $('#notepad').bind( "resize", function(event, ui) {
        me.handleResize();
    });
    
    shortcut.add('a', function() {
        me.selectParent();
    }, { 'disable_in_input': true });

    shortcut.add('d', function() {
        me.selectFirstChild();
    }, { 'disable_in_input': true });

    shortcut.add('w', function() {
        me.selectPrevCousin();
    }, { 'disable_in_input': true });

    shortcut.add('s', function() {
        me.selectNextCousin();
    }, { 'disable_in_input': true });

    this.destroy = function() {
        shortcut.remove('a');
        shortcut.remove('s');
        shortcut.remove('d');
        shortcut.remove('w');
    }
}

function BoardUI(delegate) 
{
    $('#view').children().remove();
    $('#view').append('<div id="thread-list"></div>');
    $('#thread-list').append('<div id="thread-list-toolbar"></div>');
    $('#thread-list-toolbar').append($( '<button id="new-thread-button"><img src="images/newthread.png"> Create a new thread</button>' ).button());
    $('#thread-list').append('<table id="thread-table"></table>');
    $('#thread-table').append('<thead><th class="subject">Subject</th><th>Replies</th><th>Last Post By</th></thead><tbody></tbody>');

    var odd=true;;

    this.addThread = function (thread) {

        var started = new Date();
        started.setISO8601(thread.started);
        var newest = new Date();
        newest.setISO8601(thread.newest);
        $('#thread-table > tbody').append(
            '<tr' + (odd?' class="odd"':'') + '><td><a href="#!thread/' + 
            htmlSpecialChars(thread.id) + '">' +
            htmlSpecialChars(thread.subject) + '</a></td><td>' + 
            htmlSpecialChars(thread.replies) + '</td><td>' +
            htmlSpecialChars(thread.newest_by) + ' (' +
            newest.toLocaleDateString() + ')</td></tr>'
        );
        $('#thread-table > tbody').append(
            '<tr class="byline ' + (odd?' odd':'') + '"><td colspan=3 ><small>' + 
            'Started by: ' + htmlSpecialChars(thread.started_by) + ' (' + 
            started.toLocaleDateString() + ')</small></td></tr>'
        );
        odd = !odd;
    }

    this.noThreads = function () {
        $('#thread-list').text('No threads have been posted to this board');
    }

    this.destroy = function() { }
}

function Converse() 
{
    var me = this;
    var view;
    var currentThread;

    this.reloadCurrentThread = function() {
        me.loadPost(currentThread);
    }

    this.loadPost = function (post_id) {
        var modelCallback = function (data, textStatus, response) {
            if (data.users) {
                view.addUsers(data.users);
            }
            if (data.posts && data.posts.length > 0) {
                _(data.posts).each(function(post) {
                    view.addPost(post);
                });
                view.redrawTree(post_id);
                view.select(post_id);
            } else {
                view.noPosts();
            }
        };
        var options = {
            url: "post/"+encodeURIComponent(post_id),
            success: modelCallback
        };
        $.ajax(options);
    }

    this.loadBoard = function (board_id) {
        var modelCallback = function (data, textStatus, response) {
            if (data.threads)
            {
                _(data.threads).each(function(thread) {
                    view.addThread(thread)
                });
            } else {
                view.noThreads();
            }
        };
        var options = {
            url: "board/"+encodeURIComponent(board_id),
            success: modelCallback
        };
        $.ajax(options);
    }

    this.setView = function(v) {
        if (view) view.destroy();
        view = v;
    }

    this.viewThread = function(root_id) {
        if (!root_id) root_id = "38bd0a3ccf69621c9695281050000ab2";

        currentThread = root_id;
        // pass self to threadui as delegate
        me.setView(new ThreadUI(me));
        me.loadPost(root_id);
    }

    this.viewBoard = function(board_id) {
        if (!board_id) board_id = 'main';

        currentBoard = board_id;
        // pass self to threadui as delegate
        me.setView(new BoardUI(me));
        me.loadBoard(board_id);
    }
}

function toolbarButton(id, image, caption, onclick) 
{
    var button = $('<div />', {
        id: id,
        class: 'toolbar-button'
    });
    if (image) {
        button.append('<img src="'+image+'" /><br />');
    }
    button.append('<span class="caption">'+caption+'</span>');
    if (onclick) {
        button.click(onclick);
    }
    return button;
}

function loadToolbar(loginInfo) 
{
    $('#toolbar div').remove();
    toolbar = $('#toolbar');
    if (loginInfo.loggedin) {
        toolbar.append(toolbarButton(
            'user-badge', '/user/'+encodeURIComponent(loginInfo.username)+'/avatar/small', loginInfo.username, showEditUser));
        toolbar.append(toolbarButton(
            'logout', 'images/logout.png', 'Log Out', showConfirmLogout));
    } else {
        toolbar.append(toolbarButton(
            'login', 'images/login.png', 'Log In', showLogin));
        toolbar.append(toolbarButton(
            'adduser', 'images/adduser.png', 'Register', showAddUser));
    }

}

function addUserCallback(req) 
{
    if (req.status == 201) {
        $( '#user-dialog' ).remove();
    } else if (req.status == 409) {
        $('#user-username-field')
            .after('<div class="error" id="user-form-error">A user of that name already exists</div>');
    } else {
        $('#user-form')
            .before('<div class="error" id="user-form-error">The user could not be created</div>');
    }
}

function showAddUser() 
{
    if ($('#user-dialog').length != 0 ) {
        return false;
    }
    $('<div id="user-dialog">').load("panels/user.html").dialog( {
        resizable: false, 
        width: 350, 
        title: 'Create User',
        close: function() { $( this ).remove(); },
        buttons: {
            "Create": function() {
                $('#user-form-error').remove();
                $.ajax( {
                    url: 'user/'+encodeURIComponent($('#user-username-field').val()), 
                    data: { password: $('#user-password-field').val() },
                    type: 'PUT',
                    complete: addUserCallback
                } );
            },
            "Cancel": function() {
                $( this ).remove();
            }
        }
    } );
}

function showEditUser(user) 
{
    if ($('#edituser-dialog').length != 0 ) { 
        return false;
    }
    var reloadAvatars = function () {
                $(".avatar").each(function() {
                    src = $(this).attr('src');
                    cookie = Math.random();
                    $(this).attr('src', src+'?'+cookie);
                });
                $("#user-badge img").each(function() {
                    src = $(this).attr('src');
                    cookie = Math.random();
                    $(this).attr('src', src+'?'+cookie);
                });
            };
    $('<div id="edituser-dialog">').load("panels/edituser.html", function() {
            $("#avatar-upload-file").change(function() {
                this.form.submit();
                $("#avatar-upload-target").load( reloadAvatars);
            });
        }).dialog( {
        resizable: false,
        width: 500,
        title: 'Edit User',
        close: function() { $( this ).remove(); },
    } );
}

function loginCallback(data, statusText, req, error) 
{
    if (req.status == 200) {
        $( '#login-dialog' ).remove();
        loadToolbar(data);
    } else if (req.status == 403) {
        $('#login-form')
            .before('<div class="error" id="login-form-error">An incorrect username or password has been supplied</div>');
    } else {
        $('#login-form')
            .before('<div class="error" id="login-form-error">A problem has occurred logging in</div>');
    }
}

function showLogin() 
{
    if ($('#login-dialog').length != 0 ) {
        return false;
    }
    function doLogin() {
        $('#login-form-error').remove();
        $.ajax({
            url: 'login', 
            data: { 
                username: $('#login-username-field').val(), 
                password: $('#login-password-field').val() 
            },
            type: 'POST',
            success: loginCallback,
            error: function(req, statusText, error) {
                loginCallback(null, statusText, req, error);
            },
        });
    }
    $('<div id="login-dialog">').load("panels/login.html", function() {
        $('#login-form').keypress(function(e){
            if ((e.which && e.which == 13) || (e.keyCode && e.keyCode == 13)) {
                e.preventDefault();
                doLogin();
            }
        });
    }).dialog( {
        resizable: false, 
        width: 350, 
        modal: true,
        title: 'Log In',
        close: function() { $( this ).remove(); },
        buttons: {
            "Log In": doLogin,
            "Cancel": function() {
                $( this ).remove();
            }
        }
    } );
}

function showConfirmLogout() 
{
    $('<div id="logout-dialog">Are you sure you wish to log out?</div>').dialog( {
        resizable: false, 
        modal: true,
        title: 'Log Out',
        buttons: {
            "Yes": function() {
                $( this ).remove();
                $.ajax( {
                    url: 'logout', 
                    type: 'POST',
                    success: function(data) { 
                        loadToolbar(data);
                    }
                } );
            },
            "No": function() {
                $( this ).remove();
            }
        }
    });
}

var converse = new Converse();

function test()
{
    window.alert('test');
}


$(window.document).ready( function() {

    var routes = {
        board: converse.viewBoard,
        thread: converse.viewThread,
        'default': converse.viewBoard,
    };
    $(window).bind( 'hashchange', function(e) {
        var url = location.hash;
        url = url.replace(/^#!?/, '');
        var parts = url.split('/');
        var cmd = parts.shift();
        if (routes[cmd]) {
            routes[cmd](parts[0]);
        } else {
            routes['default']();
        }
    });

    $.get('loggedin', function(data) {
        loggedin=data.loggedin;
        loadToolbar(data);
        $(window).trigger( 'hashchange' );
    });
});

})(window);


    

