import { query } from '../db/database.js';

class Package {
  static async create(data) {
    const result = await query(
      `INSERT INTO packages (name, name_kz, name_ru, icon_color, price, is_active)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        data.name || '',
        data.nameKZ || data.name || '',
        data.nameRU || data.name || '',
        data.iconColor || '#4CAF50',
        data.price || 1000,
        data.isActive !== undefined ? data.isActive : true,
      ]
    );
    return result.rows[0];
  }

  static async findAll() {
    const result = await query(
      'SELECT * FROM packages ORDER BY created_at DESC'
    );
    const packages = result.rows;

    // Загружаем файлы для каждого пакета
    for (const pkg of packages) {
      const filesResult = await query(
        'SELECT * FROM package_files WHERE package_id = $1',
        [pkg.id]
      );
      pkg.files = {
        kz: filesResult.rows.find(f => f.language === 'KZ') || {},
        ru: filesResult.rows.find(f => f.language === 'RU') || {},
      };
    }

    return packages;
  }

  static async findById(id) {
    const result = await query(
      'SELECT * FROM packages WHERE id = $1',
      [id]
    );
    if (result.rows.length === 0) return null;

    const pkg = result.rows[0];

    // Загружаем файлы
    const filesResult = await query(
      'SELECT * FROM package_files WHERE package_id = $1',
      [id]
    );
    pkg.files = {
      kz: filesResult.rows.find(f => f.language === 'KZ') || {},
      ru: filesResult.rows.find(f => f.language === 'RU') || {},
    };

    return pkg;
  }

  static async update(id, data) {
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (data.name !== undefined) {
      updates.push(`name = $${paramCount++}`);
      values.push(data.name);
    }
    if (data.nameKZ !== undefined) {
      updates.push(`name_kz = $${paramCount++}`);
      values.push(data.nameKZ);
    }
    if (data.nameRU !== undefined) {
      updates.push(`name_ru = $${paramCount++}`);
      values.push(data.nameRU);
    }
    if (data.iconColor !== undefined) {
      updates.push(`icon_color = $${paramCount++}`);
      values.push(data.iconColor);
    }
    if (data.price !== undefined) {
      updates.push(`price = $${paramCount++}`);
      values.push(data.price);
    }
    if (data.isActive !== undefined) {
      updates.push(`is_active = $${paramCount++}`);
      values.push(data.isActive);
    }

    if (updates.length === 0) {
      return await this.findById(id);
    }

    updates.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(id);

    await query(
      `UPDATE packages SET ${updates.join(', ')} WHERE id = $${paramCount}`,
      values
    );

    return await this.findById(id);
  }

  static async delete(id) {
    // Файлы удалятся автоматически из-за ON DELETE CASCADE
    await query('DELETE FROM packages WHERE id = $1', [id]);
  }

  static async updateFile(packageId, language, fileData) {
    // Удаляем старый файл, если есть
    await query(
      'DELETE FROM package_files WHERE package_id = $1 AND language = $2',
      [packageId, language]
    );

    // Вставляем новый файл
    if (fileData.fileUrl) {
      await query(
        `INSERT INTO package_files (package_id, language, file_url, file_name, file_size, uploaded_at)
         VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
         ON CONFLICT (package_id, language) DO UPDATE
         SET file_url = $3, file_name = $4, file_size = $5, uploaded_at = CURRENT_TIMESTAMP`,
        [
          packageId,
          language,
          fileData.fileUrl,
          fileData.fileName,
          fileData.fileSize,
        ]
      );
    }
  }

  static async deleteFile(packageId, language) {
    await query(
      'DELETE FROM package_files WHERE package_id = $1 AND language = $2',
      [packageId, language]
    );
  }
}

export { Package };
