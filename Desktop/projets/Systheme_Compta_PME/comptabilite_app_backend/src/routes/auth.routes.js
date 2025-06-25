//name is auth.routes.js
// This file defines the routes for authentication in the application.
const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');

router.post('/login', authController.login);
router.post('/signup', authController.signup);

module.exports = router;