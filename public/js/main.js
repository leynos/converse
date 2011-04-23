
(function (window, document, undefined) {

var converse = {};

var root_id = "38bd0a3ccf69621c9695281050000ab2";

var logged_in = false;

// Replace quotes with an appropriate escape sequence to allow 
// placing text in a js event
function escapeQuotes(value)
{
    if(!value) return "";
    return value.replace(/\\/g, '\\\\')
        .replace(/'/g, '\\\'').replace(/"/g, '\\\"');
}

function ThreadUI() {

    var mul=20;
    var vmul=25;

    Raphael.fn.dash = function(x, y)
    {
        x1=(x-0.5)*mul;
        y1=(y)*vmul;
        x2=(x+0.5)*mul;
        y2=(y)*vmul;
        p = this.path(sprintf("M%d %d L%d %d", x1, y1, x2, y2));
        setPathAttrs(p);
        return p;
    }

    Raphael.fn.tee = function(x, y)
    {
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

    Raphael.fn.el = function(x, y)
    {
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

    Raphael.fn.bar = function(x, y)
    {
        x1=(x)*mul;
        y1=(y-0.5)*vmul;
        x2=(x)*mul;
        y2=(y+0.5)*vmul;
        p = this.path(sprintf("M%d %d L%d %d", x1, y1, x2, y2));
        setPathAttrs(p);
        return p;
    }

    Raphael.fn.rtee = function(x, y)
    {
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

    function setPathAttrs(p)
    {
        p.attr("stroke-width", mul/8);
        p.attr("stroke", "gray");
    }

    var select = this.select;

    function drawTree(post, x, y)
    {
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
            content: 'id: '+post.id+'<br />author: '+users[post.author].name+'<br />date: '+post.date,
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

    this.redrawTree = function (post_id, x, y)
    {
        if (selection)
        {
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

    this.addPost = function (post)
    {
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
        if (null != div.body)
        {
            div.html(parser.format(post.body));
        }
        var author_id = post.author;
        var author = users[author_id];
        if (author) {
            div.prepend('<h3>'+author.displayname+'</h3>');
            if (author.avatar) {
                div.prepend('<img src="avatar/'+encodeURIComponent(author_id)+'/'+encodeURIComponent(author.avatar)+'" class="avatar" />');
            } else {
                div.prepend('<img src="images/no_avatar.png" class="avatar" />');
            }
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

    this.selectParent = function ()
    {
        var id=par(selected_id);
        if (id) {
            select(id, paper);
        }
    }

    function firstChild(id) {
        return _(postsHash[id].children).first();
    }

    this.selectFirstChild = function ()
    {
        var id=firstChild(selected_id);
        if (id) {
            select(id, paper);
        }
    }

    function nextCousin(id)
    {
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

    this.selectNextCousin = function ()
    {
        var id=nextCousin(selected_id);
        if (id) {
            select(id, paper);
        }
    }

    function prevCousin(id)
    {
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

    this.selectPrevCousin = function ()
    {
        var id=prevCousin(selected_id);
        if (id) {
            select(id, paper);
        }
    }

    this.handleResize = function ()
    {
        $("#messagepane").height( $(window).height() - $("#notepad").outerHeight() -8 );
        $("#notepad").width( $(window).width() - 16 );
    }

    function replyCallback (req)
    {
        if (req.status == 200) {
            $( '#reply-dialog' ).remove();
            converse.loadPost(root_id);
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

    function showReply(postId)
    {
        if ($('#reply-dialog').length != 0 ) {
            return false;
        }
        var editor;
        $('<div id="reply-dialog">').load("reply.html", function () {
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
}

var threadUI = new ThreadUI();

converse.loadPost = function (post_id)
{
    var modelCallback = function (data, textStatus, response) {
        if (data.users) {
            threadUI.addUsers(data.users);
        }
        if (data.posts && data.posts.length > 0) {
            _(data.posts).each(function(post) {
                threadUI.addPost(post);
            });
            threadUI.redrawTree(post_id);
            // threadUI.select(post_id);
        } else {
            $("#messagepane").html("No post found! :o");
        }
    };
    var options = {
        url: "post/"+encodeURIComponent(post_id),
        success: modelCallback
    };
    $.ajax(options);
}

function toolbarButton(id, image, caption, onclick)
{
    var button = $('<div />', {
        id: id,
        class: 'toolbar-button'
    });
    if (image) {
        button.append($('<img />', {
            src: image
        }));
        button.append('<br />');
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
            'user-badge', 'images/no_avatar_s.png', loginInfo.username, null));
        toolbar.append(toolbarButton(
            'logout', 'images/logout.png', 'Log Out', showConfirmLogout));
    } else {
        toolbar.append(toolbarButton(
            'login', 'images/login.png', 'Log In', showLogin));
    }

    if (_(loginInfo.rights).include('manage_users')) {
        toolbar.append(toolbarButton(
            'adduser', 'images/adduser.png', 'Add User', showAddUser));
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
    $('<div id="user-dialog">').load("user.html").dialog( {
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
    $('<div id="login-dialog">').load("login.html").dialog( {
        resizable: false, 
        width: 350, 
        modal: true,
        title: 'Log In',
        close: function() { $( this ).remove(); },
        buttons: {
            "Log In": function() {
                $('#login-form-error').remove();
                $.ajax( {
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
                } );
            },
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

$(document).ready( function() {
    $("#messagepane").height( $(window).height() - $("#notepad").outerHeight() -8 );

    $(window).resize( function() {
        threadUI.handleResize();
    });

    $('#notepad').resizable({
        containment: 'document',
        handles: 's'
    });

    $('#notepad').bind( "resize", function(event, ui) {
        threadUI.handleResize();
    });


    shortcut.add('a', function() {
        threadUI.selectParent();
    }, { 'disable_in_input': true });

    shortcut.add('d', function() {
        threadUI.selectFirstChild();
    }, { 'disable_in_input': true });

    shortcut.add('w', function() {
        threadUI.selectPrevCousin();
    }, { 'disable_in_input': true });

    shortcut.add('s', function() {
        threadUI.selectNextCousin();
    }, { 'disable_in_input': true });

    $.get('loggedin', function(data) {
        loggedin=data.loggedin;
        loadToolbar(data);
        converse.loadPost(root_id);
    });
});

})(window, window.document);


    

