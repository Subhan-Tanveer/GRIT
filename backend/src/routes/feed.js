const express = require('express');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

function friendIds(userId) {
  const rows = db.prepare(`
    SELECT CASE WHEN requester_id = ? THEN recipient_id ELSE requester_id END as friend_id
    FROM friendships
    WHERE (requester_id = ? OR recipient_id = ?) AND status = 'accepted'
  `).all(userId, userId, userId);
  return rows.map((r) => r.friend_id);
}

function decoratePost(post, userId) {
  const likeCount = db.prepare('SELECT COUNT(*) as count FROM post_likes WHERE post_id = ?').get(post.id).count;
  const commentCount = db.prepare('SELECT COUNT(*) as count FROM post_comments WHERE post_id = ?').get(post.id).count;
  const likedByMe = !!db.prepare('SELECT 1 FROM post_likes WHERE post_id = ? AND user_id = ?').get(post.id, userId);

  return {
    id: post.id,
    content: post.content,
    postType: post.post_type,
    createdAt: post.created_at,
    author: { id: post.user_id, firstName: post.first_name, lastName: post.last_name, email: post.email },
    likeCount,
    commentCount,
    likedByMe,
  };
}

// Feed: your own posts + accepted friends' posts.
router.get('/', (req, res) => {
  const ids = [req.userId, ...friendIds(req.userId)];
  const placeholders = ids.map(() => '?').join(',');

  const rows = db.prepare(`
    SELECT p.*, u.first_name, u.last_name, u.email
    FROM posts p
    JOIN users u ON u.id = p.user_id
    WHERE p.user_id IN (${placeholders})
    ORDER BY p.created_at DESC
    LIMIT 50
  `).all(...ids);

  res.json({ posts: rows.map((r) => decoratePost(r, req.userId)) });
});

router.post('/posts', (req, res) => {
  const { content, postType } = req.body;
  if (!content || !content.trim()) return res.status(400).json({ error: 'content is required' });

  const result = db.prepare('INSERT INTO posts (user_id, content, post_type) VALUES (?, ?, ?)')
    .run(req.userId, content.trim(), postType || 'general');

  const row = db.prepare(`
    SELECT p.*, u.first_name, u.last_name, u.email FROM posts p JOIN users u ON u.id = p.user_id WHERE p.id = ?
  `).get(result.lastInsertRowid);

  res.status(201).json({ post: decoratePost(row, req.userId) });
});

router.delete('/posts/:id', (req, res) => {
  const postId = Number(req.params.id);
  const post = db.prepare('SELECT * FROM posts WHERE id = ?').get(postId);
  if (!post) return res.status(404).json({ error: 'Post not found' });
  if (post.user_id !== req.userId) return res.status(403).json({ error: 'Not your post' });

  db.prepare('DELETE FROM posts WHERE id = ?').run(postId);
  res.json({ message: 'Post deleted' });
});

// Toggle like.
router.post('/posts/:id/like', (req, res) => {
  const postId = Number(req.params.id);
  const post = db.prepare('SELECT id FROM posts WHERE id = ?').get(postId);
  if (!post) return res.status(404).json({ error: 'Post not found' });

  const existing = db.prepare('SELECT id FROM post_likes WHERE post_id = ? AND user_id = ?')
    .get(postId, req.userId);

  if (existing) {
    db.prepare('DELETE FROM post_likes WHERE id = ?').run(existing.id);
    res.json({ liked: false });
  } else {
    db.prepare('INSERT INTO post_likes (post_id, user_id) VALUES (?, ?)').run(postId, req.userId);
    res.json({ liked: true });
  }
});

router.get('/posts/:id/comments', (req, res) => {
  const postId = Number(req.params.id);
  const rows = db.prepare(`
    SELECT c.*, u.first_name, u.last_name, u.email
    FROM post_comments c
    JOIN users u ON u.id = c.user_id
    WHERE c.post_id = ?
    ORDER BY c.created_at ASC
  `).all(postId);

  res.json({
    comments: rows.map((c) => ({
      id: c.id,
      content: c.content,
      createdAt: c.created_at,
      author: { id: c.user_id, firstName: c.first_name, lastName: c.last_name, email: c.email },
    })),
  });
});

router.post('/posts/:id/comments', (req, res) => {
  const postId = Number(req.params.id);
  const { content } = req.body;
  if (!content || !content.trim()) return res.status(400).json({ error: 'content is required' });

  const post = db.prepare('SELECT id FROM posts WHERE id = ?').get(postId);
  if (!post) return res.status(404).json({ error: 'Post not found' });

  const result = db.prepare('INSERT INTO post_comments (post_id, user_id, content) VALUES (?, ?, ?)')
    .run(postId, req.userId, content.trim());

  const row = db.prepare(`
    SELECT c.*, u.first_name, u.last_name, u.email FROM post_comments c JOIN users u ON u.id = c.user_id WHERE c.id = ?
  `).get(result.lastInsertRowid);

  res.status(201).json({
    comment: {
      id: row.id,
      content: row.content,
      createdAt: row.created_at,
      author: { id: row.user_id, firstName: row.first_name, lastName: row.last_name, email: row.email },
    },
  });
});

module.exports = router;
