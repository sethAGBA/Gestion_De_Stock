// Description: Ce fichier définit le modèle de données pour les écritures comptables dans la base de données MongoDB.
// Il utilise Mongoose pour définir le schéma et les types de données. il s'appel journal_entry.model.js
const mongoose = require('mongoose');

const journalEntrySchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  date: { type: Date, default: Date.now }, // Déjà présent
  description: { type: String, required: true },
  debitEntityType: { type: String, enum: ['Banque', 'Fournisseur', 'Client', 'Ventes'], required: true },
  debitEntityName: { type: String, required: true },
  creditEntityType: { type: String, enum: ['Banque', 'Fournisseur', 'Client', 'Ventes'], required: true },
  creditEntityName: { type: String, required: true },
  amount: { type: Number, required: true },
  reference: { type: String, required: false }, 
});

module.exports = mongoose.model('JournalEntry', journalEntrySchema);