// // db.js
// const mongoose = require('mongoose');
// require('dotenv').config();

// const connectDB = async () => {
//   try {
//     await mongoose.connect(process.env.MONGO_URI, {
//       useNewUrlParser: true,
//       useUnifiedTopology: true,
//     });
//     console.log('MongoDB connecté');
//   } catch (err) {
//     console.error('Erreur de connexion MongoDB:', err);
//     process.exit(1);
//   }
// };

// module.exports = connectDB;




const mongoose = require('mongoose');
require('dotenv').config();

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      maxPoolSize: 10,
      connectTimeoutMS: 10000,
    });
    console.log('MongoDB connecté');
  } catch (err) {
    console.error('Erreur de connexion MongoDB:', err);
    process.exit(1);
  }
};

// Gestion de la reconnexion
mongoose.connection.on('disconnected', () => {
  console.log('MongoDB déconnecté, tentative de reconnexion...');
  connectDB();
});

module.exports = connectDB;