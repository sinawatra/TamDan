const express = require('express');
const transactionController = require('../controllers/transactionController');

const router = express.Router();

// Routes for handling expense and income
router.post('/expense', transactionController.addExpense);
router.post('/income', transactionController.addIncome);
router.get('/transactions', transactionController.getTransactions);

module.exports = router; 