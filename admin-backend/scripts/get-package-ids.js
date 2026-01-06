import dotenv from 'dotenv';
import { query, initDatabase } from '../db/database.js';

dotenv.config();

async function getPackageIds() {
  try {
    await initDatabase();
    
    const result = await query('SELECT id, name, name_kz, name_ru, is_active FROM packages ORDER BY id');
    
    if (result.rows.length === 0) {
      console.log('📦 Пакеты не найдены в базе данных');
      process.exit(0);
    }
    
    console.log('\n📦 Список всех пакетов:\n');
    console.log('ID | Название (RU) | Название (KZ) | Активен');
    console.log('---|----------------|---------------|---------');
    
    result.rows.forEach(pkg => {
      const nameRu = (pkg.name_ru || pkg.name || '-').substring(0, 14);
      const nameKz = (pkg.name_kz || pkg.name || '-').substring(0, 13);
      const isActive = pkg.is_active ? '✓' : '✗';
      console.log(`${pkg.id.toString().padEnd(2)} | ${nameRu.padEnd(14)} | ${nameKz.padEnd(13)} | ${isActive}`);
    });
    
    console.log('\n📋 Только ID пакетов (через запятую):');
    const ids = result.rows.map(pkg => pkg.id).join(', ');
    console.log(ids);
    
    console.log('\n📋 ID активных пакетов (через запятую):');
    const activeIds = result.rows.filter(pkg => pkg.is_active).map(pkg => pkg.id);
    if (activeIds.length > 0) {
      console.log(activeIds.join(', '));
    } else {
      console.log('Нет активных пакетов');
    }
    
    console.log('\n📋 ID пакетов (массив JSON):');
    console.log(JSON.stringify(result.rows.map(pkg => pkg.id), null, 2));
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Ошибка получения пакетов:', error);
    process.exit(1);
  }
}

getPackageIds();

