const express = require('express');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

function publicUser(user) {
  return { id: user.id, firstName: user.first_name, lastName: user.last_name, email: user.email };
}

// Send a friend request by email.
router.post('/request', (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ error: 'email is required' });

  const normalizedEmail = email.trim().toLowerCase();
  const recipient = db.prepare('SELECT * FROM users WHERE email = ?').get(normalizedEmail);
  if (!recipient) return res.status(404).json({ error: 'No account found with that email' });
  if (recipient.id === req.userId) return res.status(400).json({ error: "You can't friend yourself" });

  const existing = db.prepare(`
    SELECT * FROM friendships
    WHERE (requester_id = ? AND recipient_id = ?) OR (requester_id = ? AND recipient_id = ?)
  `).get(req.userId, recipient.id, recipient.id, req.userId);

  if (existing) {
    return res.status(409).json({ error: `Friendship already ${existing.status}` });
  }

  db.prepare('INSERT INTO friendships (requester_id, recipient_id, status) VALUES (?, ?, ?)')
    .run(req.userId, recipient.id, 'pending');

  res.status(201).json({ message: 'Friend request sent' });
});

// Incoming pending requests.
router.get('/requests', (req, res) => {
  const rows = db.prepare(`
    SELECT f.id as request_id, u.id, u.first_name, u.last_name, u.email
    FROM friendships f
    JOIN users u ON u.id = f.requester_id
    WHERE f.recipient_id = ? AND f.status = 'pending'
    ORDER BY f.created_at DESC
  `).all(req.userId);

  res.json({
    requests: rows.map((r) => ({
      requestId: r.request_id,
      user: { id: r.id, firstName: r.first_name, lastName: r.last_name, email: r.email },
    })),
  });
});

router.post('/:requestId/accept', (req, res) => {
  const requestId = Number(req.params.requestId);
  const request = db.prepare('SELECT * FROM friendships WHERE id = ? AND recipient_id = ?')
    .get(requestId, req.userId);

  if (!request) return res.status(404).json({ error: 'Friend request not found' });

  db.prepare("UPDATE friendships SET status = 'accepted' WHERE id = ?").run(requestId);
  res.json({ message: 'Friend request accepted' });
});

router.post('/:requestId/decline', (req, res) => {
  const requestId = Number(req.params.requestId);
  const request = db.prepare('SELECT * FROM friendships WHERE id = ? AND recipient_id = ?')
    .get(requestId, req.userId);

  if (!request) return res.status(404).json({ error: 'Friend request not found' });

  db.prepare("UPDATE friendships SET status = 'declined' WHERE id = ?").run(requestId);
  res.json({ message: 'Friend request declined' });
});

// Accepted friends list.
router.get('/', (req, res) => {
  const rows = db.prepare(`
    SELECT u.id, u.first_name, u.last_name, u.email
    FROM friendships f
    JOIN users u ON u.id = CASE WHEN f.requester_id = ? THEN f.recipient_id ELSE f.requester_id END
    WHERE (f.requester_id = ? OR f.recipient_id = ?) AND f.status = 'accepted'
    ORDER BY u.first_name ASC
  `).all(req.userId, req.userId, req.userId);

  res.json({ friends: rows.map(publicUser) });
});

module.exports = router;
