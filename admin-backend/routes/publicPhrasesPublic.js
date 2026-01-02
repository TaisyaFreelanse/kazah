import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { Phrase } from '../models/Phrase.js';
import fs from 'fs/promises';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

router.get('/files/:language', async (req, res) => {
  try {
    const { language } = req.params;
    
    console.log(`Запрос финальных фраз для языка: ${language}`);
    
    if (!['KZ', 'RU', 'kz', 'ru'].includes(language)) {
      return res.status(400).json({ error: 'Неверный язык. Должен быть KZ или RU' });
    }

    const normalizedLanguage = language.toUpperCase();
    const phrase = await Phrase.findByLanguage(normalizedLanguage);
    
    console.log(`Найдена запись: ${phrase ? JSON.stringify(phrase) : 'null'}`);
    
    if (!phrase || !phrase.file_url) {
      return res.status(404).json({ 
        error: `Файл финальных фраз на ${normalizedLanguage === 'KZ' ? 'казахском' : 'русском'} языке не найден` 
      });
    }

    const filePath = path.join(__dirname, '..', phrase.file_url);
    
    try {
      await fs.access(filePath);
    } catch (err) {
      console.error(`Файл не найден: ${filePath}`, err);
      return res.status(404).json({ error: 'Файл не найден на сервере' });
    }

    res.download(filePath, phrase.file_name || `phrases_${normalizedLanguage}.xlsx`, (err) => {
      if (err) {
        console.error('Ошибка отправки файла:', err);
        if (!res.headersSent) {
          res.status(500).json({ error: 'Ошибка отправки файла' });
        }
      } else {
        console.log(`Файл успешно отправлен: ${phrase.file_name}`);
      }
    });
  } catch (error) {
    console.error('Ошибка получения файла финальных фраз:', error);
    res.status(500).json({ error: 'Ошибка получения файла', details: error.message });
  }
});

export default router;

