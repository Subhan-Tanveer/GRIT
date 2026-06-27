const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

function signToken(userId) {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '30d' });
}

function publicUser(user) {
  return {
    id: user.id,
    firstName: user.first_name,
    lastName: user.last_name,
    email: user.email,
    mobileNumber: user.mobile_number,
  };
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

router.post('/register', (req, res) => {
  const { firstName, lastName, email, mobileNumber, password } = req.body;

  if (!firstName || !lastName || !email || !mobileNumber || !password) {
    return res.status(400).json({ error: 'firstName, lastName, email, mobileNumber, and password are required' });
  }
  if (!EMAIL_RE.test(email.trim())) {
    return res.status(400).json({ error: 'Invalid email address' });
  }
  if (password.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters' });
  }

  const normalizedEmail = email.trim().toLowerCase();
  const normalizedMobile = mobileNumber.trim();

  const existing = db.prepare('SELECT id FROM users WHERE email = ? OR mobile_number = ?')
    .get(normalizedEmail, normalizedMobile);
  if (existing) {
    return res.status(409).json({ error: 'An account with this email or mobile number already exists' });
  }

  const passwordHash = bcrypt.hashSync(password, 10);
  const result = db
    .prepare('INSERT INTO users (first_name, last_name, email, mobile_number, password_hash) VALUES (?, ?, ?, ?, ?)')
    .run(firstName.trim(), lastName.trim(), normalizedEmail, normalizedMobile, passwordHash);

  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json({ token: signToken(user.id), user: publicUser(user) });
});

// Login with either email or mobile number.
router.post('/login', (req, res) => {
  const { identifier, password } = req.body;
  if (!identifier || !password) {
    return res.status(400).json({ error: 'identifier and password are required' });
  }

  const normalizedIdentifier = identifier.trim().toLowerCase();
  const user = db.prepare('SELECT * FROM users WHERE email = ? OR mobile_number = ?')
    .get(normalizedIdentifier, identifier.trim());

  if (!user || !bcrypt.compareSync(password, user.password_hash)) {
    return res.status(401).json({ error: 'Invalid email/mobile number or password' });
  }

  res.json({ token: signToken(user.id), user: publicUser(user) });
});

router.get('/me', requireAuth, (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json({ user: publicUser(user) });
});

module.exports = router;
