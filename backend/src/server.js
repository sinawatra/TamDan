const dotenv = require('dotenv');

// Load environment variables
dotenv.config({ path: './.env' });

const app = require('./app');

// Set port
const port = process.env.PORT || 3000;

// Start server
const server = app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

// Handle unhandled rejections
process.on('unhandledRejection', (err) => {
  console.error('UNHANDLED REJECTION! Shutting down...');
  console.error(err.name, err.message);
  server.close(() => {
    process.exit(1);
  });
}); 