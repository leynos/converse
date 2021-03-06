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

(function (window) {


var root_id = "38bd0a3ccf69621c9695281050000ab2";

var logged_in = false;

// From http://delete.me.uk/2005/03/iso8601.html
Date.prototype.setISO8601 = function (string) {
    var regexp = "([0-9]{4})(-([0-9]{2})(-([0-9]{2})" +
        "(T([0-9]{2}):([0-9]{2})(:([0-9]{2})(\\.([0-9]+))?)?" +
        "(Z|(([-+])([0-9]{2}):([0-9]{2})))?)?)?)?";
    var d = string.match(new RegExp(regexp));

    var offset = 0;
    var time;
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
};

// Simulates PHP's date function
// From http://jacwright.com/projects/javascript/date_format
Date.prototype.format = function(format) {
    var returnStr = '';
    var replace = Date.replaceChars;
    for (var i = 0; i < format.length; i++) {
        var curChar = format.charAt(i);
        if (i - 1 >= 0 && format.charAt(i - 1) == "\\") { 
            returnStr += curChar;
        }
        else if (replace[curChar]) {
            returnStr += replace[curChar].call(this);
        } else if (curChar != "\\"){
            returnStr += curChar;
        }
    }
    return returnStr;
};
 
Date.replaceChars = {
    shortMonths: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    longMonths: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    shortDays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    longDays: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
    
    // Day
    d: function() { return (this.getDate() < 10 ? '0' : '') + this.getDate(); },
    D: function() { return Date.replaceChars.shortDays[this.getDay()]; },
    j: function() { return this.getDate(); },
    l: function() { return Date.replaceChars.longDays[this.getDay()]; },
    N: function() { return this.getDay() + 1; },
    S: function() { return (this.getDate() % 10 == 1 && this.getDate() != 11 ? 'st' : (this.getDate() % 10 == 2 && this.getDate() != 12 ? 'nd' : (this.getDate() % 10 == 3 && this.getDate() != 13 ? 'rd' : 'th'))); },
    w: function() { return this.getDay(); },
    z: function() { var d = new Date(this.getFullYear(),0,1); return Math.ceil((this - d) / 86400000); }, // Fixed now
    // Week
    W: function() { var d = new Date(this.getFullYear(), 0, 1); return Math.ceil((((this - d) / 86400000) + d.getDay() + 1) / 7); }, // Fixed now
    // Month
    F: function() { return Date.replaceChars.longMonths[this.getMonth()]; },
    m: function() { return (this.getMonth() < 9 ? '0' : '') + (this.getMonth() + 1); },
    M: function() { return Date.replaceChars.shortMonths[this.getMonth()]; },
    n: function() { return this.getMonth() + 1; },
    t: function() { var d = new Date(); return new Date(d.getFullYear(), d.getMonth(), 0).getDate() }, // Fixed now, gets #days of date
    // Year
    L: function() { var year = this.getFullYear(); return (year % 400 == 0 || (year % 100 != 0 && year % 4 == 0)); },   // Fixed now
    o: function() { var d  = new Date(this.valueOf());  d.setDate(d.getDate() - ((this.getDay() + 6) % 7) + 3); return d.getFullYear();}, //Fixed now
    Y: function() { return this.getFullYear(); },
    y: function() { return ('' + this.getFullYear()).substr(2); },
    // Time
    a: function() { return this.getHours() < 12 ? 'am' : 'pm'; },
    A: function() { return this.getHours() < 12 ? 'AM' : 'PM'; },
    B: function() { return Math.floor((((this.getUTCHours() + 1) % 24) + this.getUTCMinutes() / 60 + this.getUTCSeconds() / 3600) * 1000 / 24); }, // Fixed now
    g: function() { return this.getHours() % 12 || 12; },
    G: function() { return this.getHours(); },
    h: function() { return ((this.getHours() % 12 || 12) < 10 ? '0' : '') + (this.getHours() % 12 || 12); },
    H: function() { return (this.getHours() < 10 ? '0' : '') + this.getHours(); },
    i: function() { return (this.getMinutes() < 10 ? '0' : '') + this.getMinutes(); },
    s: function() { return (this.getSeconds() < 10 ? '0' : '') + this.getSeconds(); },
    u: function() { var m = this.getMilliseconds(); return (m < 10 ? '00' : (m < 100 ?
'0' : '')) + m; },
    // Timezone
    e: function() { return "Not Yet Supported"; },
    I: function() { return "Not Yet Supported"; },
    O: function() { return (-this.getTimezoneOffset() < 0 ? '-' : '+') + (Math.abs(this.getTimezoneOffset() / 60) < 10 ? '0' : '') + (Math.abs(this.getTimezoneOffset() / 60)) + '00'; },
    P: function() { return (-this.getTimezoneOffset() < 0 ? '-' : '+') + (Math.abs(this.getTimezoneOffset() / 60) < 10 ? '0' : '') + (Math.abs(this.getTimezoneOffset() / 60)) + ':00'; }, // Fixed now
    T: function() { var m = this.getMonth(); this.setMonth(0); var result = this.toTimeString().replace(/^.+ \(?([^\)]+)\)?$/, '$1'); this.setMonth(m); return result;},
    Z: function() { return -this.getTimezoneOffset() * 60; },
    // Full Date/Time
    c: function() { return this.format("Y-m-d\\TH:i:sP"); }, // Fixed now
    r: function() { return this.toString(); },
    U: function() { return this.getTime() / 1000; },
    _: function() { return '&nbsp;'; }
};

var en_GB_datef = 'D_jS_M_Y, g:iA';

// Replace quotes with an appropriate escape sequence to allow 
// placing text in a js event
function escapeQuotes(value) 
{
    if(!value) { return ""; }
    return value.replace(/\\/g, '\\\\')
        .replace(/'/g, '\\\'').replace(/"/g, '\\\"');
}

function htmlSpecialChars(value) {
    if(!value) { return ""; }
    return String(value).replace(/&/g, "&amp;").replace(/</g, "&lt;")
        .replace(/>/g, "&gt;").replace(/"/g, "&quot")
        .replace(/'/g, "&#039");
}

function ThreadUI(delegate) 
{

    var me = this;

    // Threadmap dimensions
    var mul=20;
    var vmul=25;
    var paperWidth = 400;
    var paperHeight = 300;

    // Raphael object for Threadmap
    var paper;

    // Threadmap elements
    var selection;
    var circles = {};
    var qtips = {};

    // Information displayed in the message pane
    var postsHash = {};
    var orderedPosts = [];
    var users = {};

    var parser = new BBCodeParser();

    var selected_id;

    // The notepad div
    var notepad;

    // notepad drag origin
    var dragOrigin = {};

    // Style threadmap elements
    function setPathAttrs(p) {
        p.attr("stroke-width", mul/8);
        p.attr("stroke", "gray");
    }

    Raphael.fn.dash = function(x, y) {
        var x1=(x-0.5)*mul;
        var y1=(y)*vmul;
        var x2=(x+0.5)*mul;
        var y2=(y)*vmul;
        var desc = "M" + x1 + " " + y1 + " L" + x2 + " " + y2;
        var p = this.path(desc);
        setPathAttrs(p);
        return p;
    };

    Raphael.fn.tee = function(x, y) {
        var s = this.set();
        s.push(this.dash(x, y));
        var x1=(x)*mul;
        var y1=(y)*vmul;
        var x2=(x)*mul;
        var y2=(y+0.5)*vmul;
        var desc = "M" + x1 + " " + y1 + " L" + x2 + " " + y2;
        var p = this.path(desc);
        setPathAttrs(p);
        return p;
    };

    Raphael.fn.el = function(x, y) {
        var x1=(x)*mul;
        var y1=(y-0.5)*vmul;
        var x2=(x)*mul;
        var y2=(y)*vmul;
        var x3=(x+0.5)*mul;
        var y3=(y)*vmul;
        var desc = "M" + x1 + " " + y1 + " L" + x2 + " " + y2 + " L" + x3 + " " + y3;
        var p = this.path(desc);
        setPathAttrs(p);
        return p;
    };

    Raphael.fn.bar = function(x, y) {
        var x1=(x)*mul;
        var y1=(y-0.5)*vmul;
        var x2=(x)*mul;
        var y2=(y+0.5)*vmul;
        var desc = "M" + x1 + " " + y1 + " L" + x2 + " " + y2;
        var p = this.path(desc);
        setPathAttrs(p);
        return p;
    };

    Raphael.fn.rtee = function(x, y) {
        var s = this.set();
        s.push(this.bar(x, y));
        var x1=(x)*mul;
        var y1=(y)*vmul;
        var x2=(x+0.5)*mul;
        var y2=(y)*vmul;
        var desc = "M" + x1 + " " + y1 + " L" + x2 + " " + y2;
        var p = this.path(desc);
        setPathAttrs(p);
        s.push(p);
        return s;
    };

    // Add the view components
    $('#view').children().remove();
    $('#view').append('<div id="mappane"><div id="notepad" /></div>');
    $('#view').append('<div id="messagepane"></div>');
    notepad = $('#notepad');
    paper = Raphael("notepad", paperWidth, paperHeight);

    function notepadDrag(e) {
        var dx = e.pageX - dragOrigin.x;
        var dy = e.pageY - dragOrigin.y;
        dragOrigin.x = e.pageX;
        dragOrigin.y = e.pageY;
        $(this).scrollTo({
            'left':'-='+dx+'px', 
            'top':'-='+dy+'px'
        });
    }

    notepad.mousedown( function(e) {
        $(this).mousemove(notepadDrag);
        dragOrigin.x = e.pageX;
        dragOrigin.y = e.pageY;
        $(this).css('cursor', 'move');
    });

    notepad.mouseup( function(e) {
        $(this).unbind('mousemove', notepadDrag);
        $(this).css('cursor', 'auto');
    });

    // Select a post and draw the selection circle
    this.select = function(id) {
        var messageCell = $(".selected-message");
        if (messageCell) {
            messageCell.removeClass("selected-message");
        }
        messageCell = $("#post-"+id);
        if (messageCell) {
            messageCell.addClass("selected-message");
        }

        // If a delection exists already, remove it and draw a new one
        if (selection) {
            selection.remove();
        }
        var c = circles[id];
        if (c) {
            var cx = c.attr("cx");
            var cy = c.attr("cy");
            selection = paper.circle(cx, cy, mul*0.2);
            selection.attr("fill", "black");
            // $(selection.node).qtip(qtips[id]);
            $(selection.node).css("cursor", "pointer");

            // If the newly selected node is nearly out of view, scroll to encompass it
            var axis = '';
            if ( (cx < notepad.scrollLeft() + (notepad.width() * 0.05)) ||
                 (cx > notepad.scrollLeft() + (notepad.width() * 0.95)) )
            {
                axis += 'x';
            }
            if ( (cy < notepad.scrollTop() + (notepad.height() * 0.25)) ||
                 (cy > notepad.scrollTop() + (notepad.height() * 0.75)) )
            {
                axis += 'y';
            }
            if (axis != '')
            {
                notepad.scrollTo($(c.node), 400, 
                    {offset: {top:vmul*-3, left:mul*-9}, axis: axis });
            }
        }

        // Scroll to the post in the message pane
        var post_off = $("#post-"+id).position().top;
        $("#messagepane").scrollTo( "#post-"+id , 400, {axis:'y'} );

        selected_id = id;
    };

    function drawPostCircle(post, x, y) {
		var circX = x*mul;
        var circY = y*vmul;
        var circRad = mul*0.4;
        var newWidth = circX+circRad;
        var newHeight = circY+circRad;
        var c;
        var cNode;
        var id = post.id;


        if (paperWidth < newWidth || paperHeight < newHeight)
        {
            paperWidth = Math.max(paperWidth, newWidth) + 20*mul;
            paperHeight = Math.max(paperHeight, newHeight) + 20*vmul;
            paper.setSize(paperWidth, paperHeight);
        }

        c = paper.circle(circX, circY, circRad);
        circles[id] = c;
        c.attr("fill", "white");
        cNode = $(c.node);
        cNode.css("cursor", "pointer");
        $(c.node).click(function(e) {
            me.select(id, paper);
        });
        qtips[id] = {
            content: '<b>'+htmlSpecialChars(post.author)+'</b><br />'+
                post.date.format(en_GB_datef),
            show: 'mouseover',
            hide: 'mouseout',
            style: {
                border: { 
                    width: 1,
                    radius: 4 
                },
                width: { max: 500 }
            },
            position: {
                target: 'mouse', 
                corner: {
                    target: 'rightBottom',
                    tooltip: 'leftTop'
                },
                adjust: { x: 16, y: 16 }
            }
        };
        cNode.qtip(qtips[id]);
    }

    function drawTree(post, x, y) {

		var count;
        var i;
		var dy;
		
        if (!x) { x=3; }
        if (!y) { y=3; }
        
        drawPostCircle(post, x, y);

        i=0; count=1;
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
        return (0===i) ? 1 : i;
    }

    this.redrawTree = function (post_id, x, y) {
        if (selection) {
            selection.remove();
            selection = null;
        }
        paper.clear();
        drawTree(postsHash[post_id]);
    };

    this.addPost = function (post) {
        // Skip this post if we have it already
        // Layer, maybe update the body if needs be
        if (postsHash[post.id]) {
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
            'class': "message-cell"
        });
        div.click(function(e) {
            me.select(post.id, paper);
        });

        if (null !== post.body)
        {
            try {
                div.html(parser.format(htmlSpecialChars(post.body)));
            } catch (err) {
                window.alert(err);
            }
        }
        var author_id = post.author;
        var author = users[author_id];
        if (author) {
            div.prepend($('<h3>').text(author_id));
            div.prepend($('<img>', { 
                src: 'user/'+encodeURIComponent(author_id)+'/avatar',
                'class': 'avatar user-'+author_id
            }));
        }
        div.find('h3').before('<div class="date">'+ post.date.format(en_GB_datef)+'</div>');

        var messageToolbar = $('<div />', {
            'class': 'message-toolbar'
        });
        var deleteButton = $('<img />', {
            src: 'images/deletepost_s.png',
            'class': 'message-control delete-button user-'+author_id,
            click: function() { window.alert('Not yet implemented'); }
        });
        messageToolbar.append(deleteButton);
/*
        if (post.author != delegate.username) {
            deleteButton.hide();
        }
*/
        var replyButton = $('<img />', {
            src: 'images/reply_s.png',
            'class': 'message-control reply-button'
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
    };

    this.addUsers = function (data) {
        $.extend(users, data);
    };

    function par(id) {
        return postsHash[id].prnt;
    }

    this.selectParent = function () {
        var id=par(selected_id);
        if (id) {
            me.select(id, paper);
        }
    };

    function firstChild(id) {
        return _(postsHash[id].children).first();
    }

    this.selectFirstChild = function () {
        var id=firstChild(selected_id);
        if (id) {
            me.select(id, paper);
        }
    };

    function nextCousin(id) {
        var prnt = id;
        var depth = 0;
        var cand = null;
        while (!cand) {
            var old_prnt = prnt;
            prnt = par(old_prnt);
            if (!prnt) {
                return null; // we've hit the root and still not found a cousin
            }
            depth++;
            cand = prnt;
            var j = 0;
            while (j < depth) {
                var children = postsHash[cand].children;
                var i= _(children).indexOf(old_prnt);
                cand = children[i+1];
                if (!cand) {
                    break; // reached a leaf before finding a cousin
                }
                j++;
            }
        }
        return cand;
    }

    this.selectNextCousin = function () {

        var id=nextCousin(selected_id);
        if (id) {
            me.select(id, paper);
        }
    };

    function prevCousin(id) {
        var prnt = id;
        var depth = 0;
        var cand = null;
        while (!cand) {
            var old_prnt = prnt;
            prnt = par(old_prnt);
            if (!prnt) {
                return null; // we've hit the root and still not found a cousin
            }
            depth++;
            cand = prnt;
            var j = 0;
            while (j < depth) {
                var children = postsHash[cand].children;
                var i= _(children).indexOf(old_prnt);
                cand = i<0?children[children.length-1]:children[i-1];
                if (!cand) {
                    break; // reached a leaf before finding a cousin
                }
                j++;
            }
        }
        return cand;
    }

    this.selectPrevCousin = function () {
        var id=prevCousin(selected_id);
        if (id) {
            me.select(id, paper);
        }
    };

    this.handleResize = function () {
        $("#messagepane").height( $(window).height() - $("#mappane").outerHeight() -8 );
        notepad.height($("#mappane").height());
        $("#mappane").width( $(window).width() - 16 );
    };

    function replyCallback (req) {
        if (req.status == 200) {
            $( '#reply-dialog' ).dialog('close');
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
        if ($('#reply-dialog').length !== 0 ) {
            return false;
        }
        var editor;
        function replyBody() {
            return $("<div/>").html($('#reply-body-field')
                .val()).text();
        }
        $('<div id="reply-dialog">').load("panels/reply.html", function () {
            editor = $('#reply-body-field').cleditor({
                width: "100%", height: "80%", 
                controls: "bold italic underline strikethrough | " +
                    "| bullets numbering " + "| undo redo | " +
                    "rule image link unlink | source"})[0];
        }).dialog( {
            resizable: true, 
            width: 640, 
            minWidth: 640,
            minHeight: 360,
            title: 'Post a Reply',
            close: function() { 
                $(window).unbind( '.cleditor' ); 
                $( this ).remove();
            },
            buttons: {
                "Reply": function() {
                    editor.updateTextArea();
                    $('#reply-dialog div.error').remove();
                    $.ajax( {
                        url: 'post/'+encodeURIComponent(postId)+'/reply',
                        data: { 
                            body: replyBody()
                        },
                        type: 'POST',
                        complete: replyCallback
                    } );
                },
                "Cancel": function() {
                    $( this ).dialog('close');
                }
            },
            resize: function() {
                var div = $(this);
                var h = div.innerHeight()-32;
                var p = editor.$main.position();
                editor.$main.height(Math.floor(h-p['top']));
            }
        } );
    }

    this.noPosts = function() {
        $("#messagepane").text("No post found! :o");
    };

    this.hideAllReplyButtons = function() {
        $(".message-toolbar .reply-button").hide();
    };

    this.showAllReplyButtons = function() {
        $(".message-toolbar .reply-button").show();
    };

    this.hideAllDeleteButtons = function() {
        $(".message-toolbar .delete-button").hide();
    };

    this.showDeleteButtonsForUser = function(username) {
        $(".message-toolbar .delete-button.user-"+username).show();
    };

    $('#mappane').height($(window).height()*0.25);
    notepad.height($("#mappane").height());
    $("#messagepane").height( $(window).height() - $("#mappane").outerHeight() -8 );

    $('#mappane').resizable({
        containment: 'document',
        handles: 's'
    });

    $(window).resize( me.handleResize );
    $('#mappane').resize( me.handleResize );
    
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
        $(window).unbind('resize', me.handleResize);
    };
}

function BoardUI(delegate) 
{
    var odd=true;

    $('#view').children().remove();
    $('#view').append('<div id="board-banner"><h1 id="title" /><div id="description" /></div>');
    $('#view').append('<div id="thread-list"></div>');
    $('#thread-list').append('<div id="thread-list-toolbar"></div>');
    $('#thread-list-toolbar').append(
        $( '<button id="new-thread-button"><img src="images/newthread.png"> Create a new thread</button>' )
            .button().click(function() {
                showPost(delegate.currentBoard);
            }));
    $('#thread-list').append('<table id="thread-table"></table>');
    $('#thread-table').append('<thead><th class="subject">Subject</th><th>Replies</th><th>Last Post By</th></thead><tbody></tbody>');

    this.addThread = function (thread) {

        var started = new Date();
        started.setISO8601(thread.started);
        var newest = new Date();
        newest.setISO8601(thread.newest);
        $('#thread-table > tbody').append(
            '<tr' + (odd?' class="odd"':'') + '><td><a href="#!thread/' + 
            htmlSpecialChars(thread.id) + '"><div>' +
            htmlSpecialChars(thread.subject) + '</div></a></td><td>' + 
            htmlSpecialChars(thread.replies) + '</td><td>' +
            htmlSpecialChars(thread.newest_by) + ' (' +
            newest.format(en_GB_datef) + ')</td></tr>');
        $('#thread-table > tbody').append(
            '<tr class="byline ' + (odd?' odd':'') + '"><td colspan=3 ><small>' + 
            'Started by: ' + htmlSpecialChars(thread.started_by) + ' (' + 
            started.format(en_GB_datef) + ')</small></td></tr>');
        odd = !odd;
    };

    this.noThreads = function () {
        $('#thread-list').text('No threads have been posted to this board');
    };

    this.removeAllThreads = function() {
        $('#thread-table tbody tr').remove();
    };

    function postCallback (req) {
        if (req.status == 200) {
            $( '#post-dialog' ).dialog('close');
            delegate.reloadCurrentBoard();
        } else if (req.status == 403) {
            $('#post-form')
                .before('<div class="error" id="reply-form-error">You are not permitted to post here</div>');
        } else if (req.status == 404) {
            $('#reply-form')
                .before('<div class="error" id="reply-form-error">The board you are posting to no longer exists</div>');
        } else {
            $('#reply-form')
                .before('<div class="error" id="reply-form-error">An error occurred creating this thread</div>');
        }
    }

    function showPost(board_id) {
        if ($('#post-dialog').length !== 0 ) {
            return false;
        }
        function postBody() {
            return $("<div/>").html(
                $('#post-body-field').val()).text();
        }
        var editor;
        $('<div id="post-dialog">').load("panels/post.html", function () {
            editor = $('#post-body-field').cleditor({
                width: "100%",
                controls: "bold italic underline strikethrough | " +
                    "| bullets numbering " + "| undo redo | " +
                    "rule image link unlink | source"})[0];
        }).dialog( {
            resizable: true, 
            width: 640, 
            minHeight: 480,
            minWidth: 640,
            title: 'Create a New Thread',
            close: function() { 
                $(window).unbind( '.cleditor' ); 
                $( this ).remove();
            },
            buttons: {
                "Post": function() {
                    editor.updateTextArea();
                    $('#post-dialog div.error').remove();
                    $.ajax( {
                        url: 'board/'+encodeURIComponent(board_id)+'/post',
                        data: { 
                            subject: $('#post-subject-field').val(),
                            body: postBody(),
                            board: board_id
                        },
                        type: 'POST',
                        complete: postCallback
                    } );
                },
                "Cancel": function() {
                    $( this ).dialog('close');
                }
            },
            resize: function() {
                var div = $(this);
                var h = div.innerHeight()-32;
                var p = editor.$main.position();
                editor.$main.height(Math.floor(h-p['top']));
            }
        });
    }

    this.setTitle = function(title) {
        $('#board-banner #title').text(title);
    };

    this.setDescription = function(desc) {
        $('#board-banner #description').text(desc);
    };

    this.destroy = function() { };
}

/**
 * Constructor for an application controller object
 */
function Converse() 
{
    var me = this;
    var view;

    this.reloadCurrentThread = function() {
        me.loadPost(me.currentThread);
    };

    this.loadPost = function (post_id) {
        var modelCallback = function (data, textStatus, response) {
            var tmpDate;
            if (data.users) {
                view.addUsers(data.users);
            }
            if (data.subject) {
                document.title = data.subject + ' (Converse)';
            }
            if (data.posts && data.posts.length > 0) {
                _(data.posts).each(function(post) {
                    tmpDate = new Date();
                    tmpDate.setISO8601(post.date);
                    post.date = tmpDate;
                    view.addPost(post);
                });
                view.redrawTree(post_id);
                view.select(post_id);
            } else {
                view.noPosts();
            }
            me.didLogin();
        };
        var options = {
            url: "post/"+encodeURIComponent(post_id),
            success: modelCallback
        };
        $.ajax(options);
    };

    this.reloadCurrentBoard = function() {
        view.removeAllThreads();
        me.loadBoard(me.currentBoard);
    };

    this.loadBoard = function (board_id) {
        var modelCallback = function (data, textStatus, response) {
            if (data.title) {
                document.title = data.title + ' (Converse)';
                view.setTitle(data.title);
            }
            if (data.description) {
                view.setDescription(data.description);
            }
            if (data.threads)
            {
                _(data.threads).each(function(thread) {
                    view.addThread(thread);
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
    };

    var viewChangeCallback;

    this.setView = function(v) {
        if (view) { view.destroy(); }
        view = v;
        if (viewChangeCallback) {
            viewChangeCallback();
        }
    };

    this.setViewChangeCallback = function(fn) {
        viewChangeCallback = fn;
    };

    this.viewThread = function(root_id) {
        me.currentThread = root_id;
        // pass self to threadui as delegate
        me.setView(new ThreadUI(me));
        me.loadPost(root_id);
    };

    this.viewBoard = function(board_id) {
        if (!board_id) { board_id = 'main'; }

        me.currentBoard = board_id;
        // pass self to threadui as delegate
        me.setView(new BoardUI(me));
        me.loadBoard(board_id);
    };

    this.didLogin = function(data) {
        if (data) {
            me.loggedin = data.loggedin;
            me.username = data.username;
            me.rights = data.rights;
        }
        if (view instanceof ThreadUI) {
            view.hideAllDeleteButtons();
            if (me.loggedin) {
                view.showAllReplyButtons();
                view.showDeleteButtonsForUser(me.username);
            } else {
                view.hideAllReplyButtons();
            }
        }
    }
}

/**
 * Returns a JQuery object encapsulating a toolbar button
 *
 * id - a css identifier
 * image - path to the image to be used
 * caption - text label to be displayed under the image
 * onclick - callback function to be called when the button is clicked
 */
function toolbarButton(id, image, caption, onclick) 
{
    var button = $('<div />', {
        id: id,
        'class': 'toolbar-button'
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

/**
 * Create the toolbar div and add the apprpriate buttons
 */
function loadToolbar(loginInfo) 
{
    $('#toolbar div').remove();
    var toolbar = $('#toolbar');
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

/**
 * Called by the browser on completion of a user add request
 */
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

/**
 * Show the user add dialogue
 */
function showAddUser() 
{
    if ($('#user-dialog').length !== 0 ) {
        return false;
    }
    function doAddUser() {
        $('#user-form-error').remove();
        $.ajax( {
            url: 'user/'+encodeURIComponent($('#user-username-field').val()), 
            data: { password: $('#user-password-field').val() },
            type: 'PUT',
            complete: addUserCallback
        } );
    }
    $('<div id="user-dialog">').load("panels/user.html", function() {
        $('#user-form').keypress(function(e){
            if ((e.which && e.which == 13) || (e.keyCode && e.keyCode == 13)) {
                e.preventDefault();
                doAddUser();
            }
        });
        $('#user-username-field')[0].focus();
    }).dialog( {
        resizable: false, 
        width: 350, 
        title: 'Create User',
        close: function() { $( this ).remove(); },
        buttons: {
            "Register": function() {
                doAddUser();
            },
            "Cancel": function() {
                $( this ).remove();
            }
        }
    } );
}

/**
 * Show the user edit dialogue
 */
function showEditUser() 
{
    if ($('#edituser-dialog').length !== 0 ) { 
        return false;
    }
    var reloadAvatars = function () {
                $(".avatar.user-"+converse.username).each(function() {
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
        close: function() { $( this ).remove(); }
    } );
}

/**
 * Called by the browser on completion of the log in request
 */
function loginCallback(data, statusText, req, error) 
{
    if (req.status == 200) {
        $( '#login-dialog' ).remove();
        loadToolbar(data);
        converse.didLogin(data);
    } else if (req.status == 403) {
        $('#login-form')
            .before('<div class="error" id="login-form-error">An incorrect username or password has been supplied</div>');
    } else {
        $('#login-form')
            .before('<div class="error" id="login-form-error">A problem has occurred logging in</div>');
    }
}

/**
 * Show the log in dialogue
 */
function showLogin() 
{
    if ($('#login-dialog').length !== 0 ) {
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
            }
        });
    }
    $('<div id="login-dialog">').load("panels/login.html", function() {
        $('#login-form').keypress(function(e){
            if ((e.which && e.which == 13) || (e.keyCode && e.keyCode == 13)) {
                e.preventDefault();
                doLogin();
            }
        });
        $('#login-username-field')[0].focus();
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

/**
 * Show the log out confirmation dialogue
 */
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
                        converse.didLogin(data);
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

/**
 *  Perform initial setup of application
 */
$(window.document).ready( function() {

    // mapping of functions to fragment routes
    var routes = {
        board: converse.viewBoard,
        thread: converse.viewThread,
        'default': converse.viewBoard
    };

    // On change of url fragment, load the apprpriate route
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

    // Ask the server if we are logged in, 
    // load the appropriate toolbar
    // evaluate the route for the current fragment
    $.get('loggedin', function(data) {
        loadToolbar(data);
        converse.didLogin(data);
        $(window).trigger( 'hashchange' );
    });
});

})(window);
