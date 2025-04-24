const db = require('../database/db');
const bcrypt = require('bcrypt');

class User {
  // Find a user by email
  static findByEmail(email) {
    return new Promise((resolve, reject) => {
      db.get('SELECT * FROM users WHERE email = ?', [email], (err, row) => {
        if (err) {
          reject(err);
        } else {
          resolve(row);
        }
      });
    });
  }

  // Find a user by ID
  static findById(id) {
    return new Promise((resolve, reject) => {
      db.get('SELECT * FROM users WHERE id = ?', [id], (err, row) => {
        if (err) {
          reject(err);
        } else {
          resolve(row);
        }
      });
    });
  }

  // Create a new user
  static async create(userData) {
    const { name, email, password } = userData;
    
    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 12);
    
    return new Promise((resolve, reject) => {
      db.run(
        'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
        [name, email, hashedPassword],
        function(err) {
          if (err) {
            reject(err);
          } else {
            resolve({
              id: this.lastID,
              name,
              email
            });
          }
        }
      );
    });
  }

  // Verify password
  static async verifyPassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }
}

module.exports = User; 