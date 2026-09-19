screen PostList "Browse published posts"
  navbar "Simplest Blog"
  heading "Latest Posts"
  list "First Post -> PostDetail | Second Post -> PostDetail | Third Post -> PostDetail"

screen PostDetail "Read a post and its comments"
  navbar "Simplest Blog"
  breadcrumb "Posts / Post Detail"
  heading "Post Title"
  text "Full body text of the post goes here."
  divider
  heading "Comments"
  list "Jane Doe: Great read! | John Smith: Thanks for sharing"
  textarea "Write a comment..."
  button "Add Comment" primary

flow "Browse and comment"
  role "Guest"
  description "A signed-in guest browses posts, reads one, and leaves a comment"
  PostList
  PostDetail
