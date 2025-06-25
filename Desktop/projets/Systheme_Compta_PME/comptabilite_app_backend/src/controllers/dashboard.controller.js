// // ce fichier s'appel dashboard.controller.js
// const Invoice = require('../models/invoice.model');
// const JournalEntry = require('../models/journal_entry.model');

// exports.getDashboardData = async (req, res) => {
//   const userId = req.user.userId;

//   try {
//     const invoices = await Invoice.find({ userId });
//     const entries = await JournalEntry.find({ userId });

//     const revenue = invoices
//       .filter((inv) => inv.status === 'paid')
//       .reduce((sum, inv) => sum + inv.amount, 0);

//     const unpaidInvoices = invoices.filter((inv) => inv.status === 'unpaid').length;

//     // Calcul du solde total basé sur les écritures (banques uniquement pour simplifier)
//     const totalBalance = entries.reduce((balance, entry) => {
//       if (entry.debitEntityType === 'Banque') {
//         return balance - entry.amount; // Débit réduit le solde
//       }
//       if (entry.creditEntityType === 'Banque') {
//         return balance + entry.amount; // Crédit augmente le solde
//       }
//       return balance;
//     }, 0); // Solde initial à 0 (à ajuster si tu veux un solde de départ)

//     res.status(200).json({
//       revenue,
//       unpaidInvoices,
//       totalBalance,
//     });
//   } catch (err) {
//     res.status(500).json({ error: 'Erreur serveur' });
//   }
// };



// filepath: /Users/cavris/Desktop/projets/Systheme_Compta_PME/comptabilite_app_backend/src/controllers/dashboard.controller.js

const Invoice = require('../models/invoice.model');
const JournalEntry = require('../models/journal_entry.model');

exports.getDashboardData = async (req, res) => {
  const userId = req.user.userId;

  try {
    const invoices = await Invoice.find({ userId });
    const entries = await JournalEntry.find({ userId });

    const totals = invoices.map(invoice => {
      const calc = calculateTotals(invoice.lignes, invoice.type === 'avoir');
      return { ...invoice.toObject(), ...calc };
    });

    const revenue = totals
      .filter((inv) => inv.statut === 'payee')
      .reduce((sum, inv) => sum + inv.totalTTC, 0);

    const unpaidInvoices = invoices.filter((inv) => inv.statut === 'enRetard').length;

    // Calcul du solde total basé sur les écritures (banques uniquement pour simplifier)
    const totalBalance = entries.reduce((balance, entry) => {
      if (entry.debitEntityType === 'Banque') {
        return balance - entry.amount; // Débit réduit le solde
      }
      if (entry.creditEntityType === 'Banque') {
        return balance + entry.amount; // Crédit augmente le solde
      }
      return balance;
    }, 0);

    res.status(200).json({
      revenue,
      unpaidInvoices,
      totalBalance,
    });
  } catch (err) {
    console.error('Erreur getDashboardData:', err.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

// Helper function to calculate invoice totals (copié ici pour éviter dépendance)
const calculateTotals = (lignes, isAvoir = false) => {
  if (!lignes || !Array.isArray(lignes) || lignes.length === 0) {
    return { totalHT: 0, totalTVA: 0, totalTTC: 0 };
  }

  const totalHT = lignes.reduce(
    (sum, ligne) => sum + (ligne.quantite * ligne.prixUnitaire - (ligne.remise || 0) - (ligne.rabais || 0) - (ligne.ristourne || 0)),
    0
  );
  const totalTVA = lignes.reduce(
    (sum, ligne) => sum + ((ligne.quantite * ligne.prixUnitaire - (ligne.remise || 0) - (ligne.rabais || 0) - (ligne.ristourne || 0)) * ((ligne.tva || 0) / 100)),
    0
  );
  const totalTTC = totalHT + totalTVA;

  return {
    totalHT: Number(totalHT.toFixed(2)),
    totalTVA: Number(totalTVA.toFixed(2)),
    totalTTC: Number((isAvoir ? -totalTTC : totalTTC).toFixed(2)),
  };
};