// // const Account = require('../models/account.model');

// // exports.getAccounts = async (req, res) => {
// //   try {
// //     const accounts = await Account.find({ userId: req.user.id });
// //     res.status(200).json(accounts);
// //   } catch (err) {
// //     res.status(500).json({ error: 'Erreur lors de la récupération des comptes' });
// //   }
// // };

// // exports.createAccount = async (req, res) => {
// //   try {
// //     const { number, label } = req.body;
// //     const existing = await Account.findOne({ number, userId: req.user.id });
// //     if (existing) {
// //       return res.status(400).json({ error: 'Numéro de compte déjà utilisé' });
// //     }
// //     const account = new Account({ number, label, userId: req.user.id });
// //     await account.save();
// //     res.status(201).json(account);
// //   } catch (err) {
// //     res.status(500).json({ error: 'Erreur lors de la création du compte' });
// //   }
// // };

// // exports.updateAccount = async (req, res) => {
// //   try {
// //     const { number, label } = req.body;
// //     const account = await Account.findOneAndUpdate(
// //       { number: req.params.number, userId: req.user.id },
// //       { number, label },
// //       { new: true }
// //     );
// //     if (!account) {
// //       return res.status(404).json({ error: 'Compte non trouvé' });
// //     }
// //     res.status(200).json(account);
// //   } catch (err) {
// //     res.status(500).json({ error: 'Erreur lors de la mise à jour' });
// //   }
// // };

// // exports.deleteAccount = async (req, res) => {
// //   try {
// //     const account = await Account.findOneAndDelete({
// //       number: req.params.number,
// //       userId: req.user.id,
// //     });
// //     if (!account) {
// //       return res.status(404).json({ error: 'Compte non trouvé' });
// //     }
// //     res.status(200).json({ message: 'Compte supprimé' });
// //   } catch (err) {
// //     res.status(500).json({ error: 'Erreur lors de la suppression' });
// //   }
// // };


// const Account = require('../models/account.model');
// const accountService = require('../services/account.service');

// exports.getAccounts = async (req, res) => {
//   const userId = req.user.userId;
//   const { page = 1, limit = 20, search } = req.query;
//   try {
//     const query = { userId };
//     if (search) {
//       query.$or = [
//         { number: { $regex: search, $options: 'i' } },
//         { label: { $regex: search, $options: 'i' } },
//       ];
//     }
//     const accounts = await Account.find(query)
//       .skip((page - 1) * limit)
//       .limit(Number(limit));
//     const total = await Account.countDocuments(query);
//     res.status(200).json({ accounts, total, page, limit });
//   } catch (err) {
//     res.status(500).json({ error: 'Erreur serveur', details: err.message });
//   }
// };

// exports.createAccount = async (req, res) => {
//   const userId = req.user.userId;
//   const {
//     number,
//     label,
//     accountClass,
//     accountType,
//     isTVARelated,
//     regimeFiscal,
//     isSelectableForInvoices,
//     supportedCurrencies,
//   } = req.body;

//   try {
//     const accountData = {
//       number,
//       label,
//       accountClass,
//       accountType,
//       isTVARelated,
//       regimeFiscal,
//       isSelectableForInvoices,
//       supportedCurrencies,
//       userId,
//     };
//     await accountService.validateAccount(accountData, userId);
//     const account = new Account(accountData);
//     await account.save();
//     await accountService.logHistory('create', account, userId);
//     res.status(201).json(account);
//   } catch (err) {
//     res.status(400).json({ error: err.message });
//   }
// };

// exports.updateAccount = async (req, res) => {
//   const userId = req.user.userId;
//   const { number } = req.params;
//   const {
//     label,
//     accountClass,
//     accountType,
//     isTVARelated,
//     regimeFiscal,
//     isSelectableForInvoices,
//     supportedCurrencies,
//   } = req.body;

//   try {
//     const account = await Account.findOne({ number, userId });
//     if (!account) {
//       return res.status(404).json({ error: 'Compte non trouvé' });
//     }
//     const updatedData = {
//       number,
//       label,
//       accountClass,
//       accountType,
//       isTVARelated,
//       regimeFiscal,
//       isSelectableForInvoices,
//       supportedCurrencies,
//       userId,
//     };
//     await accountService.validateAccount(updatedData, userId);
//     Object.assign(account, updatedData);
//     await account.save();
//     await accountService.logHistory('update', account, userId);
//     res.status(200).json(account);
//   } catch (err) {
//     res.status(400).json({ error: err.message });
//   }
// };

// exports.deleteAccount = async (req, res) => {
//   const userId = req.user.userId;
//   const { number } = req.params;

//   try {
//     const account = await Account.findOne({ number, userId });
//     if (!account) {
//       return res.status(404).json({ error: 'Compte non trouvé' });
//     }
//     await account.deleteOne();
//     await accountService.logHistory('delete', account, userId);
//     res.status(200).json({ message: 'Compte supprimé et archivé' });
//   } catch (err) {
//     res.status(400).json({ error: err.message });
//   }
// };




const Account = require('../models/account.model');
const accountService = require('../services/account.service');

exports.getAccounts = async (req, res) => {
  const userId = req.user.userId;
  const { page = 1, limit = 20, search } = req.query;
  try {
    const query = { userId };
    if (search) {
      query.$or = [
        { number: { $regex: search, $options: 'i' } },
        { label: { $regex: search, $options: 'i' } },
      ];
    }
    const accounts = await Account.find(query)
      .skip((page - 1) * limit)
      .limit(Number(limit))
      .sort({ number: 1 }); // Tri par numéro pour hiérarchie claire
    const total = await Account.countDocuments(query);
    res.status(200).json({ accounts, total, page, limit });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur', details: err.message });
  }
};

exports.createAccount = async (req, res) => {
  const userId = req.user.userId;
  const {
    number,
    label,
    accountClass,
    accountType,
    parentAccount,
    isTVARelated,
    regimeFiscal,
    isSelectableForInvoices,
    supportedCurrencies,
  } = req.body;

  try {
    const accountData = {
      number,
      label,
      accountClass,
      accountType,
      parentAccount,
      isTVARelated,
      regimeFiscal,
      isSelectableForInvoices,
      supportedCurrencies,
      userId,
    };
    await accountService.validateAccount(accountData, userId);
    const account = new Account(accountData);
    await account.save();
    await accountService.logHistory('create', account, userId);
    res.status(201).json(account);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

exports.updateAccount = async (req, res) => {
  const userId = req.user.userId;
  const { number } = req.params;
  const {
    label,
    accountClass,
    accountType,
    parentAccount,
    isTVARelated,
    regimeFiscal,
    isSelectableForInvoices,
    supportedCurrencies,
  } = req.body;

  try {
    const account = await Account.findOne({ number, userId });
    if (!account) {
      return res.status(404).json({ error: 'Compte non trouvé' });
    }
    const updatedData = {
      number,
      label,
      accountClass,
      accountType,
      parentAccount,
      isTVARelated,
      regimeFiscal,
      isSelectableForInvoices,
      supportedCurrencies,
      userId,
    };
    await accountService.validateAccount(updatedData, userId);
    Object.assign(account, updatedData);
    await account.save();
    await accountService.logHistory('update', account, userId);
    res.status(200).json(account);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

exports.deleteAccount = async (req, res) => {
  const userId = req.user.userId;
  const { number } = req.params;

  try {
    const account = await Account.findOne({ number, userId });
    if (!account) {
      return res.status(404).json({ error: 'Compte non trouvé' });
    }
    await account.deleteOne();
    await accountService.logHistory('delete', account, userId);
    res.status(200).json({ message: 'Compte supprimé et archivé' });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};