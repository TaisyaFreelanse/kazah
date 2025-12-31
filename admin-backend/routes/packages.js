import express from 'express';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import { authenticateToken } from '../middleware/auth.js';
import Package from '../models/Package.js';
import fs from 'fs/promises';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

// Настройка multer для загрузки файлов пакетов
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../uploads/packages');
    await fs.mkdir(uploadDir, { recursive: true });
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const packageId = req.params.id;
    const language = req.body.language || 'KZ';
    const ext = path.extname(file.originalname);
    const filename = `package_${packageId}_${language}_${Date.now()}${ext}`;
    cb(null, filename);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ||
        file.mimetype === 'application/vnd.ms-excel') {
      cb(null, true);
    } else {
      cb(new Error('Разрешены только Excel файлы (.xlsx, .xls)'));
    }
  },
});

// Получить все пакеты
router.get('/', authenticateToken, async (req, res) => {
  try {
    const packages = await Package.find().sort({ createdAt: -1 });
    res.json(packages);
  } catch (error) {
    res.status(500).json({ error: 'Ошибка получения пакетов', details: error.message });
  }
});

// Получить один пакет
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const packageItem = await Package.findById(req.params.id);
    if (!packageItem) {
      return res.status(404).json({ error: 'Пакет не найден' });
    }
    res.json(packageItem);
  } catch (error) {
    res.status(500).json({ error: 'Ошибка получения пакета', details: error.message });
  }
});

// Создать новый пакет
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { name, nameKZ, nameRU, iconColor, price, isActive } = req.body;

    const packageItem = new Package({
      name: name || '',
      nameKZ: nameKZ || name || '',
      nameRU: nameRU || name || '',
      iconColor: iconColor || '#4CAF50',
      price: price || 1000,
      isActive: isActive !== undefined ? isActive : true,
    });

    await packageItem.save();
    res.json({ message: 'Пакет создан успешно', package: packageItem });
  } catch (error) {
    res.status(500).json({ error: 'Ошибка создания пакета', details: error.message });
  }
});

// Обновить пакет
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { name, nameKZ, nameRU, iconColor, price, isActive } = req.body;

    const packageItem = await Package.findById(req.params.id);
    if (!packageItem) {
      return res.status(404).json({ error: 'Пакет не найден' });
    }

    if (name !== undefined) packageItem.name = name;
    if (nameKZ !== undefined) packageItem.nameKZ = nameKZ;
    if (nameRU !== undefined) packageItem.nameRU = nameRU;
    if (iconColor !== undefined) packageItem.iconColor = iconColor;
    if (price !== undefined) packageItem.price = price;
    if (isActive !== undefined) packageItem.isActive = isActive;

    await packageItem.save();
    res.json({ message: 'Пакет обновлен успешно', package: packageItem });
  } catch (error) {
    res.status(500).json({ error: 'Ошибка обновления пакета', details: error.message });
  }
});

// Удалить пакет
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const packageItem = await Package.findById(req.params.id);
    if (!packageItem) {
      return res.status(404).json({ error: 'Пакет не найден' });
    }

    // Удаляем файлы пакета
    if (packageItem.files.kz?.fileUrl) {
      try {
        await fs.unlink(path.join(__dirname, '..', packageItem.files.kz.fileUrl));
      } catch (err) {
        console.error('Ошибка удаления файла KZ:', err);
      }
    }
    if (packageItem.files.ru?.fileUrl) {
      try {
        await fs.unlink(path.join(__dirname, '..', packageItem.files.ru.fileUrl));
      } catch (err) {
        console.error('Ошибка удаления файла RU:', err);
      }
    }

    await Package.deleteOne({ _id: req.params.id });
    res.json({ message: 'Пакет успешно удален' });
  } catch (error) {
    res.status(500).json({ error: 'Ошибка удаления пакета', details: error.message });
  }
});

// Загрузить файл для пакета
router.post('/:id/upload', authenticateToken, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Файл не загружен' });
    }

    const { language } = req.body;
    if (!language || !['KZ', 'RU'].includes(language)) {
      await fs.unlink(req.file.path);
      return res.status(400).json({ error: 'Язык должен быть KZ или RU' });
    }

    const packageItem = await Package.findById(req.params.id);
    if (!packageItem) {
      await fs.unlink(req.file.path);
      return res.status(404).json({ error: 'Пакет не найден' });
    }

    // Удаляем старый файл, если существует
    const oldFile = packageItem.files[language.toLowerCase()];
    if (oldFile?.fileUrl) {
      try {
        await fs.unlink(path.join(__dirname, '..', oldFile.fileUrl));
      } catch (err) {
        console.error('Ошибка удаления старого файла:', err);
      }
    }

    // Обновляем информацию о файле
    packageItem.files[language.toLowerCase()] = {
      fileUrl: `/uploads/packages/${req.file.filename}`,
      fileName: req.file.originalname,
      fileSize: req.file.size,
      uploadedAt: new Date(),
    };

    await packageItem.save();

    res.json({
      message: 'Файл успешно загружен',
      package: packageItem,
    });
  } catch (error) {
    if (req.file) {
      await fs.unlink(req.file.path).catch(() => {});
    }
    res.status(500).json({ error: 'Ошибка загрузки файла', details: error.message });
  }
});

// Удалить файл пакета
router.delete('/:id/file/:language', authenticateToken, async (req, res) => {
  try {
    const { id, language } = req.params;
    if (!['KZ', 'RU'].includes(language.toUpperCase())) {
      return res.status(400).json({ error: 'Неверный язык' });
    }

    const packageItem = await Package.findById(id);
    if (!packageItem) {
      return res.status(404).json({ error: 'Пакет не найден' });
    }

    const fileInfo = packageItem.files[language.toLowerCase()];
    if (fileInfo?.fileUrl) {
      try {
        await fs.unlink(path.join(__dirname, '..', fileInfo.fileUrl));
      } catch (err) {
        console.error('Ошибка удаления файла:', err);
      }
    }

    packageItem.files[language.toLowerCase()] = {};
    await packageItem.save();

    res.json({ message: 'Файл успешно удален' });
  } catch (error) {
    res.status(500).json({ error: 'Ошибка удаления файла', details: error.message });
  }
});

export default router;

