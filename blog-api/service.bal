// Generated from specs/design/components/blog-api/openapi.yaml, then filled
// in by hand. The gateway has already checked each operation's scope before
// forwarding (api-management, thunder-authentication); this service verifies
// the gateway's signed assertion and resolves who the caller is.

import ballerina/http;

listener http:Listener ep0 = new (9090);

service http:InterceptableService / on ep0 {

    public function createInterceptors() returns AssertionInterceptor => new;

    # Delete a post
    #
    # + return - returns can be any of following types
    # http:NoContent (Post deleted)
    # http:NotFound (No such post)
    # http:Unauthorized (Not signed in)
    # http:Forbidden (Missing the required scope)
    resource function delete posts/[string postId](http:RequestContext ctx)
            returns http:NoContent|ErrorNotFound|ErrorUnauthorized|ErrorForbidden|error {
        GatewayCaller|http:Unauthorized callerResult = requireGatewayCaller(ctx);
        if callerResult is http:Unauthorized {
            return unauthorizedError();
        }
        boolean deleted = check deletePostRow(postId);
        if !deleted {
            return notFoundError("No such post");
        }
        return http:NO_CONTENT;
    }

    # Remove any comment
    #
    # + return - returns can be any of following types
    # http:NoContent (Comment deleted)
    # http:NotFound (No such comment)
    # http:Unauthorized (Not signed in)
    # http:Forbidden (Missing the required scope)
    resource function delete posts/[string postId]/comments/[string commentId](http:RequestContext ctx)
            returns http:NoContent|ErrorNotFound|ErrorUnauthorized|ErrorForbidden|error {
        GatewayCaller|http:Unauthorized callerResult = requireGatewayCaller(ctx);
        if callerResult is http:Unauthorized {
            return unauthorizedError();
        }
        boolean deleted = check deleteCommentRow(postId, commentId);
        if !deleted {
            return notFoundError("No such comment");
        }
        return http:NO_CONTENT;
    }

    # Every published post
    #
    # + return - returns can be any of following types
    # http:Ok (A page of posts)
    # http:Unauthorized (Not signed in)
    resource function get posts(http:RequestContext ctx, int 'limit = 20, int offset = 0)
            returns inline_response_200|ErrorUnauthorized|error {
        GatewayCaller|http:Unauthorized callerResult = requireGatewayCaller(ctx);
        if callerResult is http:Unauthorized {
            return unauthorizedError();
        }
        int pageLimit = clampLimit('limit);
        int pageOffset = clampOffset(offset);
        int total = check countPosts();
        PostRow[] rows = check listPostsPage(pageLimit, pageOffset);
        Post[] posts = from PostRow row in rows select toPost(row);
        return {
            count: total,
            next: nextUri("/posts", pageLimit, pageOffset, total),
            previous: previousUri("/posts", pageLimit, pageOffset),
            data: posts
        };
    }

    # A single post
    #
    # + return - returns can be any of following types
    # http:Ok (The post)
    # http:NotFound (No such post)
    # http:Unauthorized (Not signed in)
    resource function get posts/[string postId](http:RequestContext ctx)
            returns Post|ErrorNotFound|ErrorUnauthorized|error {
        GatewayCaller|http:Unauthorized callerResult = requireGatewayCaller(ctx);
        if callerResult is http:Unauthorized {
            return unauthorizedError();
        }
        PostRow? row = check findPost(postId);
        if row is () {
            return notFoundError("No such post");
        }
        return toPost(row);
    }

    # Every comment on a post
    #
    # + return - returns can be any of following types
    # http:Ok (A page of comments)
    # http:NotFound (No such post)
    # http:Unauthorized (Not signed in)
    resource function get posts/[string postId]/comments(http:RequestContext ctx, int 'limit = 20, int offset = 0)
            returns inline_response_200_1|ErrorNotFound|ErrorUnauthorized|error {
        GatewayCaller|http:Unauthorized callerResult = requireGatewayCaller(ctx);
        if callerResult is http:Unauthorized {
            return unauthorizedError();
        }
        PostRow? post = check findPost(postId);
        if post is () {
            return notFoundError("No such post");
        }
        int pageLimit = clampLimit('limit);
        int pageOffset = clampOffset(offset);
        int total = check countComments(postId);
        CommentRow[] rows = check listCommentsPage(postId, pageLimit, pageOffset);
        Comment[] comments = from CommentRow row in rows select toComment(row);
        string basePath = string `/posts/${postId}/comments`;
        return {
            count: total,
            next: nextUri(basePath, pageLimit, pageOffset, total),
            previous: previousUri(basePath, pageLimit, pageOffset),
            data: comments
        };
    }

    # Create a new post
    #
    # + return - returns can be any of following types
    # http:Created (Post created)
    # http:BadRequest (Invalid post)
    # http:Unauthorized (Not signed in)
    # http:Forbidden (Missing the required scope)
    resource function post posts(http:RequestContext ctx, @http:Payload PostInput payload)
            returns Post|ErrorBadRequest|ErrorUnauthorized|ErrorForbidden|error {
        GatewayCaller|http:Unauthorized callerResult = requireGatewayCaller(ctx);
        if callerResult is http:Unauthorized {
            return unauthorizedError();
        }
        if !validPostInput(payload) {
            return badRequestError("title and body are required");
        }
        PostRow row = check insertPost(payload.title, payload.body);
        return toPost(row);
    }

    # Add a comment to a post
    #
    # + return - returns can be any of following types
    # http:Created (Comment created)
    # http:BadRequest (Invalid comment)
    # http:NotFound (No such post)
    # http:Unauthorized (Not signed in)
    # http:Forbidden (Missing the required scope)
    resource function post posts/[string postId]/comments(http:RequestContext ctx, @http:Payload CommentInput payload)
            returns Comment|ErrorBadRequest|ErrorNotFound|ErrorUnauthorized|ErrorForbidden|error {
        GatewayCaller|http:Unauthorized callerResult = requireGatewayCaller(ctx);
        if callerResult is http:Unauthorized {
            return unauthorizedError();
        }
        GatewayCaller caller = callerResult;
        if payload.body.trim() == "" {
            return badRequestError("body is required");
        }
        PostRow? post = check findPost(postId);
        if post is () {
            return notFoundError("No such post");
        }
        string|http:InternalServerError authorNameResult = requireCallerUsername(caller);
        if authorNameResult is http:InternalServerError {
            return error("gateway assertion carries no identity to stamp as the comment author");
        }
        CommentRow row = check insertComment(postId, authorNameResult, payload.body);
        return toComment(row);
    }

    # Edit an existing post
    #
    # + return - returns can be any of following types
    # http:Ok (Post updated)
    # http:BadRequest (Invalid post)
    # http:NotFound (No such post)
    # http:Unauthorized (Not signed in)
    # http:Forbidden (Missing the required scope)
    resource function put posts/[string postId](http:RequestContext ctx, @http:Payload PostInput payload)
            returns Post|ErrorBadRequest|ErrorNotFound|ErrorUnauthorized|ErrorForbidden|error {
        GatewayCaller|http:Unauthorized callerResult = requireGatewayCaller(ctx);
        if callerResult is http:Unauthorized {
            return unauthorizedError();
        }
        if !validPostInput(payload) {
            return badRequestError("title and body are required");
        }
        PostRow? row = check updatePostRow(postId, payload.title, payload.body);
        if row is () {
            return notFoundError("No such post");
        }
        return toPost(row);
    }
}

public type Comment record {
    string id;
    string postId;
    string authorName;
    string body;
    string createdAt;
};

public type ErrorNotFound record {|
    *http:NotFound;
    Error body;
|};

public type CommentInput record {
    string body;
};

public type Post record {
    string id;
    string title;
    string body;
    string createdAt;
};

public type PostInput record {
    string title;
    string body;
};

public type inline_response_200_1 record {
    # total matching items
    int count;
    # relative URI of the next page
    string? next?;
    # relative URI of the previous page
    string? previous?;
    Comment[] data;
};

public type inline_response_200 record {
    # total matching items
    int count;
    # relative URI of the next page
    string? next?;
    # relative URI of the previous page
    string? previous?;
    Post[] data;
};

public type Error record {
    # HTTP or application error code
    int code;
    # short human-readable label
    string message;
    # detailed explanation
    string description?;
    # URI to documentation
    string moreInfo?;
};

public type ErrorBadRequest record {|
    *http:BadRequest;
    Error body;
|};

public type ErrorForbidden record {|
    *http:Forbidden;
    Error body;
|};

public type ErrorUnauthorized record {|
    *http:Unauthorized;
    Error body;
|};
