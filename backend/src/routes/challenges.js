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

function decorateChallenge(challenge, userId) {
  const participants = db.prepare(`
    SELECT cp.*, u.first_name, u.last_name
    FROM challenge_participants cp
    JOIN users u ON u.id = cp.user_id
    WHERE cp.challenge_id = ?
    ORDER BY cp.progress DESC
  `).all(challenge.id);

  const myParticipation = participants.find((p) => p.user_id === userId);

  return {
    id: challenge.id,
    title: challenge.title,
    goalType: challenge.goal_type,
    goalTarget: challenge.goal_target,
    startDate: challenge.start_date,
    endDate: challenge.end_date,
    creator: { id: challenge.creator_id },
    isJoined: !!myParticipation,
    myProgress: myParticipation ? myParticipation.progress : 0,
    myCompleted: myParticipation ? !!myParticipation.completed : false,
    participants: participants.map((p) => ({
      userId: p.user_id,
      displayName: `${p.first_name} ${p.last_name}`,
      progress: p.progress,
      completed: !!p.completed,
    })),
  };
}

router.post('/', (req, res) => {
  const { title, goalType, goalTarget, durationDays } = req.body;

  if (!title || !goalType || !goalTarget || !durationDays) {
    return res.status(400).json({ error: 'title, goalType, goalTarget, and durationDays are required' });
  }
  if (!['workout_count', 'volume_kg'].includes(goalType)) {
    return res.status(400).json({ error: 'goalType must be workout_count or volume_kg' });
  }

  const startDate = new Date().toISOString();
  const endDate = new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000).toISOString();

  const result = db.prepare(`
    INSERT INTO challenges (creator_id, title, goal_type, goal_target, start_date, end_date)
    VALUES (?, ?, ?, ?, ?, ?)
  `).run(req.userId, title.trim(), goalType, goalTarget, startDate, endDate);

  db.prepare('INSERT INTO challenge_participants (challenge_id, user_id) VALUES (?, ?)')
    .run(result.lastInsertRowid, req.userId);

  const challenge = db.prepare('SELECT * FROM challenges WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json({ challenge: decorateChallenge(challenge, req.userId) });
});

// Challenges you've joined.
router.get('/mine', (req, res) => {
  const rows = db.prepare(`
    SELECT c.* FROM challenges c
    JOIN challenge_participants cp ON cp.challenge_id = c.id
    WHERE cp.user_id = ?
    ORDER BY c.end_date ASC
  `).all(req.userId);

  res.json({ challenges: rows.map((c) => decorateChallenge(c, req.userId)) });
});

// Challenges created by friends that you haven't joined yet.
router.get('/available', (req, res) => {
  const ids = friendIds(req.userId);
  if (ids.length === 0) return res.json({ challenges: [] });
  const placeholders = ids.map(() => '?').join(',');

  const rows = db.prepare(`
    SELECT c.* FROM challenges c
    WHERE c.creator_id IN (${placeholders})
      AND c.end_date > datetime('now')
      AND c.id NOT IN (SELECT challenge_id FROM challenge_participants WHERE user_id = ?)
    ORDER BY c.created_at DESC
  `).all(...ids, req.userId);

  res.json({ challenges: rows.map((c) => decorateChallenge(c, req.userId)) });
});

router.post('/:id/join', (req, res) => {
  const challengeId = Number(req.params.id);
  const challenge = db.prepare('SELECT * FROM challenges WHERE id = ?').get(challengeId);
  if (!challenge) return res.status(404).json({ error: 'Challenge not found' });

  const existing = db.prepare('SELECT id FROM challenge_participants WHERE challenge_id = ? AND user_id = ?')
    .get(challengeId, req.userId);
  if (existing) return res.status(409).json({ error: 'Already joined' });

  db.prepare('INSERT INTO challenge_participants (challenge_id, user_id) VALUES (?, ?)')
    .run(challengeId, req.userId);

  res.status(201).json({ challenge: decorateChallenge(challenge, req.userId) });
});

router.post('/:id/progress', (req, res) => {
  const challengeId = Number(req.params.id);
  const { progress } = req.body;
  if (typeof progress !== 'number') return res.status(400).json({ error: 'progress must be a number' });

  const challenge = db.prepare('SELECT * FROM challenges WHERE id = ?').get(challengeId);
  if (!challenge) return res.status(404).json({ error: 'Challenge not found' });

  const participant = db.prepare('SELECT * FROM challenge_participants WHERE challenge_id = ? AND user_id = ?')
    .get(challengeId, req.userId);
  if (!participant) return res.status(403).json({ error: 'Not a participant of this challenge' });

  const completed = progress >= challenge.goal_target ? 1 : 0;
  db.prepare('UPDATE challenge_participants SET progress = ?, completed = ? WHERE id = ?')
    .run(progress, completed, participant.id);

  res.json({ challenge: decorateChallenge(challenge, req.userId) });
});

router.get('/:id', (req, res) => {
  const challengeId = Number(req.params.id);
  const challenge = db.prepare('SELECT * FROM challenges WHERE id = ?').get(challengeId);
  if (!challenge) return res.status(404).json({ error: 'Challenge not found' });
  res.json({ challenge: decorateChallenge(challenge, req.userId) });
});

module.exports = router;
