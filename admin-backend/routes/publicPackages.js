import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { Package } from '../models/Package.js';
import fs from 'fs/promises';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

router.get('/ids', async (req, res) => {
  try {
    const packages = await Package.findActive();
    const ids = packages.map(pkg => pkg.id);
    res.json(ids);
  } catch (error) {
    res.status(500).json({ error: 'Ошибка получения ID пакетов', details: error.message });
  }
});

router.get('/', async (req, res) => {
  try {
    const packages = await Package.findActive();
    
    const formattedPackages = packages.map(pkg => ({
      id: pkg.id,
      name: pkg.name,
      nameKZ: pkg.name_kz || pkg.nameKZ,
      nameRU: pkg.name_ru || pkg.nameRU,
      iconColor: pkg.icon_color || pkg.iconColor,
      price: pkg.price,
      isActive: pkg.is_active !== undefined ? pkg.is_active : pkg.isActive,
      hasFiles: {
        kz: !!(pkg.files?.kz?.file_url),
        ru: !!(pkg.files?.ru?.file_url),
      },
    }));

    res.json(formattedPackages);
  } catch (error) {
    res.status(500).json({ error: 'Ошибка получения пакетов', details: error.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const packageItem = await Package.findById(req.params.id);
    
    if (!packageItem) {
      return res.status(404).json({ error: 'Пакет не найден' });
    }

    if (!packageItem.is_active && !packageItem.isActive) {
      return res.status(404).json({ error: 'Пакет не доступен' });
    }

    const formattedPackage = {
      id: packageItem.id,
      name: packageItem.name,
      nameKZ: packageItem.name_kz || packageItem.nameKZ,
      nameRU: packageItem.name_ru || packageItem.nameRU,
      iconColor: packageItem.icon_color || packageItem.iconColor,
      price: packageItem.price,
      isActive: packageItem.is_active !== undefined ? packageItem.is_active : packageItem.isActive,
      hasFiles: {
        kz: !!(packageItem.files?.kz?.file_url),
        ru: !!(packageItem.files?.ru?.file_url),
      },
    };

    res.json(formattedPackage);
  } catch (error) {
    res.status(500).json({ error: 'Ошибка получения пакета', details: error.message });
  }
});

router.get('/:id/files/:language', async (req, res) => {
  try {
    const { id, language } = req.params;
    
    if (!['KZ', 'RU'].includes(language.toUpperCase())) {
      return res.status(400).json({ error: 'Неверный язык. Должен быть KZ или RU' });
    }

    const packageItem = await Package.findById(id);
    
    if (!packageItem) {
      return res.status(404).json({ error: 'Пакет не найден' });
    }

    if (!packageItem.is_active && !packageItem.isActive) {
      return res.status(404).json({ error: 'Пакет не доступен' });
    }

    const fileInfo = packageItem.files[language.toLowerCase()];
    
    if (!fileInfo || !fileInfo.file_url) {
      return res.status(404).json({ error: `Файл на ${language === 'KZ' ? 'казахском' : 'русском'} языке не найден` });
    }

    const filePath = path.join(__dirname, '..', fileInfo.file_url);
    
    try {
      await fs.access(filePath);
    } catch (err) {
      return res.status(404).json({ error: 'Файл не найден на сервере' });
    }

    res.download(filePath, fileInfo.file_name || `package_${id}_${language}.xlsx`, (err) => {
      if (err) {
        console.error('Ошибка отправки файла:', err);
        if (!res.headersSent) {
          res.status(500).json({ error: 'Ошибка отправки файла' });
        }
      }
    });
  } catch (error) {
    console.error('Ошибка получения файла пакета:', error);
    res.status(500).json({ error: 'Ошибка получения файла', details: error.message });
  }
});

export default router;

