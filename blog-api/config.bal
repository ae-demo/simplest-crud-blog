// Config read from environment variables, in one place. Every value defaults
// to "" when the platform has not injected it yet; db.bal applies the
// sensible localhost/default-port fallback so the service still boots.
import ballerina/os;

configurable string dbHost = os:getEnv("BLOG_DB_HOST");
configurable string dbPort = os:getEnv("BLOG_DB_PORT");
configurable string dbName = os:getEnv("BLOG_DB_DBNAME");
configurable string dbUser = os:getEnv("BLOG_DB_USER");
configurable string dbPassword = os:getEnv("BLOG_DB_PASSWORD");
