import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import mongoose from 'mongoose';
import authRoutes from './routes/auth.js';
import publicQuestionsRoutes from './routes/publicQuestions.js';
import packagesRoutes from './routes/packages.js';
import phrasesRoutes from './routes/phrases.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Подключение к MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/blim-bilem', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ MongoDB подключена'))
.catch((err) => console.error('❌ Ошибка подключения к MongoDB:', err));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/public-questions', publicQuestionsRoutes);
app.use('/api/packages', packagesRoutes);
app.use('/api/phrases', phrasesRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Blim Bilem Admin API is running' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Что-то пошло не так!', 
    message: process.env.NODE_ENV === 'development' ? err.message : undefined 
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Сервер запущен на порту ${PORT}`);
  console.log(`📝 Режим: ${process.env.NODE_ENV || 'development'}`);
});

