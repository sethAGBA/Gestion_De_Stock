//entities.routes.js
const express = require('express');
const router = express.Router();
const entitiesController = require('../controllers/entities.controller');
const authMiddleware = require('../middlewares/auth.middleware');

router.post('/suppliers', authMiddleware, entitiesController.createSupplier);
router.get('/suppliers', authMiddleware, entitiesController.getSuppliers);
router.post('/clients', authMiddleware, entitiesController.createClient);
router.get('/clients', authMiddleware, entitiesController.getClients);
router.post('/banks', authMiddleware, entitiesController.createBank);
router.get('/banks', authMiddleware, entitiesController.getBanks);

module.exports = router;