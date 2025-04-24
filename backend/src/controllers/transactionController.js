const db = require('../database/db');

// Add a new expense to the database
exports.addExpense = (req, res) => {
  const { userId, amount, category, date } = req.body;
  
  if (!userId || !amount || !category || !date) {
    return res.status(400).json({
      status: 'error',
      message: 'Missing required fields'
    });
  }

  const query = `
    INSERT INTO expense (user_id, amount, category, date)
    VALUES (?, ?, ?, ?)
  `;

  db.run(query, [userId, amount, category, date], function(err) {
    if (err) {
      console.error('Error adding expense:', err.message);
      return res.status(500).json({
        status: 'error',
        message: 'Failed to add expense'
      });
    }

    return res.status(201).json({
      status: 'success',
      data: {
        id: this.lastID,
        userId,
        amount,
        category,
        date
      }
    });
  });
};

// Add a new income to the database
exports.addIncome = (req, res) => {
  const { userId, amount, category, date } = req.body;
  
  if (!userId || !amount || !category || !date) {
    return res.status(400).json({
      status: 'error',
      message: 'Missing required fields'
    });
  }

  const query = `
    INSERT INTO income (user_id, amount, category, date)
    VALUES (?, ?, ?, ?)
  `;

  db.run(query, [userId, amount, category, date], function(err) {
    if (err) {
      console.error('Error adding income:', err.message);
      return res.status(500).json({
        status: 'error',
        message: 'Failed to add income'
      });
    }

    return res.status(201).json({
      status: 'success',
      data: {
        id: this.lastID,
        userId,
        amount,
        category,
        date
      }
    });
  });
};

// Get all transactions for a user
exports.getTransactions = (req, res) => {
  const userId = req.query.userId;
  
  if (!userId) {
    return res.status(400).json({
      status: 'error',
      message: 'User ID is required'
    });
  }

  const expenseQuery = `
    SELECT id, amount, category, date, 'expense' as type
    FROM expense
    WHERE user_id = ?
  `;

  const incomeQuery = `
    SELECT id, amount, category, date, 'income' as type
    FROM income
    WHERE user_id = ?
  `;

  // Get expenses
  db.all(expenseQuery, [userId], (err, expenses) => {
    if (err) {
      console.error('Error fetching expenses:', err.message);
      return res.status(500).json({
        status: 'error',
        message: 'Failed to fetch transactions'
      });
    }

    // Get incomes
    db.all(incomeQuery, [userId], (err, incomes) => {
      if (err) {
        console.error('Error fetching incomes:', err.message);
        return res.status(500).json({
          status: 'error',
          message: 'Failed to fetch transactions'
        });
      }

      // Combine and sort by date (newest first)
      const transactions = [...expenses, ...incomes].sort((a, b) => {
        return new Date(b.date) - new Date(a.date);
      });

      return res.status(200).json({
        status: 'success',
        data: transactions
      });
    });
  });
}; 