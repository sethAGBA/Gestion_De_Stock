//le nom est cash_account.model.js
const mongoose = require('mongoose');

const cashAccountSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  balance: { type: Number, default: 0 },
});

module.exports = mongoose.model('CashAccount', cashAccountSchema);