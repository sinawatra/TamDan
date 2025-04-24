const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');

// Initialize express app
const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());

// Routes
app.use('/api/auth', authRoutes);

// Root route
app.get('/', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Welcome to the API'
  });
});

// Error handling for non-existent routes
app.all('*', (req, res) => {
  res.status(404).json({
    status: 'fail',
    message: `Route ${req.originalUrl} not found`
  });
});

module.exports = app; 