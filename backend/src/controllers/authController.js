const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Generate JWT token
const signToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN
  });
};

// Create and send token as response
const createSendToken = (user, statusCode, res) => {
  const token = signToken(user.id);

  // Remove password from output
  const userResponse = {
    id: user.id,
    name: user.name,
    email: user.email
  };

  res.status(statusCode).json({
    status: 'success',
    token,
    data: {
      user: userResponse
    }
  });
};

// User signup
exports.signup = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    // Check if email already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return res.status(400).json({
        status: 'fail',
        message: 'Email already in use'
      });
    }

    // Create new user
    const newUser = await User.create({
      name,
      email,
      password
    });

    // Send token response
    createSendToken(newUser, 201, res);
  } catch (err) {
    res.status(500).json({
      status: 'error',
      message: err.message
    });
  }
};

// User login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Check if email and password are provided
    if (!email || !password) {
      return res.status(400).json({
        status: 'fail',
        message: 'Please provide email and password'
      });
    }

    // Find user by email
    const user = await User.findByEmail(email);
    if (!user) {
      return res.status(401).json({
        status: 'fail',
        message: 'Invalid email or password'
      });
    }

    // Verify password
    const isPasswordCorrect = await User.verifyPassword(password, user.password);
    if (!isPasswordCorrect) {
      return res.status(401).json({
        status: 'fail',
        message: 'Invalid email or password'
      });
    }

    // Send token response
    createSendToken(user, 200, res);
  } catch (err) {
    res.status(500).json({
      status: 'error',
      message: err.message
    });
  }
};

// Logout (client-side)
exports.logout = (req, res) => {
  res.status(200).json({ status: 'success' });
}; 