import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import { initDatabase, getPool } from './db/database.js';
import authRoutes from './routes/auth.js';
import publicQuestionsRoutes from './routes/publicQuestions.js';
import publicQuestionsPublicRoutes from './routes/publicQuestionsPublic.js';
import packagesRoutes from './routes/packages.js';
import publicPackagesRoutes from './routes/publicPackages.js';
import phrasesRoutes from './routes/phrases.js';
import publicPhrasesPublicRoutes from './routes/publicPhrasesPublic.js';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

(async () => {
  try {
    await initDatabase();
    const pool = getPool();
    await pool.query('SELECT NOW()');
    console.log('✅ PostgreSQL подключена');
  } catch (err) {
    console.error('❌ Ошибка подключения к PostgreSQL:', err);
  }
})();

app.use('/api/auth', authRoutes);
app.use('/api/public-questions', publicQuestionsRoutes);
app.use('/api/public/questions', publicQuestionsPublicRoutes);
app.use('/api/packages', packagesRoutes);
app.use('/api/public/packages', publicPackagesRoutes);
app.use('/api/phrases', phrasesRoutes);
app.use('/api/public/phrases', publicPhrasesPublicRoutes);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Blim Bilem Admin API is running'   });
});

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

