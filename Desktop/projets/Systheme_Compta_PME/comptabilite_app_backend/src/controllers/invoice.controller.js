// // // // //ce fichier est le controller pour la gestion des factures
// // // // // Il contient les fonctions pour créer, récupérer et mettre à jour les factures
// // // // // Importation des modèles Invoice et JournalEntry
// // // // // Il s'appel invoice.controller.js
// // // // const Invoice = require('../models/invoice.model');
// // // // const JournalEntry = require('../models/journal_entry.model');

// // // // exports.createInvoice = async (req, res) => {
// // // //   // const { number, clientName, amount } = req.body;
// // // //   // const userId = req.user.userId;
// // // //   const { type, numero, clientNom, lignes, frequence, dateFin, invoiceRef, acompte } = req.body;
// // // //   const userId = req.user.userId;

// // // //   console.log('Requête createInvoice:', { userId, number, clientName, amount });

// // // //   try {
// // // //     const invoice = new Invoice({ userId, number, clientName, amount });
// // // //     await invoice.save();
// // // //     console.log('Facture sauvegardée:', invoice);

// // // //     const entry = new JournalEntry({
// // // //       userId,
// // // //       description: `Facture ${number} pour ${clientName}`,
// // // //       debitEntityType: 'Client',
// // // //       debitEntityName: clientName,
// // // //       creditEntityType: 'Ventes',
// // // //       creditEntityName: 'Ventes',
// // // //       amount,
// // // //     });
// // // //     await entry.save();
// // // //     console.log('Écriture comptable sauvegardée:', entry);

// // // //     res.status(201).json(invoice);
// // // //   } catch (err) {
// // // //     console.error('Erreur dans createInvoice:', err);
// // // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // // //   }
// // // // };

// // // // exports.getInvoices = async (req, res) => {
// // // //   const userId = req.user.userId;
// // // //   try {
// // // //     const invoices = await Invoice.find({ userId });
// // // //     res.status(200).json(invoices);
// // // //   } catch (err) {
// // // //     console.error('Erreur dans getInvoices:', err);
// // // //     res.status(500).json({ error: 'Erreur serveur' });
// // // //   }
// // // // };

// // // // exports.updateInvoiceStatus = async (req, res) => {
// // // //   const { invoiceId, status } = req.body;
// // // //   const userId = req.user.userId;

// // // //   try {
// // // //     const invoice = await Invoice.findOneAndUpdate(
// // // //       { _id: invoiceId, userId },
// // // //       { status },
// // // //       { new: true }
// // // //     );
// // // //     if (!invoice) return res.status(404).json({ error: 'Facture non trouvée' });

// // // //     if (status === 'paid') {
// // // //       const entry = new JournalEntry({
// // // //         userId,
// // // //         description: `Paiement facture ${invoice.number}`,
// // // //         debitEntityType: 'Banque',
// // // //         debitEntityName: 'Banque Populaire',
// // // //         creditEntityType: 'Client',
// // // //         creditEntityName: invoice.clientName,
// // // //         amount: invoice.amount,
// // // //       });
// // // //       await entry.save();
// // // //     }

// // // //     res.status(200).json(invoice);
// // // //   } catch (err) {
// // // //     console.error('Erreur dans updateInvoiceStatus:', err);
// // // //     res.status(500).json({ error: 'Erreur serveur' });
// // // //   }
// // // // };

// // // // // Nouvelle méthode : Supprimer une facture
// // // // exports.deleteInvoice = async (req, res) => {
// // // //   const invoiceId = req.params.id;
// // // //   const userId = req.user.userId;

// // // //   console.log('Requête deleteInvoice:', { invoiceId, userId });

// // // //   try {
// // // //     const invoice = await Invoice.findOneAndDelete({ _id: invoiceId, userId });
// // // //     if (!invoice) {
// // // //       return res.status(404).json({ error: 'Facture non trouvée' });
// // // //     }
// // // //     console.log('Facture supprimée:', invoice);

// // // //     // Optionnel : Supprimer ou ajuster les écritures comptables associées
// // // //     // await JournalEntry.deleteOne({ description: `Facture ${invoice.number} pour ${invoice.clientName}` });

// // // //     res.status(200).json({ message: 'Facture supprimée avec succès' });
// // // //   } catch (err) {
// // // //     console.error('Erreur dans deleteInvoice:', err);
// // // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // // //   }
// // // // };

// // // // // Nouvelle méthode : Mettre à jour une facture
// // // // exports.updateInvoice = async (req, res) => {
// // // //   const invoiceId = req.params.id;
// // // //   const userId = req.user.userId;
// // // //   const { number, clientName, amount } = req.body;

// // // //   console.log('Requête updateInvoice:', { invoiceId, userId, number, clientName, amount });

// // // //   try {
// // // //     const invoice = await Invoice.findOneAndUpdate(
// // // //       { _id: invoiceId, userId },
// // // //       { number, clientName, amount },
// // // //       { new: true }
// // // //     );
// // // //     if (!invoice) {
// // // //       return res.status(404).json({ error: 'Facture non trouvée' });
// // // //     }
// // // //     console.log('Facture mise à jour:', invoice);

// // // //     // Optionnel : Mettre à jour l’écriture comptable associée
// // // //     await JournalEntry.updateOne(
// // // //       { description: `Facture ${invoice.number} pour ${invoice.clientName}` },
// // // //       {
// // // //         description: `Facture ${number} pour ${clientName}`,
// // // //         debitEntityName: clientName,
// // // //         amount,
// // // //       }
// // // //     );

// // // //     res.status(200).json(invoice);
// // // //   } catch (err) {
// // // //     console.error('Erreur dans updateInvoice:', err);
// // // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // // //   }

  

// // // //   try {
// // // //     const invoiceData = {
// // // //       numero: numero || `CF-${new Date().getFullYear()}-${Math.floor(Math.random() * 10000)}`,
// // // //       type,
// // // //       statut: 'brouillon',
// // // //       dateEmission: new Date(),
// // // //       dateEcheance: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
// // // //       clientNom,
// // // //       lignes,
// // // //       userId,
// // // //       frequence: type === 'recurrente' ? frequence : undefined,
// // // //       dateFin: type === 'recurrente' && dateFin ? new Date(dateFin) : undefined,
// // // //       invoiceRef: ['acompte', 'avoir'].includes(type) ? invoiceRef : undefined,
// // // //       acompte: type === 'acompte' ? acompte : 0,
// // // //     };
// // // //     invoiceData.totalHT = lignes.reduce((sum, l) => sum + (l.quantite * l.prixUnitaire - l.remise - l.rabais - l.ristourne), 0);
// // // //     invoiceData.totalTVA = lignes.reduce((sum, l) => sum + ((l.quantite * l.prixUnitaire - l.remise - l.rabais - l.ristourne) * (l.tva / 100)), 0);
// // // //     invoiceData.totalTTC = type === 'avoir' ? -(invoiceData.totalHT + invoiceData.totalTVA) : invoiceData.totalHT + invoiceData.totalTVA;

// // // //     const invoice = new Invoice(invoiceData);
// // // //     await invoice.save();

// // // //     if (['standard', 'acompte'].includes(type)) {
// // // //       const entry = new JournalEntry({
// // // //         userId,
// // // //         description: `Facture ${numero} pour ${clientNom}`,
// // // //         debitEntityType: 'Client',
// // // //         debitEntityName: clientNom,
// // // //         creditEntityType: 'Ventes',
// // // //         creditEntityName: 'Ventes',
// // // //         amount: invoice.totalTTC,
// // // //       });
// // // //       await entry.save();
// // // //     }

// // // //     res.status(201).json(invoice);
// // // //   } catch (err) {
// // // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // // //   }
// // // // };

// // // // // Conversion devis -> facture
// // // // exports.convertDevis = async (req, res) => {
// // // //   const { id } = req.params;
// // // //   try {
// // // //     const devis = await Invoice.findById(id);
// // // //     if (devis.type !== 'devis') return res.status(400).json({ error: 'Non un devis' });
// // // //     devis.type = 'standard';
// // // //     devis.statut = 'brouillon';
// // // //     await devis.save();
// // // //     res.status(200).json(devis);
// // // //   } catch (err) {
// // // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // // //   }
// // // // };

// // // // // Annuler une facture
// // // // exports.cancelInvoice = async (req, res) => {
// // // //   const { id } = req.params;
// // // //   const { motifAnnulation } = req.body;
// // // //   try {
// // // //     const invoice = await Invoice.findById(id);
// // // //     if (!invoice) return res.status(404).json({ error: 'Facture non trouvée' });
// // // //     invoice.statut = 'annulee';
// // // //     invoice.motifAnnulation = motifAnnulation;
// // // //     await invoice.save();
// // // //     res.status(200).json(invoice);
// // // //   } catch (err) {
// // // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // // //   }
// // // // };




// // // //invoice.controller.js
// // // // Importation des modules nécessaires

// // // const mongoose = require('mongoose');
// // // const Invoice = require('../models/invoice.model');
// // // const JournalEntry = require('../models/journal_entry.model');
// // // const cron = require('node-cron');
// // // const { v4: uuidv4 } = require('uuid');

// // // // Helper function to calculate invoice totals
// // // const calculateTotals = (lignes, isAvoir = false) => {
// // //   if (!lignes || !Array.isArray(lignes) || lignes.length === 0) {
// // //     throw new Error('Lignes invalides ou absentes');
// // //   }

// // //   const totalHT = lignes.reduce(
// // //     (sum, ligne) => sum + (ligne.quantite * ligne.prixUnitaire - (ligne.remise || 0) - (ligne.rabais || 0) - (ligne.ristourne || 0)),
// // //     0
// // //   );
// // //   const totalTVA = lignes.reduce(
// // //     (sum, ligne) => sum + ((ligne.quantite * ligne.prixUnitaire - (ligne.remise || 0) - (ligne.rabais || 0) - (ligne.ristourne || 0)) * ((ligne.tva || 0) / 100)),
// // //     0
// // //   );
// // //   const totalTTC = totalHT + totalTVA;

// // //   return {
// // //     totalHT: Number(totalHT.toFixed(2)),
// // //     totalTVA: Number(totalTVA.toFixed(2)),
// // //     totalTTC: Number((isAvoir ? -totalTTC : totalTTC).toFixed(2)),
// // //   };
// // // };

// // // // Create a new invoice
// // // exports.createInvoice = async (req, res) => {
// // //   const {
// // //     type,
// // //     numero,
// // //     clientNom,
// // //     lignes,
// // //     frequence,
// // //     dateFin,
// // //     invoiceRef,
// // //     acompte,
// // //     dateEmission,
// // //     dateEcheance,
// // //   } = req.body;
// // //   const userId = req.user.userId;

// // //   try {
// // //     // Input validation
// // //     if (!['standard', 'recurrente', 'acompte', 'avoir', 'devis'].includes(type)) {
// // //       return res.status(400).json({ error: 'Type de facture invalide' });
// // //     }
// // //     if (!clientNom || typeof clientNom !== 'string' || clientNom.trim() === '') {
// // //       return res.status(400).json({ error: 'Nom du client requis' });
// // //     }
// // //     if (!lignes || !lignes.length) {
// // //       return res.status(400).json({ error: 'Au moins une ligne est requise' });
// // //     }
// // //     if (type === 'acompte' && (!mongoose.isValidObjectId(invoiceRef) || !acompte || acompte <= 0)) {
// // //       return res.status(400).json({ error: 'Référence de facture et montant d’acompte positif requis' });
// // //     }
// // //     if (type === 'avoir' && !mongoose.isValidObjectId(invoiceRef)) {
// // //       return res.status(400).json({ error: 'Référence de facture requise pour avoir' });
// // //     }
// // //     if (type === 'recurrente' && !['mensuelle', 'trimestrielle', 'annuelle'].includes(frequence)) {
// // //       return res.status(400).json({ error: 'Fréquence invalide pour facture récurrente' });
// // //     }

// // //     // Calculate totals
// // //     const { totalHT, totalTVA, totalTTC } = calculateTotals(lignes, type === 'avoir');

// // //     // Build invoice data
// // //     const invoiceData = {
// // //       userId,
// // //       numero: numero || `INV-${new Date().getFullYear()}-${uuidv4().slice(0, 8)}`,
// // //       type,
// // //       statut: type === 'devis' ? 'en_attente' : 'brouillon',
// // //       clientNom: clientNom.trim(),
// // //       lignes,
// // //       totalHT,
// // //       totalTVA,
// // //       totalTTC,
// // //       dateEmission: dateEmission ? new Date(dateEmission) : new Date(),
// // //       dateEcheance: dateEcheance ? new Date(dateEcheance) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
// // //       frequence: type === 'recurrente' ? frequence : undefined,
// // //       dateFin: type === 'recurrente' && dateFin ? new Date(dateFin) : undefined,
// // //       invoiceRef: ['acompte', 'avoir'].includes(type) ? invoiceRef : undefined,
// // //       acompte: type === 'acompte' ? Number(acompte.toFixed(2)) : 0,
// // //       createdAt: new Date(),
// // //     };

// // //     // Validate dateFin for recurring invoices
// // //     if (type === 'recurrente' && invoiceData.dateFin && invoiceData.dateFin <= invoiceData.dateEmission) {
// // //       return res.status(400).json({ error: 'La date de fin doit être postérieure à la date d’émission' });
// // //     }

// // //     // Save invoice
// // //     const invoice = new Invoice(invoiceData);
// // //     await invoice.save();

// // //     // Create journal entry for standard, acompte, or avoir
// // //     if (['standard', 'acompte', 'avoir'].includes(type)) {
// // //       const entry = new JournalEntry({
// // //         userId,
// // //         description: `${type === 'avoir' ? 'Avoir' : 'Facture'} ${invoice.numero} pour ${clientNom}`,
// // //         debitEntityType: type === 'avoir' ? 'Ventes' : 'Client',
// // //         debitEntityName: type === 'avoir' ? 'Ventes' : clientNom,
// // //         creditEntityType: type === 'avoir' ? 'Client' : 'Ventes',
// // //         creditEntityName: type === 'avoir' ? clientNom : 'Ventes',
// // //         amount: type === 'acompte' ? invoice.acompte : Math.abs(invoice.totalTTC),
// // //         createdAt: new Date(),
// // //       });
// // //       await entry.save();
// // //     }

// // //     // Schedule recurring invoices
// // //     if (type === 'recurrente') {
// // //       let cronExpression;
// // //       switch (frequence) {
// // //         case 'mensuelle':
// // //           cronExpression = '0 0 1 * *'; // 1st of every month
// // //           break;
// // //         case 'trimestrielle':
// // //           cronExpression = '0 0 1 */3 *'; // 1st of every 3 months
// // //           break;
// // //         case 'annuelle':
// // //           cronExpression = '0 0 1 1 *'; // 1st of every year
// // //           break;
// // //         default:
// // //           throw new Error('Fréquence invalide');
// // //       }

// // //       cron.schedule(cronExpression, async () => {
// // //         try {
// // //           if (invoiceData.dateFin && new Date() > invoiceData.dateFin) return;

// // //           const newInvoice = new Invoice({
// // //             ...invoiceData,
// // //             numero: `${invoiceData.numero}-${Date.now()}`,
// // //             type: 'standard',
// // //             statut: 'brouillon',
// // //             dateEmission: new Date(),
// // //             dateEcheance: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
// // //             frequence: undefined,
// // //             dateFin: undefined,
// // //             invoiceRef: undefined,
// // //             acompte: 0,
// // //             createdAt: new Date(),
// // //           });
// // //           await newInvoice.save();

// // //           const entry = new JournalEntry({
// // //             userId,
// // //             description: `Facture récurrente ${newInvoice.numero} pour ${clientNom}`,
// // //             debitEntityType: 'Client',
// // //             debitEntityName: clientNom,
// // //             creditEntityType: 'Ventes',
// // //             creditEntityName: 'Ventes',
// // //             amount: newInvoice.totalTTC,
// // //             createdAt: new Date(),
// // //           });
// // //           await entry.save();
// // //         } catch (err) {
// // //           console.error(`Erreur génération facture récurrente ${invoice.numero}:`, err);
// // //         }
// // //       });
// // //     }

// // //     res.status(201).json(invoice);
// // //   } catch (err) {
// // //     console.error('Erreur createInvoice:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };

// // // // Get all invoices for a user
// // // exports.getInvoices = async (req, res) => {
// // //   const userId = req.user.userId;
// // //   const { page = 1, limit = 10, type, statut, search } = req.query;

// // //   try {
// // //     const query = { userId };
// // //     if (type) query.type = type;
// // //     if (statut) query.statut = statut;
// // //     if (search) {
// // //       query.$or = [
// // //         { numero: { $regex: search, $options: 'i' } },
// // //         { clientNom: { $regex: search, $options: 'i' } },
// // //       ];
// // //     }

// // //     const invoices = await Invoice.find(query)
// // //       .skip((Number(page) - 1) * Number(limit))
// // //       .limit(Number(limit))
// // //       .sort({ createdAt: -1 })
// // //       .lean();
// // //     const total = await Invoice.countDocuments(query);

// // //     res.status(200).json({
// // //       invoices,
// // //       total,
// // //       page: Number(page),
// // //       limit: Number(limit),
// // //     });
// // //   } catch (err) {
// // //     console.error('Erreur getInvoices:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };

// // // // Get a single invoice
// // // exports.getInvoice = async (req, res) => {
// // //   const { id } = req.params;
// // //   const userId = req.user.userId;

// // //   try {
// // //     if (!mongoose.isValidObjectId(id)) {
// // //       return res.status(400).json({ error: 'ID de facture invalide' });
// // //     }

// // //     const invoice = await Invoice.findOne({ _id: id, userId }).lean();
// // //     if (!invoice) {
// // //       return res.status(404).json({ error: 'Facture non trouvée' });
// // //     }

// // //     res.status(200).json(invoice);
// // //   } catch (err) {
// // //     console.error('Erreur getInvoice:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };

// // // // Update invoice status
// // // exports.updateInvoiceStatus = async (req, res) => {
// // //   const { id } = req.params;
// // //   const { statut } = req.body;
// // //   const userId = req.user.userId;

// // //   try {
// // //     if (!mongoose.isValidObjectId(id)) {
// // //       return res.status(400).json({ error: 'ID de facture invalide' });
// // //     }
// // //     if (!['brouillon', 'envoyee', 'payee', 'en_attente', 'accepte', 'refuse'].includes(statut)) {
// // //       return res.status(400).json({ error: 'Statut invalide' });
// // //     }

// // //     const invoice = await Invoice.findOne({ _id: id, userId });
// // //     if (!invoice) {
// // //       return res.status(404).json({ error: 'Facture non trouvée' });
// // //     }
// // //     if (invoice.statut === 'annulee') {
// // //       return res.status(400).json({ error: 'Facture annulée ne peut pas être modifiée' });
// // //     }
// // //     if (invoice.type === 'devis' && !['en_attente', 'accepte', 'refuse'].includes(statut)) {
// // //       return res.status(400).json({ error: 'Statut invalide pour un devis' });
// // //     }

// // //     invoice.statut = statut;
// // //     await invoice.save();

// // //     // Record payment if status is 'payee'
// // //     if (statut === 'payee' && invoice.type !== 'avoir') {
// // //       const entry = new JournalEntry({
// // //         userId,
// // //         description: `Paiement facture ${invoice.numero} pour ${invoice.clientNom}`,
// // //         debitEntityType: 'Banque',
// // //         debitEntityName: 'Compte Bancaire',
// // //         creditEntityType: 'Client',
// // //         creditEntityName: invoice.clientNom,
// // //         amount: invoice.type === 'acompte' ? invoice.acompte : invoice.totalTTC,
// // //         createdAt: new Date(),
// // //       });
// // //       await entry.save();
// // //     }

// // //     res.status(200).json(invoice);
// // //   } catch (err) {
// // //     console.error('Erreur updateInvoiceStatus:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };

// // // // Update an invoice
// // // exports.updateInvoice = async (req, res) => {
// // //   const { id } = req.params;
// // //   const { numero, clientNom, lignes, dateEmission, dateEcheance } = req.body;
// // //   const userId = req.user.userId;

// // //   try {
// // //     if (!mongoose.isValidObjectId(id)) {
// // //       return res.status(400).json({ error: 'ID de facture invalide' });
// // //     }

// // //     const invoice = await Invoice.findOne({ _id: id, userId });
// // //     if (!invoice) {
// // //       return res.status(404).json({ error: 'Facture non trouvée' });
// // //     }
// // //     if (invoice.statut === 'annulee' || invoice.statut === 'payee') {
// // //       return res.status(400).json({ error: 'Facture annulée ou payée ne peut pas être modifiée' });
// // //     }

// // //     const { totalHT, totalTVA, totalTTC } = calculateTotals(lignes || invoice.lignes, invoice.type === 'avoir');

// // //     invoice.numero = numero && numero.trim() ? numero.trim() : invoice.numero;
// // //     invoice.clientNom = clientNom && clientNom.trim() ? clientNom.trim() : invoice.clientNom;
// // //     invoice.lignes = lignes || invoice.lignes;
// // //     invoice.totalHT = totalHT;
// // //     invoice.totalTVA = totalTVA;
// // //     invoice.totalTTC = totalTTC;
// // //     invoice.dateEmission = dateEmission ? new Date(dateEmission) : invoice.dateEmission;
// // //     invoice.dateEcheance = dateEcheance ? new Date(dateEcheance) : invoice.dateEcheance;

// // //     await invoice.save();
// // //     res.status(200).json(invoice);
// // //   } catch (err) {
// // //     console.error('Erreur updateInvoice:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };

// // // // Delete an invoice
// // // // exports.deleteInvoice = async (req, res) => {
// // // //   const { id } = req.params;
// // // //   const userId = req.user.userId;

// // // //   try {
// // // //     if (!mongoose.isValidObjectId(id)) {
// // // //       return res.status(400).json({ error: 'ID de facture invalide' });
// // // //     }

// // // //     const invoice = await Invoice.findOne({ _id: id, userId });
// // // //     if (!invoice) {
// // // //       return res.status(404).json({ error: 'Facture non trouvée' });
// // // //     }
// // // //     if (invoice.statut === 'payee' || invoice.statut === 'annulee') {
// // // //       return res.status(400).json({ error: 'Facture payée ou annulée ne peut pas être supprimée' });
// // // //     }

// // // //     await Invoice.deleteOne({ _id: id, userId });
// // // //     res.status(200).json({ message: 'Facture supprimée avec succès' });
// // // //   } catch (err) {
// // // //     console.error('Erreur deleteInvoice:', err.message);
// // // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // // //   }
// // // // };
// // // exports.deleteInvoice = async (req, res) => {
// // //   const { id } = req.params;
// // //   const userId = req.user.userId;
// // //   try {
// // //     if (!mongoose.isValidObjectId(id)) {
// // //       return res.status(400).json({ error: 'ID de facture invalide' });
// // //     }
// // //     const invoice = await Invoice.findOne({ _id: id, userId });
// // //     if (!invoice) {
// // //       return res.status(404).json({ error: 'Facture non trouvée' });
// // //     }
// // //     if (invoice.statut === 'payee' || invoice.statut === 'annulee') {
// // //       return res.status(400).json({ error: 'Facture payée ou annulée ne peut pas être supprimée' });
// // //     }
// // //     await Invoice.deleteOne({ _id: id, userId });
// // //     res.status(200).json({ message: 'Facture supprimée avec succès' });
// // //   } catch (err) {
// // //     console.error('Erreur deleteInvoice:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };

// // // // Cancel an invoice
// // // exports.cancelInvoice = async (req, res) => {
// // //   const { id } = req.params;
// // //   const { motifAnnulation } = req.body;
// // //   const userId = req.user.userId;

// // //   try {
// // //     if (!mongoose.isValidObjectId(id)) {
// // //       return res.status(400).json({ error: 'ID de facture invalide' });
// // //     }
// // //     if (!motifAnnulation || typeof motifAnnulation !== 'string' || motifAnnulation.trim() === '') {
// // //       return res.status(400).json({ error: 'Motif d’annulation requis' });
// // //     }

// // //     const invoice = await Invoice.findOne({ _id: id, userId });
// // //     if (!invoice) {
// // //       return res.status(404).json({ error: 'Facture non trouvée' });
// // //     }
// // //     if (invoice.statut === 'annulee') {
// // //       return res.status(400).json({ error: 'Facture déjà annulée' });
// // //     }
// // //     if (invoice.statut === 'payee') {
// // //       return res.status(400).json({ error: 'Facture payée ne peut pas être annulée' });
// // //     }

// // //     invoice.statut = 'annulee';
// // //     invoice.motifAnnulation = motifAnnulation.trim();
// // //     await invoice.save();

// // //     res.status(200).json(invoice);
// // //   } catch (err) {
// // //     console.error('Erreur cancelInvoice:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };

// // // // Convert a devis to a standard invoice
// // // exports.convertDevis = async (req, res) => {
// // //   const { id } = req.params;
// // //   const userId = req.user.userId;

// // //   try {
// // //     if (!mongoose.isValidObjectId(id)) {
// // //       return res.status(400).json({ error: 'ID de devis invalide' });
// // //     }

// // //     const invoice = await Invoice.findOne({ _id: id, userId, type: 'devis' });
// // //     if (!invoice) {
// // //       return res.status(404).json({ error: 'Devis non trouvé' });
// // //     }
// // //     if (invoice.statut !== 'accepte') {
// // //       return res.status(400).json({ error: 'Le devis doit être accepté avant conversion' });
// // //     }

// // //     invoice.type = 'standard';
// // //     invoice.statut = 'brouillon';
// // //     await invoice.save();

// // //     const entry = new JournalEntry({
// // //       userId,
// // //       description: `Facture ${invoice.numero} pour ${invoice.clientNom}`,
// // //       debitEntityType: 'Client',
// // //       debitEntityName: invoice.clientNom,
// // //       creditEntityType: 'Ventes',
// // //       creditEntityName: 'Ventes',
// // //       amount: invoice.totalTTC,
// // //       createdAt: new Date(),
// // //     });
// // //     await entry.save();

// // //     res.status(200).json(invoice);
// // //   } catch (err) {
// // //     console.error('Erreur convertDevis:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };

// // // // Create final invoice after acompte
// // // exports.createFinalInvoice = async (req, res) => {
// // //   const { acompteInvoiceId, numero, clientNom, lignes, dateEmission, dateEcheance } = req.body;
// // //   const userId = req.user.userId;

// // //   try {
// // //     if (!mongoose.isValidObjectId(acompteInvoiceId)) {
// // //       return res.status(400).json({ error: 'ID de facture d’acompte invalide' });
// // //     }
// // //     if (!clientNom || typeof clientNom !== 'string' || clientNom.trim() === '') {
// // //       return res.status(400).json({ error: 'Nom du client requis' });
// // //     }
// // //     if (!lignes || !lignes.length) {
// // //       return res.status(400).json({ error: 'Au moins une ligne est requise' });
// // //     }

// // //     const acompteInvoice = await Invoice.findOne({ _id: acompteInvoiceId, userId, type: 'acompte' });
// // //     if (!acompteInvoice) {
// // //       return res.status(404).json({ error: 'Facture d’acompte non trouvée' });
// // //     }

// // //     const { totalHT, totalTVA, totalTTC } = calculateTotals(lignes);
// // //     const adjustedTTC = Number((totalTTC - acompteInvoice.acompte).toFixed(2));

// // //     if (adjustedTTC < 0) {
// // //       return res.status(400).json({ error: 'Le montant final ne peut pas être négatif' });
// // //     }

// // //     const invoiceData = {
// // //       userId,
// // //       numero: numero || `INV-${new Date().getFullYear()}-${uuidv4().slice(0, 8)}`,
// // //       type: 'standard',
// // //       statut: 'brouillon',
// // //       clientNom: clientNom.trim(),
// // //       lignes,
// // //       totalHT,
// // //       totalTVA,
// // //       totalTTC: adjustedTTC,
// // //       dateEmission: dateEmission ? new Date(dateEmission) : new Date(),
// // //       dateEcheance: dateEcheance ? new Date(dateEcheance) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
// // //       invoiceRef: acompteInvoice._id,
// // //       createdAt: new Date(),
// // //     };

// // //     const invoice = new Invoice(invoiceData);
// // //     await invoice.save();

// // //     const entry = new JournalEntry({
// // //       userId,
// // //       description: `Facture finale ${invoice.numero} pour ${clientNom}`,
// // //       debitEntityType: 'Client',
// // //       debitEntityName: clientNom,
// // //       creditEntityType: 'Ventes',
// // //       creditEntityName: 'Ventes',
// // //       amount: invoice.totalTTC,
// // //       createdAt: new Date(),
// // //     });
// // //     await entry.save();

// // //     res.status(201).json(invoice);
// // //   } catch (err) {
// // //     console.error('Erreur createFinalInvoice:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };



// // // // filepath: backend/controllers/invoice.controller.js
// // // // filepath: backend/controllers/invoice.controller.js

// // // const mongoose = require('mongoose');
// // // const Invoice = require('../models/invoice.model');
// // // const JournalEntry = require('../models/journal_entry.model');
// // // const cron = require('node-cron');
// // // const { v4: uuidv4 } = require('uuid');

// // // // Helper function to calculate invoice totals
// // // const calculateTotals = (lignes, isAvoir = false) => {
// // //   if (!lignes || !Array.isArray(lignes) || lignes.length === 0) {
// // //     throw new Error('Lignes invalides ou absentes');
// // //   }

// // //   const totalHT = lignes.reduce(
// // //     (sum, ligne) => sum + (ligne.quantite * ligne.prixUnitaire - (ligne.remise || 0) - (ligne.rabais || 0) - (ligne.ristourne || 0)),
// // //     0
// // //   );
// // //   const totalTVA = lignes.reduce(
// // //     (sum, ligne) => sum + ((ligne.quantite * ligne.prixUnitaire - (ligne.remise || 0) - (ligne.rabais || 0) - (ligne.ristourne || 0)) * ((ligne.tva || 0) / 100)),
// // //     0
// // //   );
// // //   const totalTTC = totalHT + totalTVA;

// // //   return {
// // //     totalHT: Number(totalHT.toFixed(2)),
// // //     totalTVA: Number(totalTVA.toFixed(2)),
// // //     totalTTC: Number((isAvoir ? -totalTTC : totalTTC).toFixed(2)),
// // //   };
// // // };

// // // // Create a new invoice
// // // exports.createInvoice = async (req, res) => {
// // //   const {
// // //     type,
// // //     numero,
// // //     clientNom,
// // //     lignes,
// // //     frequence,
// // //     dateFin,
// // //     invoiceRef,
// // //     acompte,
// // //     dateEmission,
// // //     dateEcheance,
// // //   } = req.body;
// // //   const userId = req.user.userId;

// // //   try {
// // //     if (!['standard', 'recurrente', 'acompte', 'avoir', 'devis'].includes(type)) {
// // //       return res.status(400).json({ error: 'Type de facture invalide' });
// // //     }
// // //     if (!clientNom || typeof clientNom !== 'string' || clientNom.trim() === '') {
// // //       return res.status(400).json({ error: 'Nom du client requis' });
// // //     }
// // //     if (!lignes || !lignes.length) {
// // //       return res.status(400).json({ error: 'Au moins une ligne est requise' });
// // //     }
// // //     if (type === 'acompte' && (!mongoose.isValidObjectId(invoiceRef) || !acompte || acompte <= 0)) {
// // //       return res.status(400).json({ error: 'Référence de facture et montant d’acompte positif requis' });
// // //     }
// // //     if (type === 'avoir' && !mongoose.isValidObjectId(invoiceRef)) {
// // //       return res.status(400).json({ error: 'Référence de facture requise pour avoir' });
// // //     }
// // //     if (type === 'recurrente' && !['mensuelle', 'trimestrielle', 'annuelle'].includes(frequence)) {
// // //       return res.status(400).json({ error: 'Fréquence invalide pour facture récurrente' });
// // //     }

// // //     const { totalHT, totalTVA, totalTTC } = calculateTotals(lignes, type === 'avoir');

// // //     const invoiceData = {
// // //       userId,
// // //       numero: numero || `INV-${new Date().getFullYear()}-${uuidv4().slice(0, 8)}`,
// // //       type,
// // //       statut: type === 'devis' ? 'en_attente' : 'brouillon',
// // //       clientNom: clientNom.trim(),
// // //       lignes,
// // //       totalHT,
// // //       totalTVA,
// // //       totalTTC,
// // //       dateEmission: dateEmission ? new Date(dateEmission) : new Date(),
// // //       dateEcheance: dateEcheance ? new Date(dateEcheance) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
// // //       frequence: type === 'recurrente' ? frequence : undefined,
// // //       dateFin: type === 'recurrente' && dateFin ? new Date(dateFin) : undefined,
// // //       invoiceRef: ['acompte', 'avoir'].includes(type) ? invoiceRef : undefined,
// // //       acompte: type === 'acompte' ? Number(acompte.toFixed(2)) : 0,
// // //       createdAt: new Date(),
// // //     };

// // //     if (type === 'recurrente' && invoiceData.dateFin && invoiceData.dateFin <= invoiceData.dateEmission) {
// // //       return res.status(400).json({ error: 'La date de fin doit être postérieure à la date d’émission' });
// // //     }

// // //     const invoice = new Invoice(invoiceData);
// // //     await invoice.save();

// // //     if (['standard', 'acompte', 'avoir'].includes(type)) {
// // //       const entry = new JournalEntry({
// // //         userId,
// // //         description: `${type === 'avoir' ? 'Avoir' : 'Facture'} ${invoice.numero} pour ${clientNom}`,
// // //         debitEntityType: type === 'avoir' ? 'Ventes' : 'Client',
// // //         debitEntityName: type === 'avoir' ? 'Ventes' : clientNom,
// // //         creditEntityType: type === 'avoir' ? 'Client' : 'Ventes',
// // //         creditEntityName: type === 'avoir' ? clientNom : 'Ventes',
// // //         amount: type === 'acompte' ? invoice.acompte : Math.abs(invoice.totalTTC),
// // //         createdAt: new Date(),
// // //       });
// // //       await entry.save();
// // //     }

// // //     if (type === 'recurrente') {
// // //       let cronExpression;
// // //       switch (frequence) {
// // //         case 'mensuelle':
// // //           cronExpression = '0 0 1 * *';
// // //           break;
// // //         case 'trimestrielle':
// // //           cronExpression = '0 0 1 */3 *';
// // //           break;
// // //         case 'annuelle':
// // //           cronExpression = '0 0 1 1 *';
// // //           break;
// // //         default:
// // //           throw new Error('Fréquence invalide');
// // //       }

// // //       cron.schedule(cronExpression, async () => {
// // //         try {
// // //           if (invoiceData.dateFin && new Date() > invoiceData.dateFin) return;

// // //           const newInvoice = new Invoice({
// // //             ...invoiceData,
// // //             numero: `${invoiceData.numero}-${Date.now()}`,
// // //             type: 'standard',
// // //             statut: 'brouillon',
// // //             dateEmission: new Date(),
// // //             dateEcheance: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
// // //             frequence: undefined,
// // //             dateFin: undefined,
// // //             invoiceRef: undefined,
// // //             acompte: 0,
// // //             createdAt: new Date(),
// // //           });
// // //           await newInvoice.save();

// // //           const entry = new JournalEntry({
// // //             userId,
// // //             description: `Facture récurrente ${newInvoice.numero} pour ${clientNom}`,
// // //             debitEntityType: 'Client',
// // //             debitEntityName: clientNom,
// // //             creditEntityType: 'Ventes',
// // //             creditEntityName: 'Ventes',
// // //             amount: newInvoice.totalTTC,
// // //             createdAt: new Date(),
// // //           });
// // //           await entry.save();
// // //         } catch (err) {
// // //           console.error(`Erreur génération facture récurrente ${invoice.numero}:`, err);
// // //         }
// // //       });
// // //     }

// // //     res.status(201).json(invoice);
// // //   } catch (err) {
// // //     console.error('Erreur createInvoice:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };

// // // // Get all invoices for a user
// // // exports.getInvoices = async (req, res) => {
// // //   const userId = req.user.userId;
// // //   const { page = 1, limit = 10, type, statut, search } = req.query;

// // //   try {
// // //     const query = { userId };
// // //     if (type) query.type = type;
// // //     if (statut) query.statut = statut;
// // //     if (search) {
// // //       query.$or = [
// // //         { numero: { $regex: search, $options: 'i' } },
// // //         { clientNom: { $regex: search, $options: 'i' } },
// // //       ];
// // //     }

// // //     const invoices = await Invoice.find(query)
// // //       .skip((Number(page) - 1) * Number(limit))
// // //       .limit(Number(limit))
// // //       .sort({ createdAt: -1 })
// // //       .lean();
// // //     const total = await Invoice.countDocuments(query);

// // //     res.status(200).json({
// // //       invoices,
// // //       total,
// // //       page: Number(page),
// // //       limit: Number(limit),
// // //     });
// // //   } catch (err) {
// // //     console.error('Erreur getInvoices:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };

// // // // Get a single invoice
// // // exports.getInvoice = async (req, res) => {
// // //   const { id } = req.params;
// // //   const userId = req.user.userId;

// // //   try {
// // //     if (!mongoose.isValidObjectId(id)) {
// // //       return res.status(400).json({ error: 'ID de facture invalide' });
// // //     }

// // //     const invoice = await Invoice.findOne({ _id: id, userId }).lean();
// // //     if (!invoice) {
// // //       return res.status(404).json({ error: 'Facture non trouvée' });
// // //     }

// // //     res.status(200).json(invoice);
// // //   } catch (err) {
// // //     console.error('Erreur getInvoice:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };

// // // // Update invoice status
// // // exports.updateInvoiceStatus = async (req, res) => {
// // //   const { id } = req.params;
// // //   const { statut } = req.body;
// // //   const userId = req.user.userId;

// // //   try {
// // //     if (!mongoose.isValidObjectId(id)) {
// // //       return res.status(400).json({ error: 'ID de facture invalide' });
// // //     }
// // //     if (!['brouillon', 'envoyee', 'payee', 'en_attente', 'accepte', 'refuse'].includes(statut)) {
// // //       return res.status(400).json({ error: 'Statut invalide' });
// // //     }

// // //     const invoice = await Invoice.findOne({ _id: id, userId });
// // //     if (!invoice) {
// // //       return res.status(404).json({ error: 'Facture non trouvée' });
// // //     }
// // //     if (invoice.statut === 'annulee') {
// // //       return res.status(400).json({ error: 'Facture annulée ne peut pas être modifiée' });
// // //     }
// // //     if (invoice.type === 'devis' && !['en_attente', 'accepte', 'refuse'].includes(statut)) {
// // //       return res.status(400).json({ error: 'Statut invalide pour un devis' });
// // //     }

// // //     invoice.statut = statut;
// // //     await invoice.save();

// // //     if (statut === 'payee' && invoice.type !== 'avoir') {
// // //       const entry = new JournalEntry({
// // //         userId,
// // //         description: `Paiement facture ${invoice.numero} pour ${invoice.clientNom}`,
// // //         debitEntityType: 'Banque',
// // //         debitEntityName: 'Compte Bancaire',
// // //         creditEntityType: 'Client',
// // //         creditEntityName: invoice.clientNom,
// // //         amount: invoice.type === 'acompte' ? invoice.acompte : invoice.totalTTC,
// // //         createdAt: new Date(),
// // //       });
// // //       await entry.save();
// // //     }

// // //     res.status(200).json(invoice);
// // //   } catch (err) {
// // //     console.error('Erreur updateInvoiceStatus:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };

// // // // Update an invoice
// // // exports.updateInvoice = async (req, res) => {
// // //   const { id } = req.params;
// // //   const { numero, clientNom, lignes, dateEmission, dateEcheance } = req.body;
// // //   const userId = req.user.userId;

// // //   try {
// // //     if (!mongoose.isValidObjectId(id)) {
// // //       return res.status(400).json({ error: 'ID de facture invalide' });
// // //     }

// // //     const invoice = await Invoice.findOne({ _id: id, userId });
// // //     if (!invoice) {
// // //       return res.status(404).json({ error: 'Facture non trouvée' });
// // //     }
// // //     if (invoice.statut === 'annulee' || invoice.statut === 'payee') {
// // //       return res.status(400).json({ error: 'Facture annulée ou payée ne peut pas être modifiée' });
// // //     }

// // //     const { totalHT, totalTVA, totalTTC } = calculateTotals(lignes || invoice.lignes, invoice.type === 'avoir');

// // //     invoice.numero = numero && numero.trim() ? numero.trim() : invoice.numero;
// // //     invoice.clientNom = clientNom && clientNom.trim() ? clientNom.trim() : invoice.clientNom;
// // //     invoice.lignes = lignes || invoice.lignes;
// // //     invoice.totalHT = totalHT;
// // //     invoice.totalTVA = totalTVA;
// // //     invoice.totalTTC = totalTTC;
// // //     invoice.dateEmission = dateEmission ? new Date(dateEmission) : invoice.dateEmission;
// // //     invoice.dateEcheance = dateEcheance ? new Date(dateEcheance) : invoice.dateEcheance;

// // //     await invoice.save();
// // //     res.status(200).json(invoice);
// // //   } catch (err) {
// // //     console.error('Erreur updateInvoice:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };

// // // // Delete an invoice
// // // exports.deleteInvoice = async (req, res) => {
// // //   const { id } = req.params;

// // //   try {
// // //     if (!mongoose.isValidObjectId(id)) {
// // //       console.log(`ID invalide: ${id}`);
// // //       return res.status(400).json({ error: 'ID de facture invalide' });
// // //     }

// // //     const invoice = await Invoice.findById(id);
// // //     if (!invoice) {
// // //       console.log(`Facture non trouvée: ${id}`);
// // //       return res.status(404).json({ error: 'Facture non trouvée' });
// // //     }
// // //     if (invoice.statut === 'payee' || invoice.statut === 'annulee') {
// // //       console.log(`Facture ${id} est payée ou annulée`);
// // //       return res.status(400).json({ error: 'Facture payée ou annulée ne peut pas être supprimée' });
// // //     }

// // //     const result = await Invoice.deleteOne({ _id: id });
// // //     if (result.deletedCount === 0) {
// // //       console.log(`Échec de la suppression: ${id}`);
// // //       return res.status(500).json({ error: 'Échec de la suppression de la facture' });
// // //     }

// // //     console.log(`Facture supprimée: ${id}`);
// // //     res.status(200).json({ message: 'Facture supprimée avec succès' });
// // //   } catch (err) {
// // //     console.error('Erreur deleteInvoice:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };
// // // // Cancel an invoice (restauré à la version originale)
// // // exports.cancelInvoice = async (req, res) => {
// // //   const { id } = req.params;
// // //   const { motif, statut } = req.body;
// // //   const userId = req.user ? req.user.userId : null;

// // //   try {
// // //     if (!mongoose.isValidObjectId(id)) {
// // //       return res.status(400).json({ error: 'ID de facture invalide' });
// // //     }
// // //     if (!motif || typeof motif !== 'string' || motif.trim() === '') {
// // //       return res.status(400).json({ error: 'Motif d’annulation requis' });
// // //     }
// // //     if (!userId) {
// // //       return res.status(401).json({ error: 'Utilisateur non authentifié' });
// // //     }

// // //     const invoice = await Invoice.findOne({ _id: id, userId });
// // //     if (!invoice) {
// // //       return res.status(404).json({ error: 'Facture non trouvée' });
// // //     }

// // //     // Liste des statuts valides
// // //     const statutsValides = ['brouillon', 'envoyee', 'payee', 'annulee'];
// // //     const statutsAutorisésPourAnnulation = ['brouillon', 'envoyee'];

// // //     // Mise à jour du statut si fourni
// // //     if (statut) {
// // //       if (!statutsValides.includes(statut)) {
// // //         return res.status(400).json({ error: `Statut fourni invalide: ${statut}. Statuts autorisés: ${statutsValides.join(', ')}` });
// // //       }
// // //       invoice.statut = statut;
// // //     }

// // //     // Validation du statut pour l'annulation
// // //     if (invoice.statut === 'annulee') {
// // //       return res.status(400).json({ error: 'Facture déjà annulée' });
// // //     }
// // //     if (invoice.statut === 'payee') {
// // //       return res.status(400).json({ error: 'Facture payée ne peut pas être annulée' });
// // //     }
// // //     if (!statutsAutorisésPourAnnulation.includes(invoice.statut)) {
// // //       return res.status(400).json({ error: `Statut actuel invalide pour l'annulation: ${invoice.statut}. Statuts autorisés: ${statutsAutorisésPourAnnulation.join(', ')}` });
// // //     }

// // //     invoice.statut = 'annulee';
// // //     invoice.motifAnnulation = motif.trim();
// // //     await invoice.save();

// // //     res.status(200).json(invoice);
// // //   } catch (err) {
// // //     console.error('Erreur cancelInvoice:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };
// // // // Convert a devis to a standard invoice
// // // exports.convertDevis = async (req, res) => {
// // //   const { id } = req.params;
// // //   const userId = req.user.userId;

// // //   try {
// // //     if (!mongoose.isValidObjectId(id)) {
// // //       return res.status(400).json({ error: 'ID de devis invalide' });
// // //     }

// // //     const invoice = await Invoice.findOne({ _id: id, userId, type: 'devis' });
// // //     if (!invoice) {
// // //       return res.status(404).json({ error: 'Devis non trouvé' });
// // //     }
// // //     if (invoice.statut !== 'accepte') {
// // //       return res.status(400).json({ error: 'Le devis doit être accepté avant conversion' });
// // //     }

// // //     invoice.type = 'standard';
// // //     invoice.statut = 'brouillon';
// // //     await invoice.save();

// // //     const entry = new JournalEntry({
// // //       userId,
// // //       description: `Facture ${invoice.numero} pour ${invoice.clientNom}`,
// // //       debitEntityType: 'Client',
// // //       debitEntityName: invoice.clientNom,
// // //       creditEntityType: 'Ventes',
// // //       creditEntityName: 'Ventes',
// // //       amount: invoice.totalTTC,
// // //       createdAt: new Date(),
// // //     });
// // //     await entry.save();

// // //     res.status(200).json(invoice);
// // //   } catch (err) {
// // //     console.error('Erreur convertDevis:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };

// // // // Create final invoice after acompte
// // // exports.createFinalInvoice = async (req, res) => {
// // //   const { acompteInvoiceId, numero, clientNom, lignes, dateEmission, dateEcheance } = req.body;
// // //   const userId = req.user.userId;

// // //   try {
// // //     if (!mongoose.isValidObjectId(acompteInvoiceId)) {
// // //       return res.status(400).json({ error: 'ID de facture d’acompte invalide' });
// // //     }
// // //     if (!clientNom || typeof clientNom !== 'string' || clientNom.trim() === '') {
// // //       return res.status(400).json({ error: 'Nom du client requis' });
// // //     }
// // //     if (!lignes || !lignes.length) {
// // //       return res.status(400).json({ error: 'Au moins une ligne est requise' });
// // //     }

// // //     const acompteInvoice = await Invoice.findOne({ _id: acompteInvoiceId, userId, type: 'acompte' });
// // //     if (!acompteInvoice) {
// // //       return res.status(404).json({ error: 'Facture d’acompte non trouvée' });
// // //     }

// // //     const { totalHT, totalTVA, totalTTC } = calculateTotals(lignes);
// // //     const adjustedTTC = Number((totalTTC - acompteInvoice.acompte).toFixed(2));

// // //     if (adjustedTTC < 0) {
// // //       return res.status(400).json({ error: 'Le montant final ne peut pas être négatif' });
// // //     }

// // //     const invoiceData = {
// // //       userId,
// // //       numero: numero || `INV-${new Date().getFullYear()}-${uuidv4().slice(0, 8)}`,
// // //       type: 'standard',
// // //       statut: 'brouillon',
// // //       clientNom: clientNom.trim(),
// // //       lignes,
// // //       totalHT,
// // //       totalTVA,
// // //       totalTTC: adjustedTTC,
// // //       dateEmission: dateEmission ? new Date(dateEmission) : new Date(),
// // //       dateEcheance: dateEcheance ? new Date(dateEcheance) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
// // //       invoiceRef: acompteInvoice._id,
// // //       createdAt: new Date(),
// // //     };

// // //     const invoice = new Invoice(invoiceData);
// // //     await invoice.save();

// // //     const entry = new JournalEntry({
// // //       userId,
// // //       description: `Facture finale ${invoice.numero} pour ${clientNom}`,
// // //       debitEntityType: 'Client',
// // //       debitEntityName: clientNom,
// // //       creditEntityType: 'Ventes',
// // //       creditEntityName: 'Ventes',
// // //       amount: invoice.totalTTC,
// // //       createdAt: new Date(),
// // //     });
// // //     await entry.save();

// // //     res.status(201).json(invoice);
// // //   } catch (err) {
// // //     console.error('Erreur createFinalInvoice:', err.message);
// // //     res.status(500).json({ error: 'Erreur serveur', details: err.message });
// // //   }
// // // };



// // // filepath: /Users/cavris/Desktop/projets/Systheme_Compta_PME/comptabilite_app_backend/src/controllers/invoice.controller.js

// const mongoose = require('mongoose');
// const Invoice = require('../models/invoice.model');
// const JournalEntry = require('../models/journal_entry.model');
// const cron = require('node-cron');
// const { v4: uuidv4 } = require('uuid');
// const PDFDocument = require('pdfkit');
// const fs = require('fs');
// const path = require('path');

// // Helper function to calculate invoice totals
// const calculateTotals = (lignes, isAvoir = false) => {
//   if (!lignes || !Array.isArray(lignes) || lignes.length === 0) {
//     throw new Error('Lignes invalides ou absentes');
//   }

//   const totalHT = lignes.reduce(
//     (sum, ligne) => sum + (ligne.quantite * ligne.prixUnitaire - (ligne.remise || 0) - (ligne.rabais || 0) - (ligne.ristourne || 0)),
//     0
//   );
//   const totalTVA = lignes.reduce(
//     (sum, ligne) => sum + ((ligne.quantite * ligne.prixUnitaire - (ligne.remise || 0) - (ligne.rabais || 0) - (ligne.ristourne || 0)) * ((ligne.tva || 0) / 100)),
//     0
//   );
//   const totalTTC = totalHT + totalTVA;

//   return {
//     totalHT: Number(totalHT.toFixed(2)),
//     totalTVA: Number(totalTVA.toFixed(2)),
//     totalTTC: Number((isAvoir ? -totalTTC : totalTTC).toFixed(2)),
//   };
// };

// // Create a new invoice
// exports.createInvoice = async (req, res) => {
//   const {
//     type,
//     numero,
//     clientNom,
//     clientAdresse,
//     clientTVA,
//     siret,
//     clientSiret,
//     adresseFournisseur,
//     penalitesRetard,
//     lignes,
//     fraisLivraison,
//     agios,
//     acompte,
//     devise,
//     frequence,
//     dateFin,
//     invoiceRef,
//     parentInvoice,
//     revisionPrix,
//     motifAvoir,
//     creditType,
//     validiteDevis,
//     version,
//     signature,
//     dateEmission,
//     dateEcheance,
//   } = req.body;
//   const userId = req.user.userId;

//   try {
//     if (!['standard', 'recurrente', 'acompte', 'avoir', 'devis'].includes(type)) {
//       return res.status(400).json({ error: 'Type de facture invalide' });
//     }
//     if (!clientNom || typeof clientNom !== 'string' || clientNom.trim() === '') {
//       return res.status(400).json({ error: 'Nom du client requis' });
//     }
//     if (!lignes || !lignes.length) {
//       return res.status(400).json({ error: 'Au moins une ligne est requise' });
//     }
//     if (type === 'acompte' && (!mongoose.isValidObjectId(invoiceRef) || !acompte || acompte <= 0)) {
//       return res.status(400).json({ error: 'Référence de facture et montant d’acompte positif requis' });
//     }
//     if (type === 'avoir' && !mongoose.isValidObjectId(invoiceRef)) {
//       return res.status(400).json({ error: 'Référence de facture requise pour avoir' });
//     }
//     if (type === 'recurrente' && !['mensuelle', 'trimestrielle', 'annuelle'].includes(frequence)) {
//       return res.status(400).json({ error: 'Fréquence invalide pour facture récurrente' });
//     }

//     const invoiceData = {
//       userId,
//       numero: numero || `INV-${new Date().getFullYear()}-${uuidv4().slice(0, 8)}`,
//       type,
//       statut: type === 'devis' ? 'enAttente' : 'brouillon',
//       clientNom: clientNom.trim(),
//       clientAdresse,
//       clientTVA,
//       siret,
//       clientSiret,
//       adresseFournisseur,
//       penalitesRetard: penalitesRetard || '5000 FCFA + 2% par mois',
//       lignes,
//       fraisLivraison: fraisLivraison || 0,
//       agios: agios || 0,
//       acompte: acompte || 0,
//       devise: devise || 'XOF',
//       invoiceRef: ['acompte', 'avoir'].includes(type) ? invoiceRef : undefined,
//       motifAnnulation: undefined,
//       frequence: type === 'recurrente' ? frequence : undefined,
//       dateFin: type === 'recurrente' && dateFin ? new Date(dateFin) : undefined,
//       parentInvoice,
//       revisionPrix,
//       motifAvoir,
//       creditType,
//       validiteDevis: validiteDevis ? new Date(validiteDevis) : undefined,
//       version: version || 1,
//       signature,
//       dateEmission: dateEmission ? new Date(dateEmission) : new Date(),
//       dateEcheance: dateEcheance ? new Date(dateEcheance) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
//       createdAt: new Date(),
//     };

//     if (type === 'recurrente' && invoiceData.dateFin && invoiceData.dateFin <= invoiceData.dateEmission) {
//       return res.status(400).json({ error: 'La date de fin doit être postérieure à la date d’émission' });
//     }

//     const invoice = new Invoice(invoiceData);
//     await invoice.save();

//     if (['standard', 'acompte', 'avoir'].includes(type)) {
//       const totals = calculateTotals(lignes, type === 'avoir');
//       const entry = new JournalEntry({
//         userId,
//         description: `${type === 'avoir' ? 'Avoir' : 'Facture'} ${invoice.numero} pour ${clientNom}`,
//         debitEntityType: type === 'avoir' ? 'Ventes' : 'Client',
//         debitEntityName: type === 'avoir' ? 'Ventes' : clientNom,
//         creditEntityType: type === 'avoir' ? 'Client' : 'Ventes',
//         creditEntityName: type === 'avoir' ? clientNom : 'Ventes',
//         amount: type === 'acompte' ? invoice.acompte : Math.abs(totals.totalTTC),
//         createdAt: new Date(),
//       });
//       await entry.save();
//     }

//     if (type === 'recurrente') {
//       let cronExpression;
//       switch (frequence) {
//         case 'mensuelle':
//           cronExpression = '0 0 1 * *';
//           break;
//         case 'trimestrielle':
//           cronExpression = '0 0 1 */3 *';
//           break;
//         case 'annuelle':
//           cronExpression = '0 0 1 1 *';
//           break;
//         default:
//           throw new Error('Fréquence invalide');
//       }

//       cron.schedule(cronExpression, async () => {
//         try {
//           if (invoiceData.dateFin && new Date() > invoiceData.dateFin) return;

//           const newInvoice = new Invoice({
//             ...invoiceData,
//             numero: `${invoiceData.numero}-${Date.now()}`,
//             type: 'standard',
//             statut: 'brouillon',
//             dateEmission: new Date(),
//             dateEcheance: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
//             frequence: undefined,
//             dateFin: undefined,
//             invoiceRef: undefined,
//             acompte: 0,
//             createdAt: new Date(),
//           });
//           await newInvoice.save();

//           const totals = calculateTotals(newInvoice.lignes);
//           const entry = new JournalEntry({
//             userId,
//             description: `Facture récurrente ${newInvoice.numero} pour ${clientNom}`,
//             debitEntityType: 'Client',
//             debitEntityName: clientNom,
//             creditEntityType: 'Ventes',
//             creditEntityName: 'Ventes',
//             amount: totals.totalTTC,
//             createdAt: new Date(),
//           });
//           await entry.save();
//         } catch (err) {
//           console.error(`Erreur génération facture récurrente ${invoice.numero}:`, err);
//         }
//       });
//     }

//     res.status(201).json(invoice);
//   } catch (err) {
//     console.error('Erreur createInvoice:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Get all invoices for a user
// exports.getInvoices = async (req, res) => {
//   const userId = req.user.userId;
//   const { page = 1, limit = 10, type, statut, search } = req.query;

//   try {
//     const query = { userId };
//     if (type) query.type = type;
//     if (statut) query.statut = statut;
//     if (search) {
//       query.$or = [
//         { numero: { $regex: search, $options: 'i' } },
//         { clientNom: { $regex: search, $options: 'i' } },
//       ];
//     }

//     const invoices = await Invoice.find(query)
//       .skip((Number(page) - 1) * Number(limit))
//       .limit(Number(limit))
//       .sort({ createdAt: -1 })
//       .lean();
//     const total = await Invoice.countDocuments(query);

//     res.status(200).json({
//       invoices,
//       total,
//       page: Number(page),
//       limit: Number(limit),
//     });
//   } catch (err) {
//     console.error('Erreur getInvoices:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Get a single invoice
// exports.getInvoice = async (req, res) => {
//   const { id } = req.params;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(id)) {
//       return res.status(400).json({ error: 'ID de facture invalide' });
//     }

//     const invoice = await Invoice.findOne({ _id: id, userId }).lean();
//     if (!invoice) {
//       return res.status(404).json({ error: 'Facture non trouvée' });
//     }

//     res.status(200).json(invoice);
//   } catch (err) {
//     console.error('Erreur getInvoice:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Update invoice status
// exports.updateInvoiceStatus = async (req, res) => {
//   const { id } = req.params;
//   const { statut } = req.body;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(id)) {
//       return res.status(400).json({ error: 'ID de facture invalide' });
//     }
//     if (!['brouillon', 'envoyee', 'payee', 'enRetard', 'enAttente', 'accepte', 'refuse'].includes(statut)) {
//       return res.status(400).json({ error: 'Statut invalide' });
//     }

//     const invoice = await Invoice.findOne({ _id: id, userId });
//     if (!invoice) {
//       return res.status(404).json({ error: 'Facture non trouvée' });
//     }
//     if (invoice.statut === 'annulee') {
//       return res.status(400).json({ error: 'Facture annulée ne peut pas être modifiée' });
//     }
//     if (invoice.type === 'devis' && !['enAttente', 'accepte', 'refuse'].includes(statut)) {
//       return res.status(400).json({ error: 'Statut invalide pour un devis' });
//     }

//     invoice.statut = statut;
//     await invoice.save();

//     if (statut === 'payee' && invoice.type !== 'avoir') {
//       const totals = calculateTotals(invoice.lignes, invoice.type === 'avoir');
//       const entry = new JournalEntry({
//         userId,
//         description: `Paiement facture ${invoice.numero} pour ${invoice.clientNom}`,
//         debitEntityType: 'Banque',
//         debitEntityName: 'Compte Bancaire',
//         creditEntityType: 'Client',
//         creditEntityName: invoice.clientNom,
//         amount: invoice.type === 'acompte' ? invoice.acompte : totals.totalTTC,
//         createdAt: new Date(),
//       });
//       await entry.save();
//     }

//     res.status(200).json(invoice);
//   } catch (err) {
//     console.error('Erreur updateInvoiceStatus:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Update an invoice
// exports.updateInvoice = async (req, res) => {
//   const { id } = req.params;
//   const {
//     numero,
//     clientNom,
//     clientAdresse,
//     clientTVA,
//     siret,
//     clientSiret,
//     adresseFournisseur,
//     penalitesRetard,
//     lignes,
//     fraisLivraison,
//     agios,
//     acompte,
//     devise,
//     dateEmission,
//     dateEcheance,
//   } = req.body;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(id)) {
//       return res.status(400).json({ error: 'ID de facture invalide' });
//     }

//     const invoice = await Invoice.findOne({ _id: id, userId });
//     if (!invoice) {
//       return res.status(404).json({ error: 'Facture non trouvée' });
//     }
//     if (invoice.statut === 'annulee' || invoice.statut === 'payee') {
//       return res.status(400).json({ error: 'Facture annulée ou payée ne peut pas être modifiée' });
//     }

//     invoice.numero = numero && numero.trim() ? numero.trim() : invoice.numero;
//     invoice.clientNom = clientNom && clientNom.trim() ? clientNom.trim() : invoice.clientNom;
//     invoice.clientAdresse = clientAdresse ?? invoice.clientAdresse;
//     invoice.clientTVA = clientTVA ?? invoice.clientTVA;
//     invoice.siret = siret ?? invoice.siret;
//     invoice.clientSiret = clientSiret ?? invoice.clientSiret;
//     invoice.adresseFournisseur = adresseFournisseur ?? invoice.adresseFournisseur;
//     invoice.penalitesRetard = penalitesRetard ?? invoice.penalitesRetard;
//     invoice.lignes = lignes || invoice.lignes;
//     invoice.fraisLivraison = fraisLivraison ?? invoice.fraisLivraison;
//     invoice.agios = agios ?? invoice.agios;
//     invoice.acompte = acompte ?? invoice.acompte;
//     invoice.devise = devise ?? invoice.devise;
//     invoice.dateEmission = dateEmission ? new Date(dateEmission) : invoice.dateEmission;
//     invoice.dateEcheance = dateEcheance ? new Date(dateEcheance) : invoice.dateEcheance;

//     await invoice.save();
//     res.status(200).json(invoice);
//   } catch (err) {
//     console.error('Erreur updateInvoice:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Delete an invoice
// exports.deleteInvoice = async (req, res) => {
//   const { id } = req.params;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(id)) {
//       console.log(`ID invalide: ${id}`);
//       return res.status(400).json({ error: 'ID de facture invalide' });
//     }

//     const invoice = await Invoice.findOne({ _id: id, userId });
//     if (!invoice) {
//       console.log(`Facture non trouvée: ${id}`);
//       return res.status(404).json({ error: 'Facture non trouvée' });
//     }
//     if (invoice.statut === 'payee' || invoice.statut === 'annulee') {
//       console.log(`Facture ${id} est payée ou annulée`);
//       return res.status(400).json({ error: 'Facture payée ou annulée ne peut pas être supprimée' });
//     }

//     await invoice.deleteOne();
//     console.log(`Facture supprimée: ${id}`);
//     res.status(200).json({ message: 'Facture supprimée avec succès' });
//   } catch (err) {
//     console.error('Erreur deleteInvoice:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Cancel an invoice
// exports.cancelInvoice = async (req, res) => {
//   const { id } = req.params;
//   const { motif } = req.body;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(id)) {
//       return res.status(400).json({ error: 'ID de facture invalide' });
//     }
//     if (!motif || typeof motif !== 'string' || motif.trim() === '') {
//       return res.status(400).json({ error: 'Motif d’annulation requis' });
//     }

//     const invoice = await Invoice.findOne({ _id: id, userId });
//     if (!invoice) {
//       return res.status(404).json({ error: 'Facture non trouvée' });
//     }

//     if (invoice.statut === 'annulee') {
//       return res.status(400).json({ error: 'Facture déjà annulée' });
//     }
//     if (invoice.statut === 'payee') {
//       return res.status(400).json({ error: 'Facture payée ne peut pas être annulée' });
//     }

//     invoice.statut = 'annulee';
//     invoice.motifAnnulation = motif.trim();
//     await invoice.save();

//     res.status(200).json(invoice);
//   } catch (err) {
//     console.error('Erreur cancelInvoice:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Convert a devis to a standard invoice
// exports.convertDevis = async (req, res) => {
//   const { id } = req.params;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(id)) {
//       return res.status(400).json({ error: 'ID de devis invalide' });
//     }

//     const invoice = await Invoice.findOne({ _id: id, userId, type: 'devis' });
//     if (!invoice) {
//       return res.status(404).json({ error: 'Devis non trouvé' });
//     }
//     if (invoice.statut !== 'accepte') {
//       return res.status(400).json({ error: 'Le devis doit être accepté avant conversion' });
//     }

//     invoice.type = 'standard';
//     invoice.statut = 'brouillon';
//     await invoice.save();

//     const totals = calculateTotals(invoice.lignes);
//     const entry = new JournalEntry({
//       userId,
//       description: `Facture ${invoice.numero} pour ${invoice.clientNom}`,
//       debitEntityType: 'Client',
//       debitEntityName: invoice.clientNom,
//       creditEntityType: 'Ventes',
//       creditEntityName: 'Ventes',
//       amount: totals.totalTTC,
//       createdAt: new Date(),
//     });
//     await entry.save();

//     res.status(200).json(invoice);
//   } catch (err) {
//     console.error('Erreur convertDevis:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Create final invoice after acompte
// exports.createFinalInvoice = async (req, res) => {
//   const {
//     acompteInvoiceId,
//     numero,
//     clientNom,
//     clientAdresse,
//     clientTVA,
//     siret,
//     clientSiret,
//     adresseFournisseur,
//     penalitesRetard,
//     lignes,
//     fraisLivraison,
//     agios,
//     devise,
//     dateEmission,
//     dateEcheance,
//   } = req.body;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(acompteInvoiceId)) {
//       return res.status(400).json({ error: 'ID de facture d’acompte invalide' });
//     }
//     if (!clientNom || typeof clientNom !== 'string' || clientNom.trim() === '') {
//       return res.status(400).json({ error: 'Nom du client requis' });
//     }
//     if (!lignes || !lignes.length) {
//       return res.status(400).json({ error: 'Au moins une ligne est requise' });
//     }

//     const acompteInvoice = await Invoice.findOne({ _id: acompteInvoiceId, userId, type: 'acompte' });
//     if (!acompteInvoice) {
//       return res.status(404).json({ error: 'Facture d’acompte non trouvée' });
//     }

//     const totals = calculateTotals(lignes);
//     const adjustedTTC = Number((totals.totalTTC - acompteInvoice.acompte).toFixed(2));

//     if (adjustedTTC < 0) {
//       return res.status(400).json({ error: 'Le montant final ne peut pas être négatif' });
//     }

//     const invoiceData = {
//       userId,
//       numero: numero || `INV-${new Date().getFullYear()}-${uuidv4().slice(0, 8)}`,
//       type: 'standard',
//       statut: 'brouillon',
//       clientNom: clientNom.trim(),
//       clientAdresse,
//       clientTVA,
//       siret,
//       clientSiret,
//       adresseFournisseur,
//       penalitesRetard: penalitesRetard || '5000 FCFA + 2% par mois',
//       lignes,
//       fraisLivraison: fraisLivraison || 0,
//       agios: agios || 0,
//       acompte: acompteInvoice.acompte,
//       devise: devise || 'XOF',
//       invoiceRef: acompteInvoice._id,
//       dateEmission: dateEmission ? new Date(dateEmission) : new Date(),
//       dateEcheance: dateEcheance ? new Date(dateEcheance) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
//       createdAt: new Date(),
//     };

//     const invoice = new Invoice(invoiceData);
//     await invoice.save();

//     const entry = new JournalEntry({
//       userId,
//       description: `Facture finale ${invoice.numero} pour ${clientNom}`,
//       debitEntityType: 'Client',
//       debitEntityName: clientNom,
//       creditEntityType: 'Ventes',
//       creditEntityName: 'Ventes',
//       amount: adjustedTTC,
//       createdAt: new Date(),
//     });
//     await entry.save();

//     res.status(201).json(invoice);
//   } catch (err) {
//     console.error('Erreur createFinalInvoice:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Generate PDF for an invoice
// exports.generatePdf = async (req, res) => {
//   const { id } = req.params;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(id)) {
//       return res.status(400).json({ error: 'ID de facture invalide', code: 'INVALID_ID' });
//     }

//     const invoice = await Invoice.findOne({ _id: id, userId });
//     if (!invoice) {
//       return res.status(404).json({ error: 'Facture non trouvée', code: 'NOT_FOUND' });
//     }

//     const documentsDir = path.join(__dirname, '../../documents');
//     if (!fs.existsSync(documentsDir)) {
//       fs.mkdirSync(documentsDir, { recursive: true });
//     }

//     const doc = new PDFDocument({ margin: 50 });
//     const filename = `facture-${invoice.numero}.pdf`;
//     const filePath = path.join(documentsDir, filename);
//     const writeStream = fs.createWriteStream(filePath);
//     doc.pipe(writeStream);

//     doc.fontSize(20).text(`${invoice.type === 'devis' ? 'Devis' : 'Facture'} ${invoice.numero}`, { align: 'center' });
//     doc.moveDown();
//     doc.fontSize(12).text(`Date: ${new Date(invoice.dateEmission).toLocaleDateString('fr-FR')}`);
//     doc.text(`Échéance: ${invoice.dateEcheance ? new Date(invoice.dateEcheance).toLocaleDateString('fr-FR') : 'N/A'}`);
//     doc.text(`Client: ${invoice.clientNom}`);
//     if (invoice.clientAdresse) doc.text(`Adresse client: ${invoice.clientAdresse}`);
//     if (invoice.clientTVA) doc.text(`TVA client: ${invoice.clientTVA}`);
//     if (invoice.siret) doc.text(`SIRET: ${invoice.siret}`);
//     if (invoice.clientSiret) doc.text(`SIRET client: ${invoice.clientSiret}`);
//     if (invoice.adresseFournisseur) doc.text(`Fournisseur: ${invoice.adresseFournisseur}`);
//     doc.moveDown();

//     doc.fontSize(10);
//     doc.text('Description | Quantité | Prix Unitaire | TVA | Remise | Rabais | Ristourne | Total', { underline: true });
//     invoice.lignes.forEach(ligne => {
//       const totalLigne = (ligne.quantite * ligne.prixUnitaire - (ligne.remise || 0) - (ligne.rabais || 0) - (ligne.ristourne || 0)) * (1 + (ligne.tva || 0) / 100);
//       doc.text(
//         `${ligne.description} | ${ligne.quantite} | ${ligne.prixUnitaire} ${invoice.devise} | ${ligne.tva || 0}% | ${ligne.remise || 0} | ${ligne.rabais || 0} | ${ligne.ristourne || 0} | ${totalLigne.toFixed(2)} ${invoice.devise}`
//       );
//     });
//     doc.moveDown();

//     const totals = calculateTotals(invoice.lignes, invoice.type === 'avoir');
//     doc.fontSize(12).text(`Frais de livraison: ${invoice.fraisLivraison.toFixed(2)} ${invoice.devise}`, { align: 'right' });
//     doc.text(`Agios: ${invoice.agios.toFixed(2)} ${invoice.devise}`, { align: 'right' });
//     doc.text(`Total HT: ${totals.totalHT.toFixed(2)} ${invoice.devise}`, { align: 'right' });
//     doc.text(`Total TVA: ${totals.totalTVA.toFixed(2)} ${invoice.devise}`, { align: 'right' });
//     doc.text(`Total TTC: ${totals.totalTTC.toFixed(2)} ${invoice.devise}`, { align: 'right' });
//     if (invoice.acompte) doc.text(`Acompte: ${invoice.acompte.toFixed(2)} ${invoice.devise}`, { align: 'right' });
//     if (invoice.penalitesRetard) doc.text(`Pénalités de retard: ${invoice.penalitesRetard}`);
//     if (invoice.motifAnnulation) doc.text(`Motif annulation: ${invoice.motifAnnulation}`);
//     if (invoice.motifAvoir) doc.text(`Motif avoir: ${invoice.motifAvoir}`);
//     if (invoice.validiteDevis) doc.text(`Validité devis: ${new Date(invoice.validiteDevis).toLocaleDateString('fr-FR')}`);
//     if (invoice.signature) doc.text(`Signature: ${invoice.signature}`);

//     doc.end();

//     await new Promise((resolve, reject) => {
//       writeStream.on('finish', resolve);
//       writeStream.on('error', reject);
//     });

//     res.status(200).json({ url: `/documents/${filename}` });
//   } catch (err) {
//     console.error('Erreur generatePdf:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message, code: 'SERVER_ERROR' });
//   }
// };









// //invoice.contrpller.js
// const mongoose = require('mongoose');
// const Invoice = require('../models/invoice.model');
// const JournalEntry = require('../models/journal_entry.model');
// const cron = require('node-cron');
// const PDFDocument = require('pdfkit');

// // Calculate invoice totals per frontend logic
// const calculateTotals = (invoice, isAvoir = false) => {
//   if (!invoice.lignes || !Array.isArray(invoice.lignes) || invoice.lignes.length === 0) {
//     throw new Error('Lignes invalides ou absentes');
//   }

//   const totalHT = invoice.lignes.reduce(
//     (sum, ligne) => sum + (ligne.quantite * ligne.prixUnitaireHT),
//     0
//   );

//   const tvaByRate = {};
//   invoice.lignes.forEach(ligne => {
//     const base = ligne.quantite * ligne.prixUnitaireHT;
//     tvaByRate[ligne.tauxTVA] = (tvaByRate[ligne.tauxTVA] || 0) + base;
//   });
//   const tvaArray = Object.entries(tvaByRate).map(([rate, baseHT]) => ({
//     rate: parseFloat(rate),
//     baseHT,
//     montantTVA: baseHT * (parseFloat(rate) / 100),
//   }));
//   const totalTVA = tvaArray.reduce((sum, tva) => sum + tva.montantTVA, 0);

//   const totalTTC = totalHT + totalTVA + (invoice.penalites || 0);

//   return {
//     totalHT: Number(totalHT.toFixed(2)),
//     tvaByRate: tvaArray,
//     totalTVA: Number(totalTVA.toFixed(2)),
//     totalTTC: Number((isAvoir ? -totalTTC : totalTTC).toFixed(2)),
//   };
// };

// // Generate invoice number with abbreviated prefix
// exports.generateInvoiceNumber = async (req, res) => {
//   try {
//     const { type } = req.body;
//     if (!['standard', 'recurrente', 'acompte', 'avoir', 'devis', 'proforma'].includes(type)) {
//       return res.status(400).json({ error: 'Type de facture invalide' });
//     }

//     // Map invoice type to abbreviated prefix
//     const prefixMap = {
//       standard: 'FACT',
//       recurrente: 'REC',
//       acompte: 'ACOMP',
//       avoir: 'AVOIR',
//       devis: 'DEV',
//       proforma: 'PROF',
//     };
//     const prefix = prefixMap[type];

//     const year = new Date().getFullYear();
//     const count = await Invoice.countDocuments({
//       type,
//       createdAt: { $gte: new Date(`${year}-01-01`) },
//     });
//     const numero = `${prefix}${year}-${String(count + 1).padStart(4, '0')}`;
//     res.status(200).json({ data: numero });
//   } catch (err) {
//     console.error('Erreur generateInvoiceNumber:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Create a new invoice
// exports.createInvoice = async (req, res) => {
//   const {
//     type,
//     numero,
//     rccm,
//     clientRccm,
//     clientNom,
//     clientAdresse,
//     clientEmail,
//     clientTelephone,
//     adresseFournisseur,
//     penalites,
//     lignes,
//     fraisLivraison,
//     agios,
//     acompte,
//     devise,
//     frequence,
//     dateFin,
//     invoiceRef,
//     parentInvoice,
//     revisionPrix,
//     motifAvoir,
//     creditType,
//     validiteDevis,
//     version,
//     signature,
//     dateEmission,
//     dateEcheance,
//   } = req.body;
//   const userId = req.user.userId;

//   try {
//     if (!['standard', 'recurrente', 'acompte', 'avoir', 'devis', 'proforma'].includes(type)) {
//       return res.status(400).json({ error: 'Type de facture invalide' });
//     }
//     if (!clientNom || typeof clientNom !== 'string' || clientNom.trim() === '') {
//       return res.status(400).json({ error: 'Nom du client requis' });
//     }
//     if (!lignes || !lignes.length) {
//       return res.status(400).json({ error: 'Au moins une ligne est requise' });
//     }
//     if (type === 'acompte' && (!mongoose.isValidObjectId(invoiceRef) || !acompte || acompte <= 0)) {
//       return res.status(400).json({ error: 'Référence de facture et montant d’acompte positif requis' });
//     }
//     if (type === 'avoir' && !mongoose.isValidObjectId(invoiceRef)) {
//       return res.status(400).json({ error: 'Référence de facture requise pour avoir' });
//     }
//     if (type === 'recurrente' && !['mensuelle', 'trimestrielle', 'annuelle'].includes(frequence)) {
//       return res.status(400).json({ error: 'Fréquence invalide pour facture récurrente' });
//     }

//     const invoiceData = {
//       userId,
//       numero: numero || `${type.toUpperCase()}${new Date().getFullYear()}-${String((await Invoice.countDocuments({ type })) + 1).padStart(4, '0')}`,
//       type,
//       statut: type === 'devis' ? 'enAttente' : 'brouillon',
//       rccm,
//       clientRccm,
//       clientNom: clientNom.trim(),
//       clientAdresse,
//       clientEmail,
//       clientTelephone,
//       adresseFournisseur,
//       penalites,
//       lignes,
//       fraisLivraison: fraisLivraison || 0,
//       agios: agios || 0,
//       acompte: acompte || 0,
//       devise: devise || 'XOF',
//       invoiceRef: ['acompte', 'avoir'].includes(type) ? invoiceRef : undefined,
//       motifAnnulation: undefined,
//       frequence: type === 'recurrente' ? frequence : undefined,
//       dateFin: type === 'recurrente' && dateFin ? new Date(dateFin) : undefined,
//       parentInvoice,
//       revisionPrix,
//       motifAvoir,
//       creditType,
//       validiteDevis: validiteDevis ? new Date(validiteDevis) : undefined,
//       version: version || 1,
//       signature,
//       dateEmission: dateEmission ? new Date(dateEmission) : new Date(),
//       dateEcheance: dateEcheance ? new Date(dateEcheance) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
//       createdAt: new Date(),
//     };

//     if (type === 'recurrente' && invoiceData.dateFin && invoiceData.dateFin <= invoiceData.dateEmission) {
//       return res.status(400).json({ error: 'La date de fin doit être postérieure à la date d’émission' });
//     }

//     const totals = calculateTotals(invoiceData, type === 'avoir');
//     invoiceData.tvaByRate = totals.tvaByRate;
//     invoiceData.montantHT = totals.totalHT;
//     invoiceData.montantTVA = totals.totalTVA;
//     invoiceData.montantTTC = totals.totalTTC;

//     const invoice = new Invoice(invoiceData);
//     await invoice.save();

//     if (['standard', 'acompte', 'avoir'].includes(type)) {
//       const entry = new JournalEntry({
//         userId,
//         description: `${type === 'avoir' ? 'Avoir' : 'Facture'} ${invoice.numero} pour ${clientNom}`,
//         debitEntityType: type === 'avoir' ? 'Ventes' : 'Client',
//         debitEntityName: type === 'avoir' ? 'Ventes' : clientNom,
//         creditEntityType: type === 'avoir' ? 'Client' : 'Ventes',
//         creditEntityName: type === 'avoir' ? clientNom : 'Ventes',
//         amount: type === 'acompte' ? invoice.acompte : Math.abs(totals.totalTTC),
//         createdAt: new Date(),
//       });
//       await entry.save();
//     }

//     if (type === 'recurrente') {
//       let cronExpression;
//       switch (frequence) {
//         case 'mensuelle':
//           cronExpression = '0 0 1 * *';
//           break;
//         case 'trimestrielle':
//           cronExpression = '0 0 1 */3 *';
//           break;
//         case 'annuelle':
//           cronExpression = '0 0 1 1 *';
//           break;
//         default:
//           throw new Error('Fréquence invalide');
//       }

//       cron.schedule(cronExpression, async () => {
//         try {
//           if (invoiceData.dateFin && new Date() > invoiceData.dateFin) return;

//           const newInvoice = new Invoice({
//             ...invoiceData,
//             numero: `${type.toUpperCase()}${new Date().getFullYear()}-${String((await Invoice.countDocuments({ type })) + 1).padStart(4, '0')}`,
//             type: 'standard',
//             statut: 'brouillon',
//             dateEmission: new Date(),
//             dateEcheance: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
//             frequence: undefined,
//             dateFin: undefined,
//             invoiceRef: undefined,
//             acompte: 0,
//             createdAt: new Date(),
//             tvaByRate: calculateTotals(invoiceData).tvaByRate,
//             montantHT: calculateTotals(invoiceData).totalHT,
//             montantTVA: calculateTotals(invoiceData).totalTVA,
//             montantTTC: calculateTotals(invoiceData).totalTTC,
//           });
//           await newInvoice.save();

//           const entry = new JournalEntry({
//             userId,
//             description: `Facture récurrente ${newInvoice.numero} pour ${clientNom}`,
//             debitEntityType: 'Client',
//             debitEntityName: clientNom,
//             creditEntityType: 'Ventes',
//             creditEntityName: 'Ventes',
//             amount: newInvoice.montantTTC,
//             createdAt: new Date(),
//           });
//           await entry.save();
//         } catch (err) {
//           console.error(`Erreur génération facture récurrente ${invoice.numero}:`, err);
//         }
//       });
//     }

//     res.status(201).json(invoice);
//   } catch (err) {
//     console.error('Erreur createInvoice:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Get all invoices for a user
// exports.getInvoices = async (req, res) => {
//   const userId = req.user.userId;
//   const { page = 1, limit = 10, type, statut, search } = req.query;

//   try {
//     const query = { userId };
//     if (type) query.type = type;
//     if (statut) query.statut = statut;
//     if (search) {
//       query.$or = [
//         { numero: { $regex: search, $options: 'i' } },
//         { clientNom: { $regex: search, $options: 'i' } },
//       ];
//     }

//     const invoices = await Invoice.find(query)
//       .skip((Number(page) - 1) * Number(limit))
//       .limit(Number(limit))
//       .sort({ createdAt: -1 })
//       .lean();
//     const total = await Invoice.countDocuments(query);

//     res.status(200).json({
//       invoices,
//       total,
//       page: Number(page),
//       limit: Number(limit),
//     });
//   } catch (err) {
//     console.error('Erreur getInvoices:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Get a single invoice
// exports.getInvoice = async (req, res) => {
//   const { id } = req.params;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(id)) {
//       return res.status(400).json({ error: 'ID de facture invalide' });
//     }

//     const invoice = await Invoice.findOne({ _id: id, userId }).lean();
//     if (!invoice) {
//       return res.status(404).json({ error: 'Facture non trouvée' });
//     }

//     res.status(200).json(invoice);
//   } catch (err) {
//     console.error('Erreur getInvoice:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Update invoice status
// exports.updateInvoiceStatus = async (req, res) => {
//   const { id } = req.params;
//   const { statut } = req.body;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(id)) {
//       return res.status(400).json({ error: 'ID de facture invalide' });
//     }
//     if (!['brouillon', 'envoyee', 'payee', 'enRetard', 'enAttente', 'accepte', 'refuse'].includes(statut)) {
//       return res.status(400).json({ error: 'Statut invalide' });
//     }

//     const invoice = await Invoice.findOne({ _id: id, userId });
//     if (!invoice) {
//       return res.status(404).json({ error: 'Facture non trouvée' });
//     }
//     if (invoice.statut === 'annulee') {
//       return res.status(400).json({ error: 'Facture annulée ne peut pas être modifiée' });
//     }
//     if (invoice.type === 'devis' && !['enAttente', 'accepte', 'refuse'].includes(statut)) {
//       return res.status(400).json({ error: 'Statut invalide pour un devis' });
//     }

//     invoice.statut = statut;
//     await invoice.save();

//     if (statut === 'payee' && invoice.type !== 'avoir') {
//       const entry = new JournalEntry({
//         userId,
//         description: `Paiement facture ${invoice.numero} pour ${invoice.clientNom}`,
//         debitEntityType: 'Banque',
//         debitEntityName: 'Compte Bancaire',
//         creditEntityType: 'Client',
//         creditEntityName: invoice.clientNom,
//         amount: invoice.type === 'acompte' ? invoice.acompte : invoice.montantTTC,
//         createdAt: new Date(),
//       });
//       await entry.save();
//     }

//     res.status(200).json(invoice);
//   } catch (err) {
//     console.error('Erreur updateInvoiceStatus:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Update an invoice
// exports.updateInvoice = async (req, res) => {
//   const { id } = req.params;
//   const {
//     numero,
//     rccm,
//     clientRccm,
//     clientNom,
//     clientAdresse,
//     clientEmail,
//     clientTelephone,
//     adresseFournisseur,
//     penalites,
//     lignes,
//     fraisLivraison,
//     agios,
//     acompte,
//     devise,
//     dateEmission,
//     dateEcheance,
//   } = req.body;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(id)) {
//       return res.status(400).json({ error: 'ID de facture invalide' });
//     }

//     const invoice = await Invoice.findOne({ _id: id, userId });
//     if (!invoice) {
//       return res.status(404).json({ error: 'Facture non trouvée' });
//     }
//     if (invoice.statut === 'annulee' || invoice.statut === 'payee') {
//       return res.status(400).json({ error: 'Facture annulée ou payée ne peut pas être modifiée' });
//     }

//     invoice.numero = numero && numero.trim() ? numero.trim() : invoice.numero;
//     invoice.rccm = rccm ?? invoice.rccm;
//     invoice.clientRccm = clientRccm ?? invoice.clientRccm;
//     invoice.clientNom = clientNom && clientNom.trim() ? clientNom.trim() : invoice.clientNom;
//     invoice.clientAdresse = clientAdresse ?? invoice.clientAdresse;
//     invoice.clientEmail = clientEmail ?? invoice.clientEmail;
//     invoice.clientTelephone = clientTelephone ?? invoice.clientTelephone;
//     invoice.adresseFournisseur = adresseFournisseur ?? invoice.adresseFournisseur;
//     invoice.penalites = penalites ?? invoice.penalites;
//     invoice.lignes = lignes || invoice.lignes;
//     invoice.fraisLivraison = fraisLivraison ?? invoice.fraisLivraison;
//     invoice.agios = agios ?? invoice.fraisLivraison;
//     invoice.acompte = acompte ?? invoice.acompte;
//     invoice.devise = devise ?? invoice.devise;
//     invoice.dateEmission = dateEmission ? new Date(dateEmission) : invoice.dateEmission;
//     invoice.dateEcheance = dateEcheance ? new Date(dateEcheance) : invoice.dateEcheance;

//     await invoice.save();
//     res.status(200).json(invoice);
//   } catch (err) {
//     console.error('Erreur updateInvoice:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Delete an invoice
// exports.deleteInvoice = async (req, res) => {
//   const { id } = req.params;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(id)) {
//       console.log(`ID invalide: ${id}`);
//       return res.status(400).json({ error: 'ID de facture invalide' });
//     }

//     const invoice = await Invoice.findOne({ _id: id, userId });
//     if (!invoice) {
//       console.log(`Facture non trouvée: ${id}`);
//       return res.status(404).json({ error: 'Facture non trouvée' });
//     }
//     if (invoice.statut === 'payee' || invoice.statut === 'annulee') {
//       console.log(`Facture ${id} est payée ou annulée`);
//       return res.status(400).json({ error: 'Facture payée ou annulée ne peut pas être supprimée' });
//     }

//     await invoice.deleteOne();
//     console.log(`Facture supprimée: ${id}`);
//     res.status(200).json({ message: 'Facture supprimée avec succès' });
//   } catch (err) {
//     console.error('Erreur deleteInvoice:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Cancel an invoice
// exports.cancelInvoice = async (req, res) => {
//   const { id } = req.params;
//   const { motif } = req.body;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(id)) {
//       return res.status(400).json({ error: 'ID de facture invalide' });
//     }
//     if (!motif || typeof motif !== 'string' || motif.trim() === '') {
//       return res.status(400).json({ error: 'Motif d’annulation requis' });
//     }

//     const invoice = await Invoice.findOne({ _id: id, userId });
//     if (!invoice) {
//       return res.status(404).json({ error: 'Facture non trouvée' });
//     }

//     if (invoice.statut === 'annulee') {
//       return res.status(400).json({ error: 'Facture déjà annulée' });
//     }
//     if (invoice.statut === 'payee') {
//       return res.status(400).json({ error: 'Facture payée ne peut pas être annulée' });
//     }

//     invoice.statut = 'annulee';
//     invoice.motifAnnulation = motif.trim();
//     await invoice.save();

//     res.status(200).json(invoice);
//   } catch (err) {
//     console.error('Erreur cancelInvoice:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Convert a devis to a standard invoice
// exports.convertDevis = async (req, res) => {
//   const { id } = req.params;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(id)) {
//       return res.status(400).json({ error: 'ID de devis invalide' });
//     }

//     const invoice = await Invoice.findOne({ _id: id, userId, type: 'devis' });
//     if (!invoice) {
//       return res.status(404).json({ error: 'Devis non trouvé' });
//     }
//     if (invoice.statut !== 'accepte') {
//       return res.status(400).json({ error: 'Le devis doit être accepté avant conversion' });
//     }

//     invoice.type = 'standard';
//     invoice.statut = 'brouillon';
//     await invoice.save();

//     const entry = new JournalEntry({
//       userId,
//       description: `Facture ${invoice.numero} pour ${invoice.clientNom}`,
//       debitEntityType: 'Client',
//       debitEntityName: invoice.clientNom,
//       creditEntityType: 'Ventes',
//       creditEntityName: 'Ventes',
//       amount: invoice.montantTTC,
//       createdAt: new Date(),
//     });
//     await invoice.save();

//     res.status(200).json(invoice);
//   } catch (err) {
//     console.error('Erreur convertDevis:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Create final invoice after acompte
// exports.createFinalInvoice = async (req, res) => {
//   const {
//     acompteInvoiceId,
//     numero,
//     rccm,
//     clientRccm,
//     clientNom,
//     clientAdresse,
//     clientEmail,
//     clientTelephone,
//     adresseFournisseur,
//     penalites,
//     lignes,
//     fraisLivraison,
//     agios,
//     devise,
//     dateEmission,
//     dateEcheance,
//   } = req.body;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(acompteInvoiceId)) {
//       return res.status(400).json({ error: 'ID de facture d’acompte invalide' });
//     }
//     if (!clientNom || typeof clientNom !== 'string' || clientNom.trim() === '') {
//       return res.status(400).json({ error: 'Nom du client requis' });
//     }
//     if (!lignes || !lignes.length) {
//       return res.status(400).json({ error: 'Au moins une ligne est requise' });
//     }

//     const acompteInvoice = await Invoice.findOne({ _id: acompteInvoiceId, userId, type: 'acompte' });
//     if (!acompteInvoice) {
//       return res.status(404).json({ error: 'Facture d’acompte non trouvée' });
//     }

//     const totals = calculateTotals({ lignes, penalites });
//     const adjustedTTC = Number((totals.totalTTC - acompteInvoice.acompte).toFixed(2));

//     if (adjustedTTC < 0) {
//       return res.status(400).json({ error: 'Le montant final ne peut pas être négatif' });
//     }

//     const invoiceData = {
//       userId,
//       numero: numero || `${type.toUpperCase()}${new Date().getFullYear()}-${String((await Invoice.countDocuments({ type })) + 1).padStart(4, '0')}`,
//       type: 'standard',
//       statut: 'brouillon',
//       rccm,
//       clientRccm,
//       clientNom: clientNom.trim(),
//       clientAdresse,
//       clientEmail,
//       clientTelephone,
//       adresseFournisseur,
//       penalites,
//       lignes,
//       fraisLivraison: fraisLivraison || 0,
//       agios: agios || 0,
//       acompte: acompteInvoice.acompte,
//       devise: devise || 'XOF',
//       invoiceRef: acompteInvoice._id,
//       dateEmission: dateEmission ? new Date(dateEmission) : new Date(),
//       dateEcheance: dateEcheance ? new Date(dateEcheance) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
//       createdAt: new Date(),
//       tvaByRate: totals.tvaByRate,
//       montantHT: totals.totalHT,
//       montantTVA: totals.totalTVA,
//       montantTTC: totals.totalTTC,
//     };

//     const invoice = new Invoice(invoiceData);
//     await invoice.save();

//     const entry = new JournalEntry({
//       userId,
//       description: `Facture finale ${invoice.numero} pour ${clientNom}`,
//       debitEntityType: 'Client',
//       debitEntityName: clientNom,
//       creditEntityType: 'Ventes',
//       creditEntityName: 'Ventes',
//       amount: adjustedTTC,
//       createdAt: new Date(),
//     });
//     await entry.save();

//     res.status(201).json(invoice);
//   } catch (err) {
//     console.error('Erreur createFinalInvoice:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// // Generate PDF for an invoice
// exports.generatePdf = async (req, res) => {
//   const { id } = req.params;
//   const userId = req.user.userId;

//   try {
//     if (!mongoose.isValidObjectId(id)) {
//       return res.status(400).json({ error: 'ID de facture invalide', code: 'INVALID_ID' });
//     }

//     const invoice = await Invoice.findOne({ _id: id, userId });
//     if (!invoice) {
//       return res.status(404).json({ error: 'Facture non trouvée', code: 'NOT_FOUND' });
//     }

//     const doc = new PDFDocument({ margin: 50 });
//     const buffers = [];
//     doc.on('data', buffers.push.bind(buffers));
//     doc.on('end', () => {
//       const pdfData = Buffer.concat(buffers);
//       res.set({
//         'Content-Type': 'application/pdf',
//         'Content-Length': pdfData.length,
//       });
//       res.status(200).send(pdfData);
//     });

//     doc.fontSize(20).text(`${invoice.type === 'devis' ? 'Devis' : 'Facture'} ${invoice.numero}`, { align: 'center' });
//     doc.moveDown();
//     doc.fontSize(12).text(`Date: ${new Date(invoice.dateEmission).toLocaleDateString('fr-FR')}`);
//     doc.text(`Échéance: ${invoice.dateEcheance ? new Date(invoice.dateEcheance).toLocaleDateString('fr-FR') : 'N/A'}`);
//     doc.text(`Client: ${invoice.clientNom}`);
//     if (invoice.clientAdresse) doc.text(`Adresse client: ${invoice.clientAdresse}`);
//     if (invoice.rccm) doc.text(`RCCM: ${invoice.rccm}`);
//     if (invoice.clientRccm) doc.text(`RCCM client: ${invoice.clientRccm}`);
//     if (invoice.clientEmail) doc.text(`Email client: ${invoice.clientEmail}`);
//     if (invoice.clientTelephone) doc.text(`Téléphone client: ${invoice.clientTelephone}`);
//     if (invoice.adresseFournisseur) doc.text(`Fournisseur: ${invoice.adresseFournisseur}`);
//     doc.moveDown();

//     doc.fontSize(10);
//     doc.text('Description | Quantité | Prix Unitaire HT | TVA | Total HT', { underline: true });
//     invoice.lignes.forEach(ligne => {
//       const totalLigne = ligne.quantite * ligne.prixUnitaireHT;
//       doc.text(
//         `${ligne.description} | ${ligne.quantite} | ${ligne.prixUnitaireHT} ${invoice.devise} | ${ligne.tauxTVA}% | ${totalLigne.toFixed(2)} ${invoice.devise}`
//       );
//     });
//     doc.moveDown();

//     doc.fontSize(12).text('TVA Breakdown:', { underline: true });
//     invoice.tvaByRate.forEach(tva => {
//       doc.text(`TVA ${tva.rate}%: Base ${tva.baseHT.toFixed(2)} ${invoice.devise}, Montant ${tva.montantTVA.toFixed(2)} ${invoice.devise}`);
//     });
//     doc.moveDown();

//     doc.text(`Frais de livraison: ${invoice.fraisLivraison.toFixed(2)} ${invoice.devise}`, { align: 'right' });
//     doc.text(`Agios: ${invoice.agios.toFixed(2)} ${invoice.devise}`, { align: 'right' });
//     doc.text(`Total HT: ${invoice.montantHT.toFixed(2)} ${invoice.devise}`, { align: 'right' });
//     doc.text(`Total TVA: ${invoice.montantTVA.toFixed(2)} ${invoice.devise}`, { align: 'right' });
//     doc.text(`Pénalités: ${(invoice.penalites || 0).toFixed(2)} ${invoice.devise}`, { align: 'right' });
//     doc.text(`Total TTC: ${invoice.montantTTC.toFixed(2)} ${invoice.devise}`, { align: 'right' });
//     if (invoice.acompte) doc.text(`Acompte: ${invoice.acompte.toFixed(2)} ${invoice.devise}`, { align: 'right' });
//     if (invoice.motifAnnulation) doc.text(`Motif annulation: ${invoice.motifAnnulation}`);
//     if (invoice.motifAvoir) doc.text(`Motif avoir: ${invoice.motifAvoir}`);
//     if (invoice.validiteDevis) doc.text(`Validité devis: ${new Date(invoice.validiteDevis).toLocaleDateString('fr-FR')}`);
//     if (invoice.signature) doc.text(`Signature: ${invoice.signature}`);
//     doc.moveDown();
//     doc.text('Conformément à l’Acte Uniforme OHADA relatif au droit commercial général', { align: 'center' });

//     doc.end();
//   } catch (err) {
//     console.error('Erreur generatePdf:', err.message);
//     res.status(500).json({ error: 'Erreur serveur', details: err.message, code: 'SERVER_ERROR' });
//   }
// };






const mongoose = require('mongoose');
const Invoice = require('../models/invoice.model');
const JournalEntry = require('../models/journal_entry.model');
const cron = require('node-cron');
const PDFDocument = require('pdfkit');

// Calculate invoice totals per frontend logic
const calculateTotals = (invoice, isAvoir = false) => {
  if (!invoice.lignes || !Array.isArray(invoice.lignes) || invoice.lignes.length === 0) {
    throw new Error('Lignes invalides ou absentes');
  }

  const totalHT = invoice.lignes.reduce(
    (sum, ligne) => sum + (ligne.quantite * ligne.prixUnitaireHT),
    0
  );

  const tvaByRate = {};
  invoice.lignes.forEach(ligne => {
    const base = ligne.quantite * ligne.prixUnitaireHT;
    tvaByRate[ligne.tauxTVA] = (tvaByRate[ligne.tauxTVA] || 0) + base;
  });
  const tvaArray = Object.entries(tvaByRate).map(([rate, baseHT]) => ({
    rate: parseFloat(rate),
    baseHT,
    montantTVA: baseHT * (parseFloat(rate) / 100),
  }));
  const totalTVA = tvaArray.reduce((sum, tva) => sum + tva.montantTVA, 0);

  const totalTTC = totalHT + totalTVA + (invoice.penalites || 0);

  return {
    totalHT: Number(totalHT.toFixed(2)),
    tvaByRate: tvaArray,
    totalTVA: Number(totalTVA.toFixed(2)),
    totalTTC: Number((isAvoir ? -totalTTC : totalTTC).toFixed(2)),
  };
};

// Generate invoice number with abbreviated prefix
exports.generateInvoiceNumber = async (req, res) => {
  try {
    const { type } = req.body;
    if (!['standard', 'recurrente', 'acompte', 'avoir', 'devis', 'proforma', 'abonnement', 'indemnite'].includes(type)) {
      return res.status(400).json({ error: 'Type de facture invalide' });
    }

    // Map invoice type to abbreviated prefix
    const prefixMap = {
      standard: 'FACT',
      recurrente: 'REC',
      acompte: 'ACOMP',
      avoir: 'AVOIR',
      devis: 'DEV',
      proforma: 'PROF',
      abonnement: 'ABON',
      indemnite: 'INDEM',
    };
    const prefix = prefixMap[type];

    const year = new Date().getFullYear();
    const count = await Invoice.countDocuments({
      type,
      createdAt: { $gte: new Date(`${year}-01-01`) },
    });
    const numero = `${prefix}${year}-${String(count + 1).padStart(4, '0')}`;
    res.status(200).json({ data: numero });
  } catch (err) {
    console.error('Erreur generateInvoiceNumber:', err.message);
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};

// Create a new invoice
exports.createInvoice = async (req, res) => {
  const {
    type,
    numero,
    rccm,
    clientRccm,
    clientNom,
    clientAdresse,
    clientEmail,
    clientTelephone,
    adresseFournisseur,
    penalites,
    lignes,
    fraisLivraison,
    agios,
    acompte,
    devise,
    frequence,
    dateFin,
    invoiceRef,
    parentInvoice,
    revisionPrix,
    motifAvoir,
    creditType,
    validiteDevis,
    version,
    signature,
    dateEmission,
    dateEcheance,
  } = req.body;
  const userId = req.user.userId;

  try {
    if (!['standard', 'recurrente', 'acompte', 'avoir', 'devis', 'proforma', 'abonnement', 'indemnite'].includes(type)) {
      return res.status(400).json({ error: 'Type de facture invalide' });
    }
    if (!clientNom || typeof clientNom !== 'string' || clientNom.trim() === '') {
      return res.status(400).json({ error: 'Nom du client requis' });
    }
    if (!lignes || !lignes.length) {
      return res.status(400).json({ error: 'Au moins une ligne est requise' });
    }
    if (type === 'acompte' && (!mongoose.isValidObjectId(invoiceRef) || !acompte || acompte <= 0)) {
      return res.status(400).json({ error: 'Référence de facture et montant d’acompte positif requis' });
    }
    if (type === 'avoir' && !mongoose.isValidObjectId(invoiceRef)) {
      return res.status(400).json({ error: 'Référence de facture requise pour avoir' });
    }
    if (type === 'recurrente' && !['mensuelle', 'trimestrielle', 'annuelle'].includes(frequence)) {
      return res.status(400).json({ error: 'Fréquence invalide pour facture récurrente' });
    }

    const invoiceData = {
      userId,
      numero: numero || `${type.toUpperCase()}${new Date().getFullYear()}-${String((await Invoice.countDocuments({ type })) + 1).padStart(4, '0')}`,
      type,
      statut: type === 'devis' ? 'enAttente' : 'brouillon',
      rccm,
      clientRccm,
      clientNom: clientNom.trim(),
      clientAdresse,
      clientEmail,
      clientTelephone,
      adresseFournisseur,
      penalites,
      lignes,
      fraisLivraison: fraisLivraison || 0,
      agios: agios || 0,
      acompte: acompte || 0,
      devise: devise || 'XOF',
      invoiceRef: ['acompte', 'avoir'].includes(type) ? invoiceRef : undefined,
      motifAnnulation: undefined,
      frequence: type === 'recurrente' ? frequence : undefined,
      dateFin: type === 'recurrente' && dateFin ? new Date(dateFin) : undefined,
      parentInvoice,
      revisionPrix,
      motifAvoir,
      creditType,
      validiteDevis: validiteDevis ? new Date(validiteDevis) : undefined,
      version: version || 1,
      signature,
      dateEmission: dateEmission ? new Date(dateEmission) : new Date(),
      dateEcheance: dateEcheance ? new Date(dateEcheance) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      createdAt: new Date(),
    };

    if (type === 'recurrente' && invoiceData.dateFin && invoiceData.dateFin <= invoiceData.dateEmission) {
      return res.status(400).json({ error: 'La date de fin doit être postérieure à la date d’émission' });
    }

    const totals = calculateTotals(invoiceData, type === 'avoir');
    invoiceData.tvaByRate = totals.tvaByRate;
    invoiceData.montantHT = totals.totalHT;
    invoiceData.montantTVA = totals.totalTVA;
    invoiceData.montantTTC = totals.totalTTC;

    const invoice = new Invoice(invoiceData);
    await invoice.save();

    if (['standard', 'acompte', 'avoir', 'abonnement', 'indemnite'].includes(type)) {
      const entry = new JournalEntry({
        userId,
        description: `${type === 'avoir' ? 'Avoir' : 'Facture'} ${invoice.numero} pour ${clientNom}`,
        debitEntityType: type === 'avoir' ? 'Ventes' : 'Client',
        debitEntityName: type === 'avoir' ? 'Ventes' : clientNom,
        creditEntityType: type === 'avoir' ? 'Client' : 'Ventes',
        creditEntityName: type === 'avoir' ? clientNom : 'Ventes',
        amount: type === 'acompte' ? invoice.acompte : Math.abs(totals.totalTTC),
        createdAt: new Date(),
      });
      await entry.save();
    }

    if (type === 'recurrente') {
      let cronExpression;
      switch (frequence) {
        case 'mensuelle':
          cronExpression = '0 0 1 * *';
          break;
        case 'trimestrielle':
          cronExpression = '0 0 1 */3 *';
          break;
        case 'annuelle':
          cronExpression = '0 0 1 1 *';
          break;
        default:
          throw new Error('Fréquence invalide');
      }

      cron.schedule(cronExpression, async () => {
        try {
          if (invoiceData.dateFin && new Date() > invoiceData.dateFin) return;

          const newInvoice = new Invoice({
            ...invoiceData,
            numero: `${type.toUpperCase()}${new Date().getFullYear()}-${String((await Invoice.countDocuments({ type })) + 1).padStart(4, '0')}`,
            type: 'standard',
            statut: 'brouillon',
            dateEmission: new Date(),
            dateEcheance: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            frequence: undefined,
            dateFin: undefined,
            invoiceRef: undefined,
            acompte: 0,
            createdAt: new Date(),
            tvaByRate: calculateTotals(invoiceData).tvaByRate,
            montantHT: calculateTotals(invoiceData).totalHT,
            montantTVA: calculateTotals(invoiceData).totalTVA,
            montantTTC: calculateTotals(invoiceData).totalTTC,
          });
          await newInvoice.save();

          const entry = new JournalEntry({
            userId,
            description: `Facture récurrente ${newInvoice.numero} pour ${clientNom}`,
            debitEntityType: 'Client',
            debitEntityName: clientNom,
            creditEntityType: 'Ventes',
            creditEntityName: 'Ventes',
            amount: newInvoice.montantTTC,
            createdAt: new Date(),
          });
          await entry.save();
        } catch (err) {
          console.error(`Erreur génération facture récurrente ${invoice.numero}:`, err);
        }
      });
    }

    res.status(201).json(invoice);
  } catch (err) {
    console.error('Erreur createInvoice:', err.message);
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};

// Get all invoices for a user
exports.getInvoices = async (req, res) => {
  const userId = req.user.userId;
  const { page = 1, limit = 10, type, statut, search } = req.query;

  try {
    const query = { userId };
    if (type) query.type = type;
    if (statut) query.statut = statut;
    if (search) {
      query.$or = [
        { numero: { $regex: search, $options: 'i' } },
        { clientNom: { $regex: search, $options: 'i' } },
      ];
    }

    const invoices = await Invoice.find(query)
      .skip((Number(page) - 1) * Number(limit))
      .limit(Number(limit))
      .sort({ createdAt: -1 })
      .lean();
    const total = await Invoice.countDocuments(query);

    res.status(200).json({
      invoices,
      total,
      page: Number(page),
      limit: Number(limit),
    });
  } catch (err) {
    console.error('Erreur getInvoices:', err.message);
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};

// Get a single invoice
exports.getInvoice = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userId;

  try {
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({ error: 'ID de facture invalide' });
    }

    const invoice = await Invoice.findOne({ _id: id, userId }).lean();
    if (!invoice) {
      return res.status(404).json({ error: 'Facture non trouvée' });
    }

    res.status(200).json(invoice);
  } catch (err) {
    console.error('Erreur getInvoice:', err.message);
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};

// Update invoice status
exports.updateInvoiceStatus = async (req, res) => {
  const { id } = req.params;
  const { statut } = req.body;
  const userId = req.user.userId;

  try {
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({ error: 'ID de facture invalide' });
    }
    if (!['brouillon', 'envoyee', 'payee', 'enRetard', 'enAttente', 'accepte', 'refuse', 'partiellementPayée'].includes(statut)) {
      return res.status(400).json({ error: 'Statut invalide' });
    }

    const invoice = await Invoice.findOne({ _id: id, userId });
    if (!invoice) {
      return res.status(404).json({ error: 'Facture non trouvée' });
    }
    if (invoice.statut === 'annulee') {
      return res.status(400).json({ error: 'Facture annulée ne peut pas être modifiée' });
    }
    if (invoice.type === 'devis' && !['enAttente', 'accepte', 'refuse'].includes(statut)) {
      return res.status(400).json({ error: 'Statut invalide pour un devis' });
    }

    invoice.statut = statut;
    await invoice.save();

    if (statut === 'payee' && invoice.type !== 'avoir') {
      const entry = new JournalEntry({
        userId,
        description: `Paiement facture ${invoice.numero} pour ${invoice.clientNom}`,
        debitEntityType: 'Banque',
        debitEntityName: 'Compte Bancaire',
        creditEntityType: 'Client',
        creditEntityName: invoice.clientNom,
        amount: invoice.type === 'acompte' ? invoice.acompte : invoice.montantTTC,
        createdAt: new Date(),
      });
      await entry.save();
    }

    res.status(200).json(invoice);
  } catch (err) {
    console.error('Erreur updateInvoiceStatus:', err.message);
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};

// Update an invoice
exports.updateInvoice = async (req, res) => {
  const { id } = req.params;
  const {
    numero,
    rccm,
    clientRccm,
    clientNom,
    clientAdresse,
    clientEmail,
    clientTelephone,
    adresseFournisseur,
    penalites,
    lignes,
    fraisLivraison,
    agios,
    acompte,
    devise,
    dateEmission,
    dateEcheance,
  } = req.body;
  const userId = req.user.userId;

  try {
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({ error: 'ID de facture invalide' });
    }

    const invoice = await Invoice.findOne({ _id: id, userId });
    if (!invoice) {
      return res.status(404).json({ error: 'Facture non trouvée' });
    }
    if (invoice.statut === 'annulee' || invoice.statut === 'payee') {
      return res.status(400).json({ error: 'Facture annulée ou payée ne peut pas être modifiée' });
    }

    invoice.numero = numero && numero.trim() ? numero.trim() : invoice.numero;
    invoice.rccm = rccm ?? invoice.rccm;
    invoice.clientRccm = clientRccm ?? invoice.clientRccm;
    invoice.clientNom = clientNom && clientNom.trim() ? clientNom.trim() : invoice.clientNom;
    invoice.clientAdresse = clientAdresse ?? invoice.clientAdresse;
    invoice.clientEmail = clientEmail ?? invoice.clientEmail;
    invoice.clientTelephone = clientTelephone ?? invoice.clientTelephone;
    invoice.adresseFournisseur = adresseFournisseur ?? invoice.adresseFournisseur;
    invoice.penalites = penalites ?? invoice.penalites;
    invoice.lignes = lignes || invoice.lignes;
    invoice.fraisLivraison = fraisLivraison ?? invoice.fraisLivraison;
    invoice.agios = agios ?? invoice.fraisLivraison;
    invoice.acompte = acompte ?? invoice.acompte;
    invoice.devise = devise ?? invoice.devise;
    invoice.dateEmission = dateEmission ? new Date(dateEmission) : invoice.dateEmission;
    invoice.dateEcheance = dateEcheance ? new Date(dateEcheance) : invoice.dateEcheance;

    await invoice.save();
    res.status(200).json(invoice);
  } catch (err) {
    console.error('Erreur updateInvoice:', err.message);
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};

// Delete an invoice
exports.deleteInvoice = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userId;

  try {
    if (!mongoose.isValidObjectId(id)) {
      console.log(`ID invalide: ${id}`);
      return res.status(400).json({ error: 'ID de facture invalide' });
    }

    const invoice = await Invoice.findOne({ _id: id, userId });
    if (!invoice) {
      console.log(`Facture non trouvée: ${id}`);
      return res.status(404).json({ error: 'Facture non trouvée' });
    }
    if (invoice.statut === 'payee' || invoice.statut === 'annulee') {
      console.log(`Facture ${id} est payée ou annulée`);
      return res.status(400).json({ error: 'Facture payée ou annulée ne peut pas être supprimée' });
    }

    await invoice.deleteOne();
    console.log(`Facture supprimée: ${id}`);
    res.status(200).json({ message: 'Facture supprimée avec succès' });
  } catch (err) {
    console.error('Erreur deleteInvoice:', err.message);
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};

// Cancel an invoice
exports.cancelInvoice = async (req, res) => {
  const { id } = req.params;
  const { motif } = req.body;
  const userId = req.user.userId;

  try {
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({ error: 'ID de facture invalide' });
    }
    if (!motif || typeof motif !== 'string' || motif.trim() === '') {
      return res.status(400).json({ error: 'Motif d’annulation requis' });
    }

    const invoice = await Invoice.findOne({ _id: id, userId });
    if (!invoice) {
      return res.status(404).json({ error: 'Facture non trouvée' });
    }

    if (invoice.statut === 'annulee') {
      return res.status(400).json({ error: 'Facture déjà annulée' });
    }
    if (invoice.statut === 'payee') {
      return res.status(400).json({ error: 'Facture payée ne peut pas être annulée' });
    }

    invoice.statut = 'annulee';
    invoice.motifAnnulation = motif.trim();
    await invoice.save();

    res.status(200).json(invoice);
  } catch (err) {
    console.error('Erreur cancelInvoice:', err.message);
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};

// Convert a devis to a standard invoice
exports.convertDevis = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userId;

  try {
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({ error: 'ID de devis invalide' });
    }

    const invoice = await Invoice.findOne({ _id: id, userId, type: 'devis' });
    if (!invoice) {
      return res.status(404).json({ error: 'Devis non trouvé' });
    }
    if (invoice.statut !== 'accepte') {
      return res.status(400).json({ error: 'Le devis doit être accepté avant conversion' });
    }

    invoice.type = 'standard';
    invoice.statut = 'brouillon';
    await invoice.save();

    const entry = new JournalEntry({
      userId,
      description: `Facture ${invoice.numero} pour ${invoice.clientNom}`,
      debitEntityType: 'Client',
      debitEntityName: invoice.clientNom,
      creditEntityType: 'Ventes',
      creditEntityName: 'Ventes',
      amount: invoice.montantTTC,
      createdAt: new Date(),
    });
    await invoice.save();

    res.status(200).json(invoice);
  } catch (err) {
    console.error('Erreur convertDevis:', err.message);
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};

// Create final invoice after acompte
exports.createFinalInvoice = async (req, res) => {
  const {
    acompteInvoiceId,
    numero,
    rccm,
    clientRccm,
    clientNom,
    clientAdresse,
    clientEmail,
    clientTelephone,
    adresseFournisseur,
    penalites,
    lignes,
    fraisLivraison,
    agios,
    devise,
    dateEmission,
    dateEcheance,
  } = req.body;
  const userId = req.user.userId;

  try {
    if (!mongoose.isValidObjectId(acompteInvoiceId)) {
      return res.status(400).json({ error: 'ID de facture d’acompte invalide' });
    }
    if (!clientNom || typeof clientNom !== 'string' || clientNom.trim() === '') {
      return res.status(400).json({ error: 'Nom du client requis' });
    }
    if (!lignes || !lignes.length) {
      return res.status(400).json({ error: 'Au moins une ligne est requise' });
    }

    const acompteInvoice = await Invoice.findOne({ _id: acompteInvoiceId, userId, type: 'acompte' });
    if (!acompteInvoice) {
      return res.status(404).json({ error: 'Facture d’acompte non trouvée' });
    }

    const totals = calculateTotals({ lignes, penalites });
    const adjustedTTC = Number((totals.totalTTC - acompteInvoice.acompte).toFixed(2));

    if (adjustedTTC < 0) {
      return res.status(400).json({ error: 'Le montant final ne peut pas être négatif' });
    }

    const invoiceData = {
      userId,
      numero: numero || `${type.toUpperCase()}${new Date().getFullYear()}-${String((await Invoice.countDocuments({ type })) + 1).padStart(4, '0')}`,
      type: 'standard',
      statut: 'brouillon',
      rccm,
      clientRccm,
      clientNom: clientNom.trim(),
      clientAdresse,
      clientEmail,
      clientTelephone,
      adresseFournisseur,
      penalites,
      lignes,
      fraisLivraison: fraisLivraison || 0,
      agios: agios || 0,
      acompte: acompteInvoice.acompte,
      devise: devise || 'XOF',
      invoiceRef: acompteInvoice._id,
      dateEmission: dateEmission ? new Date(dateEmission) : new Date(),
      dateEcheance: dateEcheance ? new Date(dateEcheance) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      createdAt: new Date(),
      tvaByRate: totals.tvaByRate,
      montantHT: totals.totalHT,
      montantTVA: totals.totalTVA,
      montantTTC: totals.totalTTC,
    };

    const invoice = new Invoice(invoiceData);
    await invoice.save();

    const entry = new JournalEntry({
      userId,
      description: `Facture finale ${invoice.numero} pour ${clientNom}`,
      debitEntityType: 'Client',
      debitEntityName: clientNom,
      creditEntityType: 'Ventes',
      creditEntityName: 'Ventes',
      amount: adjustedTTC,
      createdAt: new Date(),
    });
    await entry.save();

    res.status(201).json(invoice);
  } catch (err) {
    console.error('Erreur createFinalInvoice:', err.message);
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};

// Generate PDF for an invoice
exports.generatePdf = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userId;

  try {
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({ error: 'ID de facture invalide', code: 'INVALID_ID' });
    }

    const invoice = await Invoice.findOne({ _id: id, userId });
    if (!invoice) {
      return res.status(404).json({ error: 'Facture non trouvée', code: 'NOT_FOUND' });
    }

    const doc = new PDFDocument({ margin: 50 });
    const buffers = [];
    doc.on('data', buffers.push.bind(buffers));
    doc.on('end', () => {
      const pdfData = Buffer.concat(buffers);
      res.set({
        'Content-Type': 'application/pdf',
        'Content-Length': pdfData.length,
      });
      res.status(200).send(pdfData);
    });

    doc.fontSize(20).text(`${invoice.type === 'devis' ? 'Devis' : 'Facture'} ${invoice.numero}`, { align: 'center' });
    doc.moveDown();
    doc.fontSize(12).text(`Date: ${new Date(invoice.dateEmission).toLocaleDateString('fr-FR')}`);
    doc.text(`Échéance: ${invoice.dateEcheance ? new Date(invoice.dateEcheance).toLocaleDateString('fr-FR') : 'N/A'}`);
    doc.text(`Client: ${invoice.clientNom}`);
    if (invoice.clientAdresse) doc.text(`Adresse client: ${invoice.clientAdresse}`);
    if (invoice.rccm) doc.text(`RCCM: ${invoice.rccm}`);
    if (invoice.clientRccm) doc.text(`RCCM client: ${invoice.clientRccm}`);
    if (invoice.clientEmail) doc.text(`Email client: ${invoice.clientEmail}`);
    if (invoice.clientTelephone) doc.text(`Téléphone client: ${invoice.clientTelephone}`);
    if (invoice.adresseFournisseur) doc.text(`Fournisseur: ${invoice.adresseFournisseur}`);
    doc.moveDown();

    doc.fontSize(10);
    doc.text('Description | Quantité | Prix Unitaire HT | TVA | Total HT', { underline: true });
    invoice.lignes.forEach(ligne => {
      const totalLigne = ligne.quantite * ligne.prixUnitaireHT;
      doc.text(
        `${ligne.description} | ${ligne.quantite} | ${ligne.prixUnitaireHT} ${invoice.devise} | ${ligne.tauxTVA}% | ${totalLigne.toFixed(2)} ${invoice.devise}`
      );
    });
    doc.moveDown();

    doc.fontSize(12).text('TVA Breakdown:', { underline: true });
    invoice.tvaByRate.forEach(tva => {
      doc.text(`TVA ${tva.rate}%: Base ${tva.baseHT.toFixed(2)} ${invoice.devise}, Montant ${tva.montantTVA.toFixed(2)} ${invoice.devise}`);
    });
    doc.moveDown();

    doc.text(`Frais de livraison: ${invoice.fraisLivraison.toFixed(2)} ${invoice.devise}`, { align: 'right' });
    doc.text(`Agios: ${invoice.agios.toFixed(2)} ${invoice.devise}`, { align: 'right' });
    doc.text(`Total HT: ${invoice.montantHT.toFixed(2)} ${invoice.devise}`, { align: 'right' });
    doc.text(`Total TVA: ${invoice.montantTVA.toFixed(2)} ${invoice.devise}`, { align: 'right' });
    doc.text(`Pénalités: ${(invoice.penalites || 0).toFixed(2)} ${invoice.devise}`, { align: 'right' });
    doc.text(`Total TTC: ${invoice.montantTTC.toFixed(2)} ${invoice.devise}`, { align: 'right' });
    if (invoice.acompte) doc.text(`Acompte: ${invoice.acompte.toFixed(2)} ${invoice.devise}`, { align: 'right' });
    if (invoice.motifAnnulation) doc.text(`Motif annulation: ${invoice.motifAnnulation}`);
    if (invoice.motifAvoir) doc.text(`Motif avoir: ${invoice.motifAvoir}`);
    if (invoice.validiteDevis) doc.text(`Validité devis: ${new Date(invoice.validiteDevis).toLocaleDateString('fr-FR')}`);
    if (invoice.signature) doc.text(`Signature: ${invoice.signature}`);
    doc.moveDown();
    doc.text('Conformément à l’Acte Uniforme OHADA relatif au droit commercial général', { align: 'center' });

    doc.end();
  } catch (err) {
    console.error('Erreur generatePdf:', err.message);
    res.status(500).json({ error: 'Erreur serveur', details: err.message, code: 'SERVER_ERROR' });
  }
};