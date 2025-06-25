// Fichier de routes pour le tableau de bord
// Description: Ce fichier définit les routes pour le tableau de bord de l'application.
// Il utilise Express pour gérer les requêtes HTTP et les réponses. Il s'appel dashboard.routes.js
const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboard.controller');
const authMiddleware = require('../middlewares/auth.middleware');

// Vérifie que les imports sont valides
console.log('dashboardController.getDashboardData:', typeof dashboardController.getDashboardData);
console.log('authMiddleware:', typeof authMiddleware);

router.get('/', authMiddleware, dashboardController.getDashboardData);

module.exports = router;