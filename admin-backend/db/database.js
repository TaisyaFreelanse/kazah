import pkg from 'pg';
const { Pool } = pkg;

let pool = null;

export const getPool = () => {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL || process.env.POSTGRES_URL;
    const isRender = connectionString && connectionString.includes('render.com');
    
    pool = new Pool({
      connectionString: connectionString,
      ssl: isRender || process.env.NODE_ENV === 'production' 
        ? { rejectUnauthorized: false } 
        : false,
    });

    pool.on('error', (err) => {
      console.error('Unexpected error on idle client', err);
    });
  }
  return pool;
};

export const initDatabase = async () => {
  const pool = getPool();
  
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS admins (
        id SERIAL PRIMARY KEY,
        username VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS public_questions (
        id SERIAL PRIMARY KEY,
        language VARCHAR(2) NOT NULL CHECK (language IN ('KZ', 'RU')),
        file_url VARCHAR(500) NOT NULL,
        file_name VARCHAR(255) NOT NULL,
        file_size BIGINT,
        uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        uploaded_by INTEGER REFERENCES admins(id)
      )
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS packages (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        name_kz VARCHAR(255),
        name_ru VARCHAR(255),
        icon_color VARCHAR(7) DEFAULT '#4CAF50',
        price INTEGER NOT NULL DEFAULT 1000,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS package_files (
        id SERIAL PRIMARY KEY,
        package_id INTEGER REFERENCES packages(id) ON DELETE CASCADE,
        language VARCHAR(2) NOT NULL CHECK (language IN ('KZ', 'RU')),
        file_url VARCHAR(500),
        file_name VARCHAR(255),
        file_size BIGINT,
        uploaded_at TIMESTAMP,
        UNIQUE(package_id, language)
      )
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS phrases (
        id SERIAL PRIMARY KEY,
        language VARCHAR(2) NOT NULL CHECK (language IN ('KZ', 'RU')),
        file_url VARCHAR(500) NOT NULL,
        file_name VARCHAR(255) NOT NULL,
        file_size BIGINT,
        uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        uploaded_by INTEGER REFERENCES admins(id)
      )
    `);

    console.log('✅ Таблицы базы данных созданы/проверены');
  } catch (error) {
    console.error('❌ Ошибка инициализации базы данных:', error);
    throw error;
  }
};

export const query = async (text, params) => {
  const pool = getPool();
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    if (process.env.NODE_ENV === 'development') {
      console.log('Executed query', { text, duration, rows: res.rowCount });
    }
    return res;
  } catch (error) {
    console.error('Database query error:', error);
    throw error;
  }
};

