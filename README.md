# TamDan

TamDan is a full-stack application with a Flutter frontend and Node.js backend. This project provides a secure and modern mobile interface with authentication capabilities and a RESTful API backend.

## Project Structure

```
tamdan/
├── frontend/         # Flutter mobile application
└── backend/          # Node.js Express API server
```

## Frontend (Flutter)

The frontend is built with Flutter, providing a cross-platform mobile experience.

### Technologies Used

- Flutter SDK (3.1.0+)
- Dart programming language
- Key packages:
  - http: For API communication
  - flutter_secure_storage: For secure token storage
  - google_fonts: For typography
  - image_picker: For handling image selection
  - fl_chart: For data visualization
  - intl: For internationalization

### Features

- Material Design UI
- Secure authentication
- Interactive charts and visualizations
- Image upload functionality
- Responsive layout

### Setup & Running

1. Ensure Flutter is installed on your system
2. Navigate to the frontend directory:
   ```
   cd frontend
   ```
3. Install dependencies:
   ```
   flutter pub get
   ```
4. Run the app:
   ```
   flutter run
   ```

## Backend (Node.js)

The backend provides a RESTful API built with Express.js and uses SQLite for data storage.

### Technologies Used

- Node.js
- Express.js
- SQLite (via sqlite3)
- JSON Web Tokens (JWT) for authentication
- bcrypt for password hashing
- dotenv for environment variables

### API Endpoints

- Authentication:
  - `POST /api/auth/signup`: Register a new user
  - `POST /api/auth/login`: User login
  - `GET /api/auth/logout`: User logout
  - `GET /api/auth/me`: Get current user profile (protected route)

### Database

The application uses SQLite for data persistence, stored in the `backend/data` directory.

### Setup & Running

1. Ensure Node.js is installed on your system
2. Navigate to the backend directory:
   ```
   cd backend
   ```
3. Install dependencies:
   ```
   npm install
   ```
4. Set up environment variables:
   Create a `.env` file with the following variables:
   ```
   PORT=3000
   JWT_SECRET=your-secret-key
   JWT_EXPIRES_IN=90d
   ```
5. Start the server:
   ```
   npm run dev
   ```
   
## Development

To run the entire application in development mode:

1. Start the backend server:
   ```
   cd backend
   npm run dev
   ```
2. In a new terminal, run the Flutter app:
   ```
   cd frontend
   flutter run
   ```

## License

ISC License

## Contribute

Contributions are welcome! Please feel free to submit a Pull Request.
