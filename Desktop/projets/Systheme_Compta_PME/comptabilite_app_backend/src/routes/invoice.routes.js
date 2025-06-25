// // // //invoice.routes.js
// // // // const express = require('express');
// // // // const router = express.Router();
// // // // const invoiceController = require('../controllers/invoice.controller');
// // // // const authMiddleware = require('../middlewares/auth.middleware');

// // // // router.post('/', authMiddleware, invoiceController.createInvoice);
// // // // router.get('/', authMiddleware, invoiceController.getInvoices);
// // // // router.put('/status', authMiddleware, invoiceController.updateInvoiceStatus);

// // // // module.exports = router;

// // // const express = require('express');
// // // const router = express.Router();
// // // const invoiceController = require('../controllers/invoice.controller');
// // // const authMiddleware = require('../middlewares/auth.middleware');
// // // router.post('/', authMiddleware, invoiceController.createInvoice);
// // // router.put('/:id/convert', authMiddleware, invoiceController.convertDevis);
// // // router.put('/:id/cancel', authMiddleware, invoiceController.cancelInvoice);

// // // // router.post('/', authMiddleware, invoiceController.createInvoice);
// // // router.get('/', authMiddleware, invoiceController.getInvoices);
// // // router.put('/status', authMiddleware, invoiceController.updateInvoiceStatus);
// // // router.delete('/:id', authMiddleware, invoiceController.deleteInvoice); // Nouvelle route DELETE
// // // router.put('/:id', authMiddleware, invoiceController.updateInvoice);    // Nouvelle route PUT

// // // module.exports = router;

// // // invoice.routes.js



// // // const express = require('express');
// // // const router = express.Router();
// // // const invoiceController = require('../controllers/invoice.controller');
// // // const authMiddleware = require('../middlewares/auth.middleware'); // Correction du chemin

// // // // Appliquer le middleware d'authentification à toutes les routes
// // // router.use(authMiddleware);

// // // // Routes CRUD de base
// // // router.post('/', invoiceController.createInvoice);
// // // router.get('/', invoiceController.getInvoices);
// // // router.get('/:id', invoiceController.getInvoice);
// // // router.put('/:id', invoiceController.updateInvoice);
// // // router.delete('/:id', invoiceController.deleteInvoice);

// // // // Routes spécifiques aux factures
// // // router.put('/:id/status', invoiceController.updateInvoiceStatus);
// // // router.put('/:id/cancel', invoiceController.cancelInvoice);
// // // router.put('/:id/convert', invoiceController.convertDevis);
// // // router.post('/final', invoiceController.createFinalInvoice);
// // // router.delete('/:id', authMiddleware, invoiceController.deleteInvoice);
// // // module.exports = router;

// // // filepath: /Users/cavris/Desktop/projets/Systheme_Compta_PME/comptabilite_app_backend/src/routes/invoice.routes.js

// // const express = require('express');
// // const router = express.Router();
// // const invoiceController = require('../controllers/invoice.controller');
// // const authMiddleware = require('../middlewares/auth.middleware');

// // // Routes CRUD de base
// // router.post('/', authMiddleware, invoiceController.createInvoice);
// // router.get('/', authMiddleware, invoiceController.getInvoices);
// // router.get('/:id', authMiddleware, invoiceController.getInvoice);
// // router.put('/:id', authMiddleware, invoiceController.updateInvoice);
// // router.delete('/:id', invoiceController.deleteInvoice); // Sans authMiddleware

// // // Routes spécifiques aux factures
// // router.put('/:id/status', authMiddleware, invoiceController.updateInvoiceStatus);
// // router.patch('/:id/cancel', authMiddleware, invoiceController.cancelInvoice);
// // router.put('/:id/convert', authMiddleware, invoiceController.convertDevis);
// // router.post('/final', authMiddleware, invoiceController.createFinalInvoice);

// // module.exports = router;


// // filepath: /Users/cavris/Desktop/projets/Systheme_Compta_PME/comptabilite_app_backend/src/routes/invoice.routes.js

// const express = require('express');
// const router = express.Router();
// const invoiceController = require('../controllers/invoice.controller');
// const authMiddleware = require('../middlewares/auth.middleware');

// // Routes CRUD de base
// router.post('/', authMiddleware, invoiceController.createInvoice);
// router.get('/', authMiddleware, invoiceController.getInvoices);
// router.get('/:id', authMiddleware, invoiceController.getInvoice);
// router.put('/:id', authMiddleware, invoiceController.updateInvoice);
// router.delete('/:id', authMiddleware, invoiceController.deleteInvoice);

// // Routes spécifiques aux factures
// router.put('/:id/status', authMiddleware, invoiceController.updateInvoiceStatus);
// router.patch('/:id/cancel', authMiddleware, invoiceController.cancelInvoice);
// router.put('/:id/convert', authMiddleware, invoiceController.convertDevis);
// router.post('/final', authMiddleware, invoiceController.createFinalInvoice);
// router.get('/:id/pdf', authMiddleware, invoiceController.generatePdf);

// module.exports = router;





const express = require('express');
const router = express.Router();
const invoiceController = require('../controllers/invoice.controller');
const authMiddleware = require('../middlewares/auth.middleware');
const validateInvoice = require('../middlewares/validateInvoice');

// Routes CRUD de base
router.post('/', authMiddleware, validateInvoice, invoiceController.createInvoice);
router.get('/', authMiddleware, invoiceController.getInvoices);
router.get('/:id', authMiddleware, invoiceController.getInvoice);
router.put('/:id', authMiddleware, validateInvoice, invoiceController.updateInvoice);
router.delete('/:id', authMiddleware, invoiceController.deleteInvoice);

// Routes spécifiques aux factures
router.post('/generate-number', authMiddleware, invoiceController.generateInvoiceNumber);
router.put('/:id/status', authMiddleware, invoiceController.updateInvoiceStatus);
router.patch('/:id/cancel', authMiddleware, invoiceController.cancelInvoice);
router.put('/:id/convert', authMiddleware, invoiceController.convertDevis);
router.post('/final', authMiddleware, validateInvoice, invoiceController.createFinalInvoice);
router.get('/:id/pdf', authMiddleware, invoiceController.generatePdf);

module.exports = router;