// This file defines the User model for the application using Mongoose.
// It includes fields such as email, password, role, and createdAt.
// The password field is hashed before saving to the database for security.
// The role field can be either 'admin' or 'user', with 'user' as the default.
// The createdAt field is automatically set to the current date and time when a new user is created.
// This file is part of the backend for a web application that manages accounting data.
// The User model is used to store user information and manage authentication.
// The file is named user.model.js and is located in the src/models directory of the backend project.
// This file is part of the backend for a web application that manages accounting data.
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['admin', 'user'], default: 'user' },
  createdAt: { type: Date, default: Date.now },
});

userSchema.pre('save', async function (next) {
  if (this.isModified('password')) {
    this.password = await bcrypt.hash(this.password, 10);
  }
  next();
});

module.exports = mongoose.model('User', userSchema);