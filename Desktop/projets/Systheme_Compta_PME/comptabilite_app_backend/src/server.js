// // // //server.js
// // // const express = require('express');
// // // const connectDB = require('./config/db');
// // // const authRoutes = require('./routes/auth.routes');
// // // const dashboardRoutes = require('./routes/dashboard.routes');
// // // const accountingRoutes = require('./routes/accounting.routes');
// // // const invoiceRoutes = require('./routes/invoice.routes');

// // // const app = express();
// // // app.use(express.json());
// // // connectDB();

// // // app.use('/auth', authRoutes);
// // // app.use('/dashboard', dashboardRoutes);
// // // app.use('/accounting', accountingRoutes);
// // // app.use('/invoices', invoiceRoutes); // Nouvelle ligne
// // // app.use('/accounts', require('./routes/accounts.routes'));
// // // const PORT = process.env.PORT || 3000;
// // // app.listen(PORT, () => console.log(`Serveur démarré sur le port ${PORT}`));



// // // filepath: /Users/cavris/Desktop/projets/Systheme_Compta_PME/comptabilite_app_backend/server.js

// // const express = require('express');
// // const connectDB = require('./config/db');
// // const authRoutes = require('./routes/auth.routes');
// // const dashboardRoutes = require('./routes/dashboard.routes');
// // const accountingRoutes = require('./routes/accounting.routes');
// // const invoiceRoutes = require('./routes/invoice.routes');

// // const app = express();
// // app.use(express.json());
// // app.use('/documents', express.static('documents'));
// // connectDB();

// // app.use('/auth', authRoutes);
// // app.use('/dashboard', dashboardRoutes);
// // app.use('/accounting', accountingRoutes);
// // app.use('/invoices', invoiceRoutes);
// // app.use('/accounts', require('./routes/accounts.routes'));

// // const PORT = process.env.PORT || 3000;
// // app.listen(PORT, () => console.log(`Serveur démarré sur le port ${PORT}`));




// // server// server.js 
// // filepath: /Users/cavris/Desktop/projets/Systheme_Compta_PME/comptabilite_app_backend/server.js



// // const express = require('express');
// // const connectDB = require('./config/db');
// // const authRoutes = require('./routes/auth.routes');
// // const dashboardRoutes = require('./routes/dashboard.routes');
// // const accountingRoutes = require('./routes/accounting.routes');
// // const invoiceRoutes = require('./routes/invoice.routes');

// // const app = express();
// // app.use(express.json());
// // app.use('/documents', express.static('documents'));
// // connectDB();

// // app.use('/auth', authRoutes);
// // app.use('/dashboard', dashboardRoutes);
// // app.use('/accounting', accountingRoutes);
// // app.use('/invoices', invoiceRoutes);
// // app.use('/accounts', require('./routes/accounts.routes'));

// // // Error handling middleware
// // app.use((err, req, res, next) => {
// //   console.error('Erreur serveur:', err.stack);
// //   res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // });

// // const PORT = process.env.PORT || 3000;
// // app.listen(PORT, () => console.log(`Serveur démarré sur le port ${PORT}`));



// const express = require('express');
// const cors = require('cors');
// const rateLimit = require('express-rate-limit');
// const connectDB = require('./config/db');
// const authRoutes = require('./routes/auth.routes');
// const dashboardRoutes = require('./routes/dashboard.routes');
// const accountingRoutes = require('./routes/accounting.routes');
// const invoiceRoutes = require('./routes/invoice.routes');
// const accountsRoutes = require('./routes/accounts.routes');

// const app = express();

// // Middlewares
// app.use(cors({ origin: process.env.FRONTEND_URL || 'http://localhost:3000' }));
// app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));
// app.use(express.json());
// app.use('/documents', express.static('documents'));

// // Connexion MongoDB
// connectDB();

// // Routes
// app.use('/auth', authRoutes);
// app.use('/dashboard', dashboardRoutes);
// app.use('/accounting', accountingRoutes);
// app.use('/invoices', invoiceRoutes);
// app.use('/accounts', accountsRoutes);

// // Gestion des erreurs
// app.use((err, req, res, next) => {
//   console.error('Erreur serveur:', err.stack);
//   res.status(500).json({ error: 'Erreur serveur', details: err.message });
// });

// const PORT = process.env.PORT || 3000;
// app.listen(PORT, () => console.log(`Serveur démarré sur le port ${PORT}`));


const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const connectDB = require('./config/db');
const authRoutes = require('./routes/auth.routes');
const dashboardRoutes = require('./routes/dashboard.routes');
const accountingRoutes = require('./routes/accounting.routes');
const invoiceRoutes = require('./routes/invoice.routes');
const accountsRoutes = require('./routes/accounts.routes');

// Importer les modèles pour garantir leur enregistrement
require('./models/account.model');
require('./models/archive.model');
require('./models/account_history.model');
// Ajoute d'autres modèles si nécessaire (ex. JournalEntry, User, Invoice)

const app = express();

// Middlewares
app.use(cors({ origin: process.env.FRONTEND_URL || 'http://localhost:3000' }));
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));
app.use(express.json());
app.use('/documents', express.static('documents'));

// Connexion MongoDB
connectDB();

// Routes
app.use('/auth', authRoutes);
app.use('/dashboard', dashboardRoutes);
app.use('/accounting', accountingRoutes);
app.use('/invoices', invoiceRoutes);
app.use('/accounts', accountsRoutes);

// Gestion des erreurs
app.use((err, req, res, next) => {
  console.error('Erreur serveur:', err.stack);
  res.status(500).json({ error: 'Erreur serveur', details: err.message });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Serveur démarré sur le port ${PORT}`));