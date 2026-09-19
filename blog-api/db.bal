// Postgres persistence for posts and comments. The client and schema are
// created at module load with sensible fallbacks so the service boots with
// no BLOG_DB_* env vars set at all; an actual query only fails at call time,
// which is expected when the database is not reachable yet.
import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerina/uuid;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

type PostRow record {|
    string id;
    string title;
    string body;
    time:Utc createdAt;
|};

type CommentRow record {|
    string id;
    string postId;
    string authorName;
    string body;
    time:Utc createdAt;
|};

function resolvedDbHost() returns string {
    return dbHost == "" ? "localhost" : dbHost;
}

function resolvedDbPort() returns int {
    if dbPort == "" {
        return 5432;
    }
    int|error parsed = int:fromString(dbPort);
    return parsed is int ? parsed : 5432;
}

function resolvedDbName() returns string {
    return dbName == "" ? "blog" : dbName;
}

function resolvedDbUser() returns string {
    return dbUser == "" ? "postgres" : dbUser;
}

function resolvedDbPassword() returns string? {
    return dbPassword == "" ? () : dbPassword;
}

// A plain (non-`check`) module-level init: a connection failure becomes an
// `error` value stored here rather than a panic that stops the process from
// booting. Every query function below narrows this before use and surfaces
// the failure only when a caller actually asks for data.
final postgresql:Client|error dbClient = new (
    host = resolvedDbHost(),
    username = resolvedDbUser(),
    password = resolvedDbPassword(),
    database = resolvedDbName(),
    port = resolvedDbPort()
);

final boolean dbSchemaReady = initSchema();

function initSchema() returns boolean {
    postgresql:Client|error pgClientResult = dbClient;
    if pgClientResult is error {
        log:printWarn("blog-db not reachable at startup; schema will be attempted again on first query",
                'error = pgClientResult);
        return false;
    }
    postgresql:Client pgClient = pgClientResult;
    sql:ExecutionResult|error posts = pgClient->execute(`
        CREATE TABLE IF NOT EXISTS posts (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            created_at TIMESTAMPTZ NOT NULL
        )
    `);
    if posts is error {
        log:printWarn("failed to create posts table", 'error = posts);
        return false;
    }
    sql:ExecutionResult|error comments = pgClient->execute(`
        CREATE TABLE IF NOT EXISTS comments (
            id TEXT PRIMARY KEY,
            post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
            author_name TEXT NOT NULL,
            body TEXT NOT NULL,
            created_at TIMESTAMPTZ NOT NULL
        )
    `);
    if comments is error {
        log:printWarn("failed to create comments table", 'error = comments);
        return false;
    }
    return true;
}

function toPost(PostRow row) returns Post => {
    id: row.id,
    title: row.title,
    body: row.body,
    createdAt: time:utcToString(row.createdAt)
};

function toComment(CommentRow row) returns Comment => {
    id: row.id,
    postId: row.postId,
    authorName: row.authorName,
    body: row.body,
    createdAt: time:utcToString(row.createdAt)
};

function countPosts() returns int|error {
    postgresql:Client pgClient = check dbClient;
    record {| int count; |} result = check pgClient->queryRow(`SELECT COUNT(*)::int AS count FROM posts`);
    return result.count;
}

function listPostsPage(int pageLimit, int pageOffset) returns PostRow[]|error {
    postgresql:Client pgClient = check dbClient;
    stream<PostRow, sql:Error?> rowStream = pgClient->query(`
        SELECT id, title, body, created_at AS "createdAt"
        FROM posts
        ORDER BY created_at DESC
        LIMIT ${pageLimit} OFFSET ${pageOffset}
    `);
    PostRow[] rows = [];
    check from PostRow row in rowStream
        do {
            rows.push(row);
        };
    return rows;
}

function findPost(string postId) returns PostRow?|error {
    postgresql:Client pgClient = check dbClient;
    PostRow|sql:Error result = pgClient->queryRow(`
        SELECT id, title, body, created_at AS "createdAt" FROM posts WHERE id = ${postId}
    `);
    if result is sql:NoRowsError {
        return ();
    }
    if result is sql:Error {
        return result;
    }
    return result;
}

function insertPost(string title, string body) returns PostRow|error {
    postgresql:Client pgClient = check dbClient;
    string id = uuid:createRandomUuid();
    time:Utc createdAt = time:utcNow();
    sql:ExecutionResult _ = check pgClient->execute(`
        INSERT INTO posts (id, title, body, created_at) VALUES (${id}, ${title}, ${body}, ${createdAt})
    `);
    return {id, title, body, createdAt};
}

function updatePostRow(string postId, string title, string body) returns PostRow?|error {
    postgresql:Client pgClient = check dbClient;
    sql:ExecutionResult result = check pgClient->execute(`
        UPDATE posts SET title = ${title}, body = ${body} WHERE id = ${postId}
    `);
    if result.affectedRowCount == 0 {
        return ();
    }
    return findPost(postId);
}

function deletePostRow(string postId) returns boolean|error {
    postgresql:Client pgClient = check dbClient;
    sql:ExecutionResult result = check pgClient->execute(`DELETE FROM posts WHERE id = ${postId}`);
    return result.affectedRowCount > 0;
}

function countComments(string postId) returns int|error {
    postgresql:Client pgClient = check dbClient;
    record {| int count; |} result = check pgClient->queryRow(`
        SELECT COUNT(*)::int AS count FROM comments WHERE post_id = ${postId}
    `);
    return result.count;
}

function listCommentsPage(string postId, int pageLimit, int pageOffset) returns CommentRow[]|error {
    postgresql:Client pgClient = check dbClient;
    stream<CommentRow, sql:Error?> rowStream = pgClient->query(`
        SELECT id, post_id AS "postId", author_name AS "authorName", body, created_at AS "createdAt"
        FROM comments
        WHERE post_id = ${postId}
        ORDER BY created_at ASC
        LIMIT ${pageLimit} OFFSET ${pageOffset}
    `);
    CommentRow[] rows = [];
    check from CommentRow row in rowStream
        do {
            rows.push(row);
        };
    return rows;
}

function insertComment(string postId, string authorName, string body) returns CommentRow|error {
    postgresql:Client pgClient = check dbClient;
    string id = uuid:createRandomUuid();
    time:Utc createdAt = time:utcNow();
    sql:ExecutionResult _ = check pgClient->execute(`
        INSERT INTO comments (id, post_id, author_name, body, created_at)
        VALUES (${id}, ${postId}, ${authorName}, ${body}, ${createdAt})
    `);
    return {id, postId, authorName, body, createdAt};
}

function deleteCommentRow(string postId, string commentId) returns boolean|error {
    postgresql:Client pgClient = check dbClient;
    sql:ExecutionResult result = check pgClient->execute(`
        DELETE FROM comments WHERE id = ${commentId} AND post_id = ${postId}
    `);
    return result.affectedRowCount > 0;
}
