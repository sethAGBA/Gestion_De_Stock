// const Account = require('../models/account.model');
// const AccountHistory = require('../models/account_history.model');

// exports.validateAccount = async (accountData, userId) => {
//   const { number, accountClass } = accountData;
//   if (!/^\d{2,5}$/.test(number) || !/^[1-9]/.test(number)) {
//     throw new Error('Numéro invalide (2-5 chiffres, commence par 1-9)');
//   }
//   if (!accountClass.startsWith('classe' + number[0])) {
//     throw new Error('Classe comptable incohérente avec le numéro');
//   }
//   const existing = await Account.findOne({ number, userId });
//   if (existing) {
//     throw new Error('Numéro de compte déjà utilisé');
//   }
// };

// exports.logHistory = async (action, account, userId) => {
//   await AccountHistory.create({
//     accountNumber: account.number,
//     action,
//     userId,
//     changes: account,
//     modifiedAt: new Date(),
//   });
// };

// exports.checkAccountUsage = async (accountNumber, userId) => {
//   const JournalEntry = require('../models/journal_entry.model');
//   const entries = await JournalEntry.find({
//     $or: [{ debitAccount: accountNumber }, { creditAccount: accountNumber }],
//     userId,
//   });
//   return entries.length > 0;
// };




const Account = require('../models/account.model');
const AccountHistory = require('../models/account_history.model');

exports.validateAccount = async (accountData, userId) => {
  const { number, accountClass, parentAccount } = accountData;

  // Validation du numéro
  if (!/^\d{2,8}$/.test(number) || !/^[1-9]/.test(number)) {
    throw new Error('Numéro invalide (2-8 chiffres, commence par 1-9)');
  }

  // Validation de la classe
  if (!accountClass.startsWith('classe' + number[0])) {
    throw new Error('Classe comptable incohérente avec le numéro');
  }

  // Validation de l’unicité
  const existing = await Account.findOne({ number, userId });
  if (existing) {
    throw new Error('Numéro de compte déjà utilisé');
  }

  // Validation du parent
  if (parentAccount) {
    const parent = await Account.findOne({ number: parentAccount, userId });
    if (!parent) {
      throw new Error('Compte parent non trouvé');
    }
    if (!number.startsWith(parentAccount)) {
      throw new Error('Numéro du sous-compte doit commencer par celui du parent');
    }
  }
};

exports.logHistory = async (action, account, userId) => {
  await AccountHistory.create({
    accountNumber: account.number,
    action,
    userId,
    changes: account,
    modifiedAt: new Date(),
  });
};

exports.checkAccountUsage = async (accountNumber, userId) => {
  const JournalEntry = require('../models/journal_entry.model');
  const entries = await JournalEntry.find({
    $or: [{ debitAccount: accountNumber }, { creditAccount: accountNumber }],
    userId,
  });
  return entries.length > 0;
};