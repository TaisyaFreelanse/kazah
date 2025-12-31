import { query } from '../db/database.js';

class Phrase {
  static async create(data) {
    const result = await query(
      `INSERT INTO phrases (language, file_url, file_name, file_size, uploaded_by)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [data.language, data.fileUrl, data.fileName, data.fileSize, data.uploadedBy]
    );
    return result.rows[0];
  }

  static async findByLanguage(language) {
    const result = await query(
      'SELECT * FROM phrases WHERE language = $1',
      [language]
    );
    return result.rows[0] || null;
  }

  static async findAll() {
    const result = await query(
      'SELECT * FROM phrases ORDER BY uploaded_at DESC'
    );
    return result.rows;
  }

  static async findById(id) {
    const result = await query(
      'SELECT * FROM phrases WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  static async delete(id) {
    await query('DELETE FROM phrases WHERE id = $1', [id]);
  }

  static async deleteByLanguage(language) {
    await query('DELETE FROM phrases WHERE language = $1', [language]);
  }
}

export { Phrase };
