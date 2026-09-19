# simplest-crud-blog — PRD

## Problem Statement

Small teams that want to publish a simple blog have no lightweight way to do
it without adopting a full CMS. They need one place to write and manage posts,
and one place for readers to see them and react, without extra infrastructure
or third-party services to wire up.

## Solution

A minimal two-app blog: a guest-facing web app for signed-in readers to browse
posts and leave comments, and an admin web app for a single admin to create,
edit and delete posts. Both apps authenticate through the same shared identity
provider, and the system makes no calls to any outside service.

## Actors

- **Guest**: a signed-in reader who browses published posts, reads them, and
leaves comments.
- **Admin**: the single administrator who creates, edits and deletes posts,
and can remove comments.

## User Stories

1. As a guest, I want to sign in through the shared identity provider, so that
 I can access the blog.
2. As a guest, I want to see a list of published posts, so that I can browse
 what's available.
3. As a guest, I want to open a post and read its full content, so that I can
 consume it.
4. As a guest, I want to see the comments on a post, so that I can read the
 discussion around it.
5. As a guest, I want to add a comment to a post, so that I can share my
 thoughts.
6. As an admin, I want to sign in through the shared identity provider, so
 that I can manage the blog.
7. As an admin, I want to create a new post, so that I can publish content.
8. As an admin, I want to edit an existing post, so that I can correct or
 update it.
9. As an admin, I want to delete a post, so that I can remove content that no
 longer belongs on the blog.
10. As an admin, I want to see all posts in one place, so that I can manage
 the blog's content.
11. As an admin, I want to remove a comment, so that I can moderate content
 guests have left.

## Product Decisions

- **Sign-in**: both the guest app and the admin app authenticate through
Thunder, the platform's shared identity provider — no separate accounts per
app.
- **No external integrations**: the system makes no calls to any third-party
or outside API; everything the blog needs is handled within the two apps
and their own data.
- **Admin model**: a single, flat admin role manages all posts — there is no
per-author ownership or multiple admin accounts. *assumed*
- **Post model**: a post has a title and body only, and is visible to guests
as soon as it is created — there is no draft/published state or scheduling.
*assumed*
- **Comments**: a signed-in guest can add a comment to a post, identified by
their signed-in identity; guests cannot edit or delete their own comments
once posted — only the admin can remove a comment. *assumed*

## Out of Scope

- Post categories, tags, or search.
- Likes, reactions, or comment replies/threading.
- Rich media uploads (images, attachments) in posts or comments.
- Draft/publish workflow or scheduled posts.
- Email or other notifications.
- Multiple admin accounts or per-author permissions.
- Guests editing or deleting their own comments.

## Open Questions

None outstanding.

## Further Notes

None.