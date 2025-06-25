const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const sequenceSchema = new Schema({
  type: { type: String, required: true, unique: true },
  prefix: { type: String, required: true },
  year: { type: Number, required: true },
  counter: { type: Number, default: 0 },
}, { timestamps: true });

module.exports = mongoose.model('Sequence', sequenceSchema);