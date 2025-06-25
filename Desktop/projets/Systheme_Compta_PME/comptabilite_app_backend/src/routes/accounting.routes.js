// This file defines the routes for the accounting module of the application.
// It includes routes for creating and retrieving accounting entries.
// The routes are protected by authentication middleware to ensure that only authenticated users can access them.
// The file is named accounting.routes.js and is located in the src/routes directory of the backend project.
// The routes are defined using Express.js and are organized in a modular way for better maintainability.
// const express = require('express');
// const router = express.Router();
// const accountingController = require('../controllers/accounting.controller');
// const authMiddleware = require('../middlewares/auth.middleware');

// router.post('/entries', authMiddleware, accountingController.createEntry);
// router.get('/entries', authMiddleware, accountingController.getEntries);

// module.exports = router;


// accounting.routes.js
const express = require('express');
const router = express.Router();
const accountingController = require('../controllers/accounting.controller');
const authMiddleware = require('../middlewares/auth.middleware');

router.post('/entries', authMiddleware, accountingController.createEntry);
router.get('/entries', authMiddleware, accountingController.getEntries);
router.put('/entries/:id', authMiddleware, accountingController.updateEntry); // Nouvelle route PUT
router.delete('/entries/:id', authMiddleware, accountingController.deleteEntry); // Nouvelle route DELETE

module.exports = router;