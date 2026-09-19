screen PostManager "See and manage every post"
  navbar "Blog Admin"
  row
    heading "Posts"
    right
    button "New Post" primary -> PostForm
  table "Title | Created | Actions" -> CommentModeration
    row "First Post | 2026-09-01 | Edit -> PostForm, Delete, Comments"
    row "Second Post | 2026-09-05 | Edit -> PostForm, Delete, Comments"

screen PostForm "Create or edit a post"
  navbar "Blog Admin"
  breadcrumb "Posts / Post Form"
  heading "Post"
  input "Title"
  textarea "Body"
  row
    button "Cancel" -> PostManager
    right
    button "Save" primary -> PostManager

screen CommentModeration "Moderate comments on a post"
  navbar "Blog Admin"
  breadcrumb "Posts / Comments"
  heading "Comments"
  table "Author | Comment | Actions"
    row "Jane Doe | Great read! | Delete"
    row "John Smith | Thanks for sharing | Delete"

flow "Manage posts and moderate comments"
  role "Admin"
  description "The admin creates, edits and deletes posts, and removes comments"
  PostManager
  PostForm
  CommentModeration
