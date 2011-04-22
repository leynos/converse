require 'couchrest_extended_document'

class Post < CouchRest::ExtendedDocument

    property :subject,  String
    property :date,     Time
    property :author
    property :path,     [String]
    property :body

    view_by  :author, :date

    # simple list of threads.  We'll improve on this later
    view_by  :thread,
        :map => "function(doc) {
            if (doc['couchrest-type'] == 'Post') 
            {
                if (doc.path.length == 0)
                {
                    emit(doc._id, {
                        id: doc._id, 
                        subject: doc.subject, 
                        author: doc.author, 
                        date: doc.date
                    });
                }
            }
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

    def setParent(parent)
        # Inherit the parent's path
        self.path = parent.path + [parent.id]
    end

end
