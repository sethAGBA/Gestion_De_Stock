// // // This file defines the Invoice model for the MongoDB database using Mongoose.
// // // It includes fields such as userId, number, clientName, amount, status, and createdAt.
// // // The userId field references the User model to associate the invoice with a specific user.
// // //le nom est invoice.model.js
// // // const mongoose = require('mongoose');

// // // const invoiceSchema = new mongoose.Schema({
// // //   userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
// // //   number: { type: String, required: true },
// // //   clientName: { type: String, required: true },
// // //   amount: { type: Number, required: true },
// // //   status: { type: String, enum: ['paid', 'unpaid'], default: 'unpaid' },
// // //   createdAt: { type: Date, default: Date.now }, // Déjà présent
// // // });

// // // module.exports = mongoose.model('Invoice', invoiceSchema);

// // // invoice.model.js

// // // const mongoose = require('mongoose');

// // // const invoiceSchema = new mongoose.Schema({
// // //   userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
// // //   numero: { type: String, required: true },
// // //   type: { type: String, enum: ['standard', 'recurrente', 'acompte', 'avoir', 'devis'], required: true },
// // //   statut: { type: String, enum: ['brouillon', 'envoyee', 'payee', 'annulee', 'en_attente', 'accepte', 'refuse'], default: 'brouillon' },
// // //   clientNom: { type: String, required: true },
// // //   lignes: [{
// // //     description: { type: String, required: true },
// // //     quantite: { type: Number, required: true },
// // //     prixUnitaire: { type: Number, required: true },
// // //     tva: { type: Number, default: 0 },
// // //     remise: { type: Number, default: 0 },
// // //     rabais: { type: Number, default: 0 },
// // //     ristourne: { type: Number, default: 0 },
// // //   }],
// // //   totalHT: { type: Number, required: true },
// // //   totalTVA: { type: Number, required: true },
// // //   totalTTC: { type: Number, required: true },
// // //   dateEmission: { type: Date, default: Date.now },
// // //   dateEcheance: { type: Date },
// // //   frequence: { type: String, enum: ['mensuelle', 'trimestrielle', 'annuelle'] },
// // //   dateFin: { type: Date },
// // //   invoiceRef: { type: mongoose.Schema.Types.ObjectId, ref: 'Invoice' },
// // //   acompte: { type: Number, default: 0 },
// // //   motifAnnulation: { type: String },
// // //   createdAt: { type: Date, default: Date.now },
// // // });

// // // invoiceSchema.index({ userId: 1, numero: 1 });
// // // module.exports = mongoose.model('Invoice', invoiceSchema);







// // // filepath: /Users/cavris/Desktop/projets/Systheme_Compta_PME/comptabilite_app_backend/src/models/invoice.model.js

// // // const mongoose = require('mongoose');

// // // const invoiceSchema = new mongoose.Schema({
// // //   userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
// // //   numero: { type: String, required: true },
// // //   type: {
// // //     type: String,
// // //     enum: ['standard', 'recurrente', 'acompte', 'avoir', 'devis'],
// // //     required: true,
// // //   },
// // //   statut: {
// // //     type: String,
// // //     enum: ['brouillon', 'envoyee', 'payee', 'enRetard', 'annulee', 'enAttente', 'accepte', 'refuse'],
// // //     default: 'brouillon',
// // //   },
// // //   clientNom: { type: String, required: true },
// // //   clientAdresse: { type: String },
// // //   clientTVA: { type: String },
// // //   siret: { type: String },
// // //   clientSiret: { type: String },
// // //   adresseFournisseur: { type: String },
// // //   penalitesRetard: { type: String, default: '5000 FCFA + 2% par mois' },
// // //   lignes: [{
// // //     description: { type: String, required: true },
// // //     quantite: { type: Number, required: true },
// // //     prixUnitaire: { type: Number, required: true },
// // //     tva: { type: Number, default: 0 },
// // //     remise: { type: Number, default: 0 },
// // //     rabais: { type: Number, default: 0 },
// // //     ristourne: { type: Number, default: 0 },
// // //   }],
// // //   fraisLivraison: { type: Number, default: 0 },
// // //   agios: { type: Number, default: 0 },
// // //   acompte: { type: Number, default: 0 },
// // //   devise: { type: String, default: 'XOF' },
// // //   invoiceRef: { type: mongoose.Schema.Types.ObjectId, ref: 'Invoice' },
// // //   motifAnnulation: { type: String },
// // //   frequence: { type: String, enum: ['mensuelle', 'trimestrielle', 'annuelle'] },
// // //   dateFin: { type: Date },
// // //   parentInvoice: { type: mongoose.Schema.Types.ObjectId, ref: 'Invoice' },
// // //   revisionPrix: { type: String },
// // //   motifAvoir: { type: String },
// // //   creditType: { type: String },
// // //   validiteDevis: { type: Date },
// // //   version: { type: Number, default: 1 },
// // //   signature: { type: String },
// // //   dateEmission: { type: Date, default: Date.now },
// // //   dateEcheance: { type: Date },
// // //   createdAt: { type: Date, default: Date.now },
// // // });

// // // invoiceSchema.index({ userId: 1, numero: 1 });
// // // module.exports = mongoose.model('Invoice', invoiceSchema);



//invoice.model.js
// This file defines the Invoice model for the MongoDB database using Mongoose.


// const mongoose = require('mongoose');

// const invoiceLineSchema = new mongoose.Schema({
//   description: { type: String, required: true },
//   quantite: { type: Number, required: true, min: 0 },
//   prixUnitaireHT: { type: Number, required: true, min: 0 },
//   tauxTVA: { type: Number, enum: [0, 5, 10, 18, 19], required: true },
// });

// const tvaByRateSchema = new mongoose.Schema({
//   rate: { type: Number, enum: [0, 5, 10, 18, 19], required: true },
//   baseHT: { type: Number, required: true, min: 0 },
//   montantTVA: { type: Number, required: true, min: 0 },
// });

// const invoiceSchema = new mongoose.Schema({
//   userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
//   numero: { type: String, required: true, unique: true },
//   type: {
//     type: String,
//     enum: ['standard', 'recurrente', 'acompte', 'avoir', 'devis', 'proforma'],
//     required: true,
//   },
//   statut: {
//     type: String,
//     enum: ['brouillon', 'envoyee', 'payee', 'enRetard', 'annulee', 'enAttente', 'accepte', 'refuse'],
//     default: 'brouillon',
//   },
//   rccm: { type: String, required: true, match: /^RC\/[A-Z]{2}\/[A-Z]{3}\/[0-9]{4}\/[A-Z][0-9]{5}$/ },
//   clientRccm: { type: String, match: /^RC\/[A-Z]{2}\/[A-Z]{3}\/[0-9]{4}\/[A-Z][0-9]{5}$/ },
//   clientNom: { type: String, required: true },
//   clientAdresse: { type: String },
//   clientEmail: { type: String },
//   clientTelephone: { type: String },
//   adresseFournisseur: { type: String },
//   penalites: { type: Number, min: 0, required: ['standard', 'acompte'].includes(this.type) },
//   lignes: [invoiceLineSchema],
//   tvaByRate: [tvaByRateSchema],
//   fraisLivraison: { type: Number, default: 0, min: 0 },
//   agios: { type: Number, default: 0, min: 0 },
//   acompte: { type: Number, default: 0, min: 0 },
//   devise: { type: String, enum: ['XOF'], default: 'XOF', required: true },
//   invoiceRef: { type: mongoose.Schema.Types.ObjectId, ref: 'Invoice' },
//   motifAnnulation: { type: String },
//   frequence: { type: String, enum: ['mensuelle', 'trimestrielle', 'annuelle'] },
//   dateFin: { type: Date },
//   parentInvoice: { type: mongoose.Schema.Types.ObjectId, ref: 'Invoice' },
//   revisionPrix: { type: String },
//   motifAvoir: { type: String },
//   creditType: { type: String },
//   validiteDevis: { type: Date },
//   version: { type: Number, default: 1 },
//   signature: { type: String },
//   dateEmission: { type: Date, default: Date.now },
//   dateEcheance: { type: Date },
//   montantHT: { type: Number, required: true, min: 0 },
//   montantTVA: { type: Number, required: true, min: 0 },
//   montantTTC: { type: Number, required: true, min: 0 },
//   createdAt: { type: Date, default: Date.now },
// });

// invoiceSchema.pre('save', function (next) {
//   // Calculate montantHT
//   this.montantHT = this.lignes.reduce((sum, line) => sum + (line.prixUnitaireHT * line.quantite), 0);

//   // Calculate tvaByRate and montantTVA
//   const baseByRate = {};
//   this.lignes.forEach(line => {
//     const base = line.prixUnitaireHT * line.quantite;
//     baseByRate[line.tauxTVA] = (baseByRate[line.tauxTVA] || 0) + base;
//   });
//   this.tvaByRate = Object.entries(baseByRate).map(([rate, baseHT]) => ({
//     rate: parseFloat(rate),
//     baseHT,
//     montantTVA: baseHT * (parseFloat(rate) / 100),
//   }));
//   this.montantTVA = this.tvaByRate.reduce((sum, tva) => sum + tva.montantTVA, 0);

//   // Calculate montantTTC
//   this.montantTTC = this.montantHT + this.montantTVA + (this.penalites || 0);

//   // Adjust for avoir (negative totals)
//   if (this.type === 'avoir') {
//     this.montantHT = -this.montantHT;
//     this.tvaByRate = this.tvaByRate.map(tva => ({
//       ...tva,
//       baseHT: -tva.baseHT,
//       montantTVA: -tva.montantTVA,
//     }));
//     this.montantTVA = -this.montantTVA;
//     this.montantTTC = -this.montantTTC;
//   }

//   next();
// });

// invoiceSchema.index({ userId: 1, numero: 1 });
// module.exports = mongoose.model('Invoice', invoiceSchema);



const mongoose = require('mongoose');

const invoiceLineSchema = new mongoose.Schema({
  description: { type: String, required: true },
  quantite: { type: Number, required: true, min: 0 },
  prixUnitaireHT: { type: Number, required: true, min: 0 },
  tauxTVA: { type: Number, enum: [0, 5, 10, 18, 19], required: true },
});

const tvaByRateSchema = new mongoose.Schema({
  rate: { type: Number, enum: [0, 5, 10, 18, 19], required: true },
  baseHT: { type: Number, required: true, min: 0 },
  montantTVA: { type: Number, required: true, min: 0 },
});

const invoiceSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  numero: { type: String, required: true, unique: true },
  type: {
    type: String,
    enum: ['standard', 'recurrente', 'acompte', 'avoir', 'devis', 'proforma', 'abonnement', 'indemnite'],
    required: true,
  },
  statut: {
    type: String,
    enum: ['brouillon', 'envoyee', 'payee', 'enRetard', 'annulee', 'enAttente', 'accepte', 'refuse', 'partiellementPayee'],
    default: 'brouillon',
  },
  rccm: { type: String, required: true, match: /^RC\/[A-Z]{2}\/[A-Z]{3}\/[0-9]{4}\/[A-Z][0-9]{5}$/ },
  clientRccm: { type: String, match: /^RC\/[A-Z]{2}\/[A-Z]{3}\/[0-9]{4}\/[A-Z][0-9]{5}$/ },
  clientNom: { type: String, required: true },
  clientAdresse: { type: String },
  clientEmail: { type: String },
  clientTelephone: { type: String },
  adresseFournisseur: { type: String },
  penalites: { type: Number, min: 0, required: ['standard', 'acompte'].includes(this.type) },
  lignes: [invoiceLineSchema],
  tvaByRate: [tvaByRateSchema],
  fraisLivraison: { type: Number, default: 0, min: 0 },
  agios: { type: Number, default: 0, min: 0 },
  acompte: { type: Number, default: 0, min: 0 },
  devise: { type: String, enum: ['XOF'], default: 'XOF', required: true },
  invoiceRef: { type: mongoose.Schema.Types.ObjectId, ref: 'Invoice' },
  motifAnnulation: { type: String },
  frequence: { type: String, enum: ['mensuelle', 'trimestrielle', 'annuelle'] },
  dateFin: { type: Date },
  parentInvoice: { type: mongoose.Schema.Types.ObjectId, ref: 'Invoice' },
  revisionPrix: { type: String },
  motifAvoir: { type: String },
  creditType: { type: String },
  validiteDevis: { type: Date },
  version: { type: Number, default: 1 },
  signature: { type: String },
  dateEmission: { type: Date, default: Date.now },
  dateEcheance: { type: Date },
  montantHT: { type: Number, required: true, min: 0 },
  montantTVA: { type: Number, required: true, min: 0 },
  montantTTC: { type: Number, required: true, min: 0 },
  createdAt: { type: Date, default: Date.now },
});

invoiceSchema.pre('save', function (next) {
  // Calculate montantHT
  this.montantHT = this.lignes.reduce((sum, line) => sum + (line.prixUnitaireHT * line.quantite), 0);

  // Calculate tvaByRate and montantTVA
  const baseByRate = {};
  this.lignes.forEach(line => {
    const base = line.prixUnitaireHT * line.quantite;
    baseByRate[line.tauxTVA] = (baseByRate[line.tauxTVA] || 0) + base;
  });
  this.tvaByRate = Object.entries(baseByRate).map(([rate, baseHT]) => ({
    rate: parseFloat(rate),
    baseHT,
    montantTVA: baseHT * (parseFloat(rate) / 100),
  }));
  this.montantTVA = this.tvaByRate.reduce((sum, tva) => sum + tva.montantTVA, 0);

  // Calculate montantTTC
  this.montantTTC = this.montantHT + this.montantTVA + (this.penalites || 0);

  // Adjust for avoir (negative totals)
  if (this.type === 'avoir') {
    this.montantHT = -this.montantHT;
    this.tvaByRate = this.tvaByRate.map(tva => ({
      ...tva,
      baseHT: -tva.baseHT,
      montantTVA: -tva.montantTVA,
    }));
    this.montantTVA = -this.montantTVA;
    this.montantTTC = -this.montantTTC;
  }

  next();
});

invoiceSchema.index({ userId: 1, numero: 1 });
module.exports = mongoose.model('Invoice', invoiceSchema);