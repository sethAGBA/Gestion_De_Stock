const mongoose = require('mongoose');

const accountHistorySchema = new mongoose.Schema({
  accountNumber: {
    type: String,
    required: [true, 'Numéro de compte requis'],
  },
  action: {
    type: String,
    enum: ['create', 'update', 'delete'],
    required: [true, 'Action requise'],
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Utilisateur requis'],
  },
  changes: {
    type: Object,
    required: [true, 'Changements requis'],
  },
  modifiedAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('AccountHistory', accountHistorySchema);