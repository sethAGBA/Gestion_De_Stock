const validateInvoice = (req, res, next) => {
    const { rccm, clientRccm, devise, lignes, penalites, type } = req.body;
  
    const rccmRegex = /^RC\/[A-Z]{2}\/[A-Z]{3}\/[0-9]{4}\/[A-Z][0-9]{5}$/;
    if (!rccm || !rccmRegex.test(rccm)) {
      return res.status(400).json({ error: 'RCCM invalide. Format attendu : RC/TG/LOM/2024/A12345' });
    }
    if (clientRccm && !rccmRegex.test(clientRccm)) {
      return res.status(400).json({ error: 'RCCM client invalide' });
    }
    if (devise !== 'XOF') {
      return res.status(400).json({ error: 'Devise non supportée. Utilisez XOF pour l’UEMOA' });
    }
    if (!lignes || !lignes.every(ligne => [0, 5, 10, 18, 19].includes(ligne.tauxTVA))) {
      return res.status(400).json({ error: 'Taux de TVA non conforme (0%, 5%, 10%, 18%, 19%)' });
    }
    if ((type === 'standard' || type === 'acompte') && (!penalites || penalites < 0)) {
      return res.status(400).json({ error: 'Pénalités de retard obligatoires pour standard ou acompte' });
    }
  
    next();
  };
  
  module.exports = validateInvoice;