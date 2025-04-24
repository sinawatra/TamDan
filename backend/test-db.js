const db = require('./src/database/db');

// List all tables first and wait for that to complete
console.log('Checking database tables...');
db.all('SELECT name FROM sqlite_master WHERE type="table"', [], (err, tables) => {
  if (err) {
    console.error('Error querying tables:', err);
    db.close();
    return;
  }
  
  console.log('Tables in database:');
  console.log(tables);
  
  if (tables.length === 0) {
    console.log('No tables found in the database. Tables may not have been created yet.');
    db.close();
    return;
  }
  
  // Describe the expense table
  db.all('PRAGMA table_info(expense)', [], (err, columns) => {
    if (err) {
      console.error('Error describing expense table:', err);
    } else {
      console.log('\nExpense table schema:');
      console.log(columns);
    }
    
    // Describe the income table
    db.all('PRAGMA table_info(income)', [], (err, columns) => {
      if (err) {
        console.error('Error describing income table:', err);
      } else {
        console.log('\nIncome table schema:');
        console.log(columns);
      }
      
      // Close the database connection when done
      db.close();
    });
  });
}); 