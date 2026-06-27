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

// Push this device's current local stats up to the backend so friends can
// see them. Called whenever the app's gamification data changes.
router.post('/sync', (req, res) => {
  const { gritScore, streak, totalVolumeKg, totalWorkouts } = req.body;

  if (
    typeof gritScore !== 'number' ||
    typeof streak !== 'number' ||
    typeof totalVolumeKg !== 'number' ||
    typeof totalWorkouts !== 'number'
  ) {
    return res.status(400).json({ error: 'gritScore, streak, totalVolumeKg, and totalWorkouts must be numbers' });
  }

  db.prepare(`
    INSERT INTO user_stats (user_id, grit_score, streak, total_volume_kg, total_workouts, updated_at)
    VALUES (?, ?, ?, ?, ?, datetime('now'))
    ON CONFLICT(user_id) DO UPDATE SET
      grit_score = excluded.grit_score,
      streak = excluded.streak,
      total_volume_kg = excluded.total_volume_kg,
      total_workouts = excluded.total_workouts,
      updated_at = datetime('now')
  `).run(req.userId, gritScore, streak, totalVolumeKg, totalWorkouts);

  res.json({ message: 'Stats synced' });
});

// Ranked leaderboard of yourself + accepted friends, by GRIT Score.
router.get('/', (req, res) => {
  const ids = [req.userId, ...friendIds(req.userId)];
  const placeholders = ids.map(() => '?').join(',');

  const rows = db.prepare(`
    SELECT u.id, u.first_name, u.last_name, s.grit_score, s.streak, s.total_volume_kg, s.total_workouts, s.updated_at
    FROM users u
    LEFT JOIN user_stats s ON s.user_id = u.id
    WHERE u.id IN (${placeholders})
    ORDER BY COALESCE(s.grit_score, 0) DESC
  `).all(...ids);

  res.json({
    entries: rows.map((r, index) => ({
      rank: index + 1,
      user: { id: r.id, firstName: r.first_name, lastName: r.last_name },
      gritScore: r.grit_score ?? 0,
      streak: r.streak ?? 0,
      totalVolumeKg: r.total_volume_kg ?? 0,
      totalWorkouts: r.total_workouts ?? 0,
      isMe: r.id === req.userId,
    })),
  });
});

module.exports = router;
