// const express = require('express');
// const router = express.Router();
// const accountsController = require('../controllers/accounts.controller');
// const authMiddleware = require('../middlewares/auth.middleware');

// router.get('/', authMiddleware, accountsController.getAccounts);
// router.post('/', authMiddleware, accountsController.createAccount);
// router.put('/:number', authMiddleware, accountsController.updateAccount);
// router.delete('/:number', authMiddleware, accountsController.deleteAccount);

// module.exports = router;


const express = require('express');
const router = express.Router();
const accountsController = require('../controllers/accounts.controller');
const authMiddleware = require('../middlewares/auth.middleware');

router.get('/', authMiddleware, accountsController.getAccounts);
router.post('/', authMiddleware, accountsController.createAccount);
router.put('/:number', authMiddleware, accountsController.updateAccount);
router.delete('/:number', authMiddleware, accountsController.deleteAccount);

module.exports = router;