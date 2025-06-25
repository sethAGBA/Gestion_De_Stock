// // // const mongoose = require('mongoose');

// // // const accountSchema = new mongoose.Schema({
// // //   number: { type: String, required: true, unique: true },
// // //   label: { type: String, required: true },
// // //   userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
// // //   createdAt: { type: Date, default: Date.now },
// // // });

// // // module.exports = mongoose.model('Account', accountSchema);




// // // server// server.js 
// // // filepath: /Users/cavris/Desktop/projets/Systheme_Compta_PME/comptabilite_app_backend/server.js


// // const mongoose = require('mongoose');

// // const accountSchema = new mongoose.Schema({
// //   number: {
// //     type: String,
// //     required: [true, 'Numéro de compte requis'],
// //     unique: true,
// //     validate: {
// //       validator: function (v) {
// //         return /^\d{2,5}$/.test(v) && /^[1-9]/.test(v);
// //       },
// //       message: 'Numéro invalide (2-5 chiffres, commence par 1-9)',
// //     },
// //   },
// //   label: {
// //     type: String,
// //     required: [true, 'Libellé requis'],
// //     trim: true,
// //   },
// //   userId: {
// //     type: mongoose.Schema.Types.ObjectId,
// //     ref: 'User',
// //     required: [true, 'Utilisateur requis'],
// //   },
// //   accountClass: {
// //     type: String,
// //     enum: ['classe1', 'classe2', 'classe3', 'classe4', 'classe5', 'classe6', 'classe7', 'classe8', 'classe9'],
// //     required: [true, 'Classe comptable requise'],
// //   },
// //   accountType: {
// //     type: String,
// //     enum: ['bilan', 'resultat', 'analytique'],
// //     // enum: ['compte de bialn ', 'compte de gestion ', 'compte d\'engagement hors bilan'],
// //     required: [true, 'Type de compte requis'],
// //   },
// //   isTVARelated: {
// //     type: Boolean,
// //     default: false,
// //   },
// //   regimeFiscal: {
// //     type: String,
// //     enum: ['reel', 'exonere', 'non_assujetti'],
// //     required: [true, 'Régime fiscal requis'],
// //   },
// //   isSelectableForInvoices: {
// //     type: Boolean,
// //     default: false,
// //   },
// //   supportedCurrencies: {
// //     type: [String],
// //     default: ['XOF'],
// //     enum: ['XOF', 'XAF', 'KMF', 'USD', 'EUR'],
// //   },
// //   createdAt: {
// //     type: Date,
// //     default: Date.now,
// //   },
// //   updatedAt: {
// //     type: Date,
// //   },
// // });

// // // Vérifier l’intangibilité avant suppression
// // accountSchema.pre('deleteOne', { document: true, query: false }, async function (next) {
// //   const JournalEntry = mongoose.model('JournalEntry');
// //   const entries = await JournalEntry.find({
// //     $or: [{ debitAccount: this.number }, { creditAccount: this.number }],
// //   });
// //   if (entries.length > 0) {
// //     throw new Error('Compte utilisé dans des écritures, suppression interdite');
// //   }
// //   const Archive = mongoose.model('Archive');
// //   await Archive.create({
// //     ...this.toObject(),
// //     deletedAt: new Date(),
// //     deletedBy: this.userId,
// //   });
// //   next();
// // });

// // // Mettre à jour updatedAt
// // accountSchema.pre('save', function (next) {
// //   this.updatedAt = new Date();
// //   next();
// // });

// // module.exports = mongoose.model('Account', accountSchema);




// const mongoose = require('mongoose');

// const accountSchema = new mongoose.Schema({
//   number: {
//     type: String,
//     required: [true, 'Numéro de compte requis'],
//     unique: true,
//     validate: {
//       validator: function (v) {
//         return /^\d{2,8}$/.test(v) && /^[1-9]/.test(v);
//       },
//       message: 'Numéro invalide (2-8 chiffres, commence par 1-9)',
//     },
//   },
//   label: {
//     type: String,
//     required: [true, 'Libellé requis'],
//     trim: true,
//   },
//   userId: {
//     type: mongoose.Schema.Types.ObjectId,
//     ref: 'User',
//     required: [true, 'Utilisateur requis'],
//   },
//   accountClass: {
//     type: String,
//     enum: ['classe1', 'classe2', 'classe3', 'classe4', 'classe5', 'classe6', 'classe7', 'classe8', 'classe9'],
//     required: [true, 'Classe comptable requise'],
//   },
//   accountType: {
//     type: String,
//     enum: ['bilan', 'resultat', 'analytique'],
//     required: [true, 'Type de compte requis'],
//   },
//   parentAccount: {
//     type: String,
//     default: null,
//     validate: {
//       validator: async function (v) {
//         if (!v) return true; // Pas de parent, c'est un compte principal
//         const parent = await mongoose.model('Account').findOne({ number: v });
//         return parent && this.number.startsWith(v);
//       },
//       message: 'Compte parent invalide ou numéro incohérent',
//     },
//   },
//   isTVARelated: {
//     type: Boolean,
//     default: false,
//   },
//   regimeFiscal: {
//     type: String,
//     enum: ['reel', 'exonere', 'non_assujetti'],
//     required: [true, 'Régime fiscal requis'],
//   },
//   isSelectableForInvoices: {
//     type: Boolean,
//     default: false,
//   },
//   supportedCurrencies: {
//     type: [String],
//     default: ['XOF'],
//     enum: ['XOF', 'XAF', 'KMF', 'USD', 'EUR'],
//   },
//   createdAt: {
//     type: Date,
//     default: Date.now,
//   },
//   updatedAt: {
//     type: Date,
//   },
// });

// // Vérifier l’intangibilité avant suppression
// accountSchema.pre('deleteOne', { document: true, query: false }, async function (next) {
//   const JournalEntry = mongoose.model('JournalEntry');
//   const entries = await JournalEntry.find({
//     $or: [{ debitAccount: this.number }, { creditAccount: this.number }],
//   });
//   if (entries.length > 0) {
//     throw new Error('Compte utilisé dans des écritures, suppression interdite');
//   }
//   // Vérifier les sous-comptes
//   const subAccounts = await mongoose.model('Account').find({ parentAccount: this.number });
//   if (subAccounts.length > 0) {
//     throw new Error('Compte parent avec sous-comptes, suppression interdite');
//   }
//   // Archiver le compte
//   const Archive = mongoose.model('Archive');
//   await Archive.create({
//     ...this.toObject(),
//     deletedAt: new Date(),
//     deletedBy: this.userId,
//   });
//   next();
// });

// // Mettre à jour updatedAt
// accountSchema.pre('save', function (next) {
//   this.updatedAt = new Date();
//   next();
// });

// module.exports = mongoose.model('Account', accountSchema);






const mongoose = require('mongoose');
const Archive = require('./archive.model'); // Import explicite

const accountSchema = new mongoose.Schema({
  number: {
    type: String,
    required: [true, 'Numéro de compte requis'],
    unique: true,
    validate: {
      validator: function (v) {
        return /^\d{2,8}$/.test(v) && /^[1-9]/.test(v);
      },
      message: 'Numéro invalide (2-8 chiffres, commence par 1-9)',
    },
  },
  label: {
    type: String,
    required: [true, 'Libellé requis'],
    trim: true,
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Utilisateur requis'],
  },
  accountClass: {
    type: String,
    enum: ['classe1', 'classe2', 'classe3', 'classe4', 'classe5', 'classe6', 'classe7', 'classe8', 'classe9'],
    required: [true, 'Classe comptable requise'],
  },
  accountType: {
    type: String,
    enum: ['bilan', 'resultat', 'analytique'],
    required: [true, 'Type de compte requis'],
  },
  parentAccount: {
    type: String,
    default: null,
    validate: {
      validator: async function (v) {
        if (!v) return true;
        const parent = await mongoose.model('Account').findOne({ number: v });
        return parent && this.number.startsWith(v);
      },
      message: 'Compte parent invalide ou numéro incohérent',
    },
  },
  isTVARelated: {
    type: Boolean,
    default: false,
  },
  regimeFiscal: {
    type: String,
    enum: ['reel', 'exonere', 'non_assujetti'],
    required: [true, 'Régime fiscal requis'],
  },
  isSelectableForInvoices: {
    type: Boolean,
    default: false,
  },
  supportedCurrencies: {
    type: [String],
    default: ['XOF'],
    enum: ['XOF', 'XAF', 'KMF', 'USD', 'EUR'],
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
  },
});

// Vérifier l’intangibilité avant suppression
accountSchema.pre('deleteOne', { document: true, query: false }, async function (next) {
  const JournalEntry = mongoose.model('JournalEntry');
  const entries = await JournalEntry.find({
    $or: [{ debitAccount: this.number }, { creditAccount: this.number }],
  });
  if (entries.length > 0) {
    throw new Error('Compte utilisé dans des écritures, suppression interdite');
  }
  const subAccounts = await mongoose.model('Account').find({ parentAccount: this.number });
  if (subAccounts.length > 0) {
    throw new Error('Compte parent avec sous-comptes, suppression interdite');
  }
  // Archiver le compte
  await Archive.create({
    ...this.toObject(),
    deletedAt: new Date(),
    deletedBy: this.userId,
  });
  next();
});

// Mettre à jour updatedAt
accountSchema.pre('save', function (next) {
  this.updatedAt = new Date();
  next();
});

module.exports = mongoose.model('Account', accountSchema);