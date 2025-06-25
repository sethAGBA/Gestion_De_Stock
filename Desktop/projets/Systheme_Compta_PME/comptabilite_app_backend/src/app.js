// filepath: /Users/cavris/Desktop/projets/Systheme_Compta_PME/comptabilite_app_backend/src/app.js

const express = require('express');
const mongoose = require('mongoose');
const invoiceRoutes = require('./routes/invoice.routes');
const config = require('./config/config');

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

mongoose.connect(config.mongoUri, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => {
  console.log('Connecté à MongoDB');
}).catch((err) => {
  console.error('Erreur de connexion MongoDB:', err.message);
});

app.use('/invoices', invoiceRoutes); // Pas de /api

app.use((err, req, res, next) => {
  console.error('Erreur serveur:', err.message);
  res.status(500).json({ error: 'Erreur serveur', details: err.message });
});

module.exports = app;