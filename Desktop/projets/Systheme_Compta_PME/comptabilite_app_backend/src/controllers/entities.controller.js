//ce fichier s'appel entities.controller.js


const Supplier = require('../models/supplier.model');
const Client = require('../models/client.model');
const Bank = require('../models/bank.model');

exports.createSupplier = async (req, res) => {
  const { name, contact } = req.body;
  const userId = req.user.userId;
  try {
    const supplier = new Supplier({ userId, name, contact });
    await supplier.save();
    res.status(201).json(supplier);
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

exports.getSuppliers = async (req, res) => {
  const userId = req.user.userId;
  try {
    const suppliers = await Supplier.find({ userId });
    res.status(200).json(suppliers);
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

exports.createClient = async (req, res) => {
  const { name, contact } = req.body;
  const userId = req.user.userId;
  try {
    const client = new Client({ userId, name, contact });
    await client.save();
    res.status(201).json(client);
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

exports.getClients = async (req, res) => {
  const userId = req.user.userId;
  try {
    const clients = await Client.find({ userId });
    res.status(200).json(clients);
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

exports.createBank = async (req, res) => {
  const { name, balance } = req.body;
  const userId = req.user.userId;
  try {
    const bank = new Bank({ userId, name, balance });
    await bank.save();
    res.status(201).json(bank);
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

exports.getBanks = async (req, res) => {
  const userId = req.user.userId;
  try {
    const banks = await Bank.find({ userId });
    res.status(200).json(banks);
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};