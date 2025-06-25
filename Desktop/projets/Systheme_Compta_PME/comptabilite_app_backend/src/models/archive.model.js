// const mongoose = require('mongoose');

// const archiveSchema = new mongoose.Schema({
//   number: {
//     type: String,
//     required: [true, 'Numéro de compte requis'],
//   },
//   label: {
//     type: String,
//     required: [true, 'Libellé requis'],
//   },
//   userId: {
//     type: mongoose.Schema.Types.ObjectId,
//     ref: 'User',
//     required: [true, 'Utilisateur requis'],
//   },
//   accountClass: {
//     type: String,
//     required: [true, 'Classe comptable requise'],
//   },
//   accountType: {
//     type: String,
//     required: [true, 'Type de compte requis'],
//   },
//   deletedAt: {
//     type: Date,
//     required: [true, 'Date de suppression requise'],
//   },
//   deletedBy: {
//     type: mongoose.Schema.Types.ObjectId,
//     ref: 'User',
//     required: [true, 'Utilisateur requis'],
//   },
// });

// module.exports = mongoose.model('Archive', archiveSchema);




const mongoose = require('mongoose');

const archiveSchema = new mongoose.Schema({
  number: {
    type: String,
    required: true,
  },
  label: {
    type: String,
    required: true,
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  accountClass: {
    type: String,
    required: true,
  },
  accountType: {
    type: String,
    required: true,
  },
  parentAccount: {
    type: String,
    default: null,
  },
  isTVARelated: {
    type: Boolean,
    default: false,
  },
  regimeFiscal: {
    type: String,
    required: true,
  },
  isSelectableForInvoices: {
    type: Boolean,
    default: false,
  },
  supportedCurrencies: {
    type: [String],
    default: ['XOF'],
  },
  createdAt: {
    type: Date,
    required: true,
  },
  updatedAt: {
    type: Date,
  },
  deletedAt: {
    type: Date,
    required: true,
  },
  deletedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
});

module.exports = mongoose.model('Archive', archiveSchema);