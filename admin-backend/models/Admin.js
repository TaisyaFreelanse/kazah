import { query } from '../db/database.js';
import bcrypt from 'bcryptjs';

class Admin {
  static async create(username, password) {
    const hashedPassword = await bcrypt.hash(password, 10);
    const result = await query(
      'INSERT INTO admins (username, password) VALUES ($1, $2) RETURNING id, username, created_at',
      [username, hashedPassword]
    );
    return result.rows[0];
  }

  static async findByUsername(username) {
    const result = await query(
      'SELECT * FROM admins WHERE username = $1',
      [username]
    );
    return result.rows[0] || null;
  }

  static async findById(id) {
    const result = await query(
      'SELECT id, username, created_at FROM admins WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  static async count() {
    const result = await query('SELECT COUNT(*) FROM admins');
    return parseInt(result.rows[0].count);
  }

  static async updatePassword(id, newPassword) {
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await query(
      'UPDATE admins SET password = $1 WHERE id = $2',
      [hashedPassword, id]
    );
  }

  async comparePassword(candidatePassword, hashedPassword) {
    return await bcrypt.compare(candidatePassword, hashedPassword);
  }
}

export { Admin };
