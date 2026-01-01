import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { PublicQuestion } from '../models/PublicQuestion.js';
import fs from 'fs/promises';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

// Публичный endpoint для скачивания базовых вопросов (для Android приложения)
// Не требует авторизации
router.get('/files/:language', async (req, res) => {
  try {
    const { language } = req.params;
    
    if (!['KZ', 'RU'].includes(language.toUpperCase())) {
      return res.status(400).json({ error: 'Неверный язык. Должен быть KZ или RU' });
    }

    // Ищем файл для указанного языка
    const question = await PublicQuestion.findByLanguage(language.toUpperCase());
    
    if (!question || !question.file_url) {
      return res.status(404).json({ error: `Файл на ${language === 'KZ' ? 'казахском' : 'русском'} языке не найден` });
    }

    // Путь к файлу на сервере
    const filePath = path.join(__dirname, '..', question.file_url);
    
    // Проверяем существование файла
    try {
      await fs.access(filePath);
    } catch (err) {
      return res.status(404).json({ error: 'Файл не найден на сервере' });
    }

    // Отправляем файл
    res.download(filePath, question.file_name || `questions_${language}.xlsx`, (err) => {
      if (err) {
        console.error('Ошибка отправки файла:', err);
        if (!res.headersSent) {
          res.status(500).json({ error: 'Ошибка отправки файла' });
        }
      }
    });
  } catch (error) {
    console.error('Ошибка получения файла базовых вопросов:', error);
    res.status(500).json({ error: 'Ошибка получения файла', details: error.message });
  }
});

export default router;

