import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useAuth } from '../context/AuthContext';
import './Packages.css';

const Packages = () => {
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();
  const [packages, setPackages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState({});
  const [deleting, setDeleting] = useState({});
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [editingPackage, setEditingPackage] = useState(null);

  useEffect(() => {
    loadPackages();
  }, []);

  const loadPackages = async () => {
    try {
      setLoading(true);
      const response = await axios.get('/api/packages');
      setPackages(response.data);
      
      // Если пакетов нет, создаем пакеты по умолчанию
      if (response.data.length === 0) {
        await createDefaultPackages();
      }
    } catch (err) {
      console.error('Ошибка загрузки пакетов:', err);
      setError('Ошибка загрузки пакетов');
    } finally {
      setLoading(false);
    }
  };

  const createDefaultPackages = async () => {
    try {
      const defaultPackages = [
        { name: 'Больше вопросов', nameKZ: 'Көбірек сұрақтар', nameRU: 'Больше вопросов', iconColor: '#9C27B0', price: 1000 },
        { name: 'История Казахстана', nameKZ: 'Қазақстан тарихы', nameRU: 'История Казахстана', iconColor: '#795548', price: 1000 },
      ];

      for (const pkg of defaultPackages) {
        await axios.post('/api/packages', pkg);
      }

      // Перезагружаем список
      const response = await axios.get('/api/packages');
      setPackages(response.data);
      setSuccess('Пакеты по умолчанию созданы');
    } catch (err) {
      console.error('Ошибка создания пакетов по умолчанию:', err);
    }
  };

  const handleCreatePackage = async () => {
    try {
      const newPackage = await axios.post('/api/packages', {
        name: '',
        nameKZ: '',
        nameRU: '',
        iconColor: '#4CAF50',
        price: 1000,
        isActive: true,
      });

      setPackages([...packages, newPackage.data.package]);
      setSuccess('Новый пакет создан');
      setEditingPackage(newPackage.data.package.id);
    } catch (err) {
      setError(err.response?.data?.error || 'Ошибка создания пакета');
    }
  };

  const handleUpdatePackage = async (packageId, updates) => {
    setSaving({ ...saving, [packageId]: true });
    setError(null);
    setSuccess(null);

    try {
      const response = await axios.put(`/api/packages/${packageId}`, updates);
      
      setPackages(packages.map(pkg => 
        pkg.id === packageId ? response.data.package : pkg
      ));
      
      setSuccess('Пакет обновлен');
      setEditingPackage(null);
    } catch (err) {
      setError(err.response?.data?.error || 'Ошибка обновления пакета');
    } finally {
      setSaving({ ...saving, [packageId]: false });
    }
  };

  const handleDeletePackage = async (packageId) => {
    const packageToDelete = packages.find(pkg => pkg.id === packageId);
    const packageName = packageToDelete?.name || packageToDelete?.name_kz || packageToDelete?.nameKZ || 'этот пакет';
    
    const confirmMessage = `Вы уверены, что хотите удалить пакет "${packageName}"?\n\n` +
      `⚠️ ВНИМАНИЕ: Это действие нельзя отменить!\n` +
      `- Пакет полностью исчезнет из админ-панели\n` +
      `- Все файлы пакета будут удалены\n` +
      `- Пакет не будет использоваться в игре\n` +
      `- Пользователи, которые купили пакет, потеряют доступ к вопросам\n\n` +
      `Если вы хотите временно скрыть пакет, используйте тумблер "Активен/Неактивен" вместо удаления.`;
    
    if (!window.confirm(confirmMessage)) {
      return;
    }

    setDeleting({ ...deleting, [packageId]: true });
    setError(null);
    setSuccess(null);

    try {
      await axios.delete(`/api/packages/${packageId}`);
      setPackages(packages.filter(pkg => pkg.id !== packageId));
      setSuccess(`Пакет "${packageName}" успешно удален`);
    } catch (err) {
      setError(err.response?.data?.error || 'Ошибка удаления пакета');
    } finally {
      setDeleting({ ...deleting, [packageId]: false });
    }
  };

  const PackageCard = ({ pkg }) => {
    const [name, setName] = useState(pkg.name || '');
    const [nameKZ, setNameKZ] = useState(pkg.name_kz || pkg.nameKZ || '');
    const [nameRU, setNameRU] = useState(pkg.name_ru || pkg.nameRU || '');
    const [iconColor, setIconColor] = useState(pkg.icon_color || pkg.iconColor || '#4CAF50');
    const [price, setPrice] = useState(pkg.price || 1000);
    const [isActive, setIsActive] = useState(pkg.is_active !== undefined ? pkg.is_active : pkg.isActive !== undefined ? pkg.isActive : true);
    const [showColorPicker, setShowColorPicker] = useState(false);
    const isEditing = editingPackage === pkg.id;

    const handleSave = () => {
      handleUpdatePackage(pkg.id, {
        name,
        nameKZ,
        nameRU,
        iconColor,
        price: parseInt(price) || 1000,
        isActive,
      });
    };

    const handleToggleActive = () => {
      const newActive = !isActive;
      setIsActive(newActive);
      handleUpdatePackage(pkg.id, {
        name,
        nameKZ,
        nameRU,
        iconColor,
        price: parseInt(price) || 1000,
        isActive: newActive,
      });
    };

    return (
      <div className={`package-card ${!isActive ? 'inactive' : ''}`}>
        <div className="package-header">
          <div className="package-icon" style={{ backgroundColor: iconColor }}>
            📦
          </div>
          <div className="package-title">
            {isEditing ? (
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Название пакета"
                className="package-name-input"
              />
            ) : (
              <h3>{name || 'Без названия'}</h3>
            )}
            <div className="package-status">
              <span className={`status-badge ${isActive ? 'active' : 'inactive'}`}>
                {isActive ? 'Активен' : 'Неактивен'}
              </span>
            </div>
          </div>
        </div>

        {isEditing && (
          <div className="package-details">
            <div className="detail-row">
              <label>Название (KZ):</label>
              <input
                type="text"
                value={nameKZ}
                onChange={(e) => setNameKZ(e.target.value)}
                placeholder="Название на казахском"
                className="detail-input"
              />
            </div>
            <div className="detail-row">
              <label>Название (RU):</label>
              <input
                type="text"
                value={nameRU}
                onChange={(e) => setNameRU(e.target.value)}
                placeholder="Название на русском"
                className="detail-input"
              />
            </div>
            <div className="detail-row">
              <label>Цвет значка:</label>
              <div className="color-picker-container">
                <div
                  className="color-preview"
                  style={{ backgroundColor: iconColor }}
                  onClick={() => setShowColorPicker(!showColorPicker)}
                />
                <input
                  type="color"
                  value={iconColor}
                  onChange={(e) => setIconColor(e.target.value)}
                  className="color-input"
                />
                <input
                  type="text"
                  value={iconColor}
                  onChange={(e) => setIconColor(e.target.value)}
                  className="color-text-input"
                  placeholder="#4CAF50"
                />
              </div>
            </div>
            <div className="detail-row">
              <label>Цена (₸):</label>
              <input
                type="number"
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                min="0"
                className="detail-input price-input"
              />
            </div>
          </div>
        )}

        <div className="package-actions">
          <div className="toggle-container">
            <label className="toggle-label">
              <input
                type="checkbox"
                checked={isActive}
                onChange={handleToggleActive}
                className="toggle-input"
              />
              <span className="toggle-slider"></span>
              <span className="toggle-text">{isActive ? 'Активен' : 'Неактивен'}</span>
            </label>
          </div>

          <div className="action-buttons">
            {isEditing ? (
              <>
                <button
                  className="save-button"
                  onClick={handleSave}
                  disabled={saving[pkg.id]}
                >
                  {saving[pkg.id] ? 'Сохранение...' : 'Сохранить'}
                </button>
                <button
                  className="cancel-button"
                  onClick={() => {
                    setEditingPackage(null);
                    setName(pkg.name || '');
                    setNameKZ(pkg.name_kz || pkg.nameKZ || '');
                    setNameRU(pkg.name_ru || pkg.nameRU || '');
                    setIconColor(pkg.icon_color || pkg.iconColor || '#4CAF50');
                    setPrice(pkg.price || 1000);
                    setIsActive(pkg.is_active !== undefined ? pkg.is_active : pkg.isActive !== undefined ? pkg.isActive : true);
                  }}
                >
                  Отмена
                </button>
              </>
            ) : (
              <>
                <button
                  className="edit-button"
                  onClick={() => setEditingPackage(pkg.id)}
                >
                  Редактировать
                </button>
                <button
                  className="view-button"
                  onClick={() => navigate(`/packages/${pkg.id}`)}
                >
                  Файлы
                </button>
              </>
            )}
            <button
              className="delete-button"
              onClick={() => handleDeletePackage(pkg.id)}
              disabled={deleting[pkg.id]}
            >
              {deleting[pkg.id] ? 'Удаление...' : 'Удалить'}
            </button>
          </div>
        </div>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="page-container">
        <header className="page-header">
          <button onClick={() => navigate('/')} className="back-button">
            ← Назад
          </button>
          <h1>Пакетные вопросы</h1>
        </header>
        <main className="page-content">
          <div className="loading">Загрузка...</div>
        </main>
      </div>
    );
  }

  return (
    <div className="page-container">
      <header className="page-header">
        <button onClick={() => navigate('/')} className="back-button">
          ← Назад
        </button>
        <h1>Пакетные вопросы</h1>
        <button className="create-button" onClick={handleCreatePackage} title="Создать новый пакет">
          +
        </button>
      </header>
      <main className="page-content">
        <div className="description">
          <p>
            Управление платными пакетами вопросов. Пакеты отображаются в приложении
            и доступны пользователям для покупки, если они активны.
          </p>
        </div>

        {error && (
          <div className="error-message">{error}</div>
        )}

        {success && (
          <div className="success-message">{success}</div>
        )}

        <div className="packages-grid">
          {packages.map((pkg) => (
            <PackageCard key={pkg.id} pkg={pkg} />
          ))}
        </div>

        {packages.length === 0 && (
          <div className="empty-state">
            <p>Пакеты не найдены. Нажмите "Создать пакет" для добавления нового пакета.</p>
          </div>
        )}

        <div className="info-box">
          <h4>ℹ️ Информация:</h4>
          <ul>
            <li><strong>Активен:</strong> Пакет отображается в приложении и доступен для покупки</li>
            <li><strong>Неактивен:</strong> Пакет скрыт из магазина, но пользователи, купившие его ранее, сохраняют доступ</li>
            <li>Цвет значка отображается рядом с названием пакета и вопросами из этого пакета</li>
            <li>Для загрузки файлов с вопросами перейдите в раздел "Файлы" каждого пакета</li>
          </ul>
        </div>
      </main>
    </div>
  );
};

export default Packages;
