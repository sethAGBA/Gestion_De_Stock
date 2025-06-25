// supplier.model.js
// Description: Ce fichier définit le modèle de données pour les fournisseurs dans la base de données MongoDB.
// Il utilise Mongoose pour définir le schéma et les types de données.
const mongoose = require('mongoose');

const supplierSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  accountCode: { type: String, default: '401' }, // Compte par défaut pour fournisseurs
  contact: { type: String }, // Optionnel : nom du contact
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Supplier', supplierSchema);