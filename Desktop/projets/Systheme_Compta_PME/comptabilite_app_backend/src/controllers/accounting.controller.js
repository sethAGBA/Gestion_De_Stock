//ce fichier est le controller pour la gestion des écritures comptables
// Il contient les fonctions pour créer et récupérer les écritures comptables
// Importation du modèle JournalEntry
//il s'appel accounting.controller.js
// accounting.controller.js
const JournalEntry = require('../models/journal_entry.model');

exports.createEntry = async (req, res) => {
  const { description, debitEntityType, debitEntityName, creditEntityType, creditEntityName, amount, reference } = req.body;
  const userId = req.user.userId;

  // Validation des champs requis
  if (!description || !debitEntityType || !debitEntityName || !creditEntityType || !creditEntityName || !amount) {
    return res.status(400).json({ error: 'Tous les champs requis doivent être fournis' });
  }

  try {
    const entry = new JournalEntry({
      userId,
      description,
      debitEntityType,
      debitEntityName,
      creditEntityType,
      creditEntityName,
      amount: Number(amount), // Convertir en nombre
      reference,
    });
    await entry.save();
    res.status(201).json(entry);
  } catch (err) {
    console.error('Erreur dans createEntry:', err.stack);
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};

exports.getEntries = async (req, res) => {
  const userId = req.user.userId;
  try {
    const entries = await JournalEntry.find({ userId });
    res.status(200).json(entries);
  } catch (err) {
    console.error('Erreur dans getEntries:', err.stack);
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};

exports.updateEntry = async (req, res) => {
  const { id } = req.params;
  const { description, debitEntityType, debitEntityName, creditEntityType, creditEntityName, amount, reference } = req.body;
  const userId = req.user.userId;

  if (!id) {
    return res.status(400).json({ error: 'ID de l’entrée requis' });
  }

  try {
    const entry = await JournalEntry.findOneAndUpdate(
      { _id: id, userId },
      { description, debitEntityType, debitEntityName, creditEntityType, creditEntityName, amount: Number(amount), reference },
      { new: true }
    );
    if (!entry) {
      return res.status(404).json({ error: 'Écriture non trouvée ou non autorisée' });
    }
    res.status(200).json(entry);
  } catch (err) {
    console.error('Erreur dans updateEntry:', err.stack);
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};

exports.deleteEntry = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userId;

  if (!id) {
    return res.status(400).json({ error: 'ID de l’entrée requis' });
  }

  try {
    const entry = await JournalEntry.findOneAndDelete({ _id: id, userId });
    if (!entry) {
      return res.status(404).json({ error: 'Écriture non trouvée ou non autorisée' });
    }
    res.status(200).json({ message: 'Écriture supprimée avec succès' });
  } catch (err) {
    console.error('Erreur dans deleteEntry:', err.stack);
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};