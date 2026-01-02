import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useAuth } from '../context/AuthContext';
import './PackageDetail.css';

const PackageDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();
  const [packageData, setPackageData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState({ KZ: false, RU: false });
  const [deleting, setDeleting] = useState({ KZ: false, RU: false });
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  useEffect(() => {
    loadPackage();
  }, [id]);

  const loadPackage = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`/api/packages/${id}`);
      setPackageData(response.data);
    } catch (err) {
      console.error('Ошибка загрузки пакета:', err);
      setError('Ошибка загрузки пакета');
    } finally {
      setLoading(false);
    }
  };

  const handleFileUpload = async (language, file) => {
    if (!file) return;

    const validExtensions = ['.xlsx', '.xls'];
    const fileExtension = file.name.toLowerCase().substring(file.name.lastIndexOf('.'));
    if (!validExtensions.includes(fileExtension)) {
      setError('Разрешены только Excel файлы (.xlsx, .xls)');
      return;
    }

    const formData = new FormData();
    formData.append('file', file);
    formData.append('language', language);

    setUploading({ ...uploading, [language]: true });
    setError(null);
    setSuccess(null);

    try {
      const response = await axios.post(`/api/packages/${id}/upload`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      setPackageData(response.data.package);
      setSuccess(`Файл на ${language === 'KZ' ? 'казахском' : 'русском'} языке успешно загружен`);
    } catch (err) {
      setError(err.response?.data?.error || 'Ошибка загрузки файла');
    } finally {
      setUploading({ ...uploading, [language]: false });
    }
  };

  const handleFileDelete = async (language) => {
    if (!window.confirm(`Вы уверены, что хотите удалить файл на ${language === 'KZ' ? 'казахском' : 'русском'} языке?`)) {
      return;
    }

    setDeleting({ ...deleting, [language]: true });
    setError(null);
    setSuccess(null);

    try {
      await axios.delete(`/api/packages/${id}/file/${language}`);
      await loadPackage(); // Перезагружаем данные пакета
      setSuccess(`Файл на ${language === 'KZ' ? 'казахском' : 'русском'} языке удален`);
    } catch (err) {
      setError(err.response?.data?.error || 'Ошибка удаления файла');
    } finally {
      setDeleting({ ...deleting, [language]: false });
    }
  };

  const formatFileSize = (bytes) => {
    if (!bytes) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  };

  const formatDate = (dateString) => {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleDateString('ru-RU', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (loading) {
    return (
      <div className="page-container">
        <header className="page-header">
          <button onClick={() => navigate('/packages')} className="back-button">
            ← Назад
          </button>
          <h1>Загрузка файлов пакета</h1>
        </header>
        <main className="page-content">
          <div className="loading">Загрузка...</div>
        </main>
      </div>
    );
  }

  if (!packageData) {
    return (
      <div className="page-container">
        <header className="page-header">
          <button onClick={() => navigate('/packages')} className="back-button">
            ← Назад
          </button>
          <h1>Пакет не найден</h1>
        </header>
        <main className="page-content">
          <div className="error-message">Пакет не найден</div>
        </main>
      </div>
    );
  }

  const fileKZ = packageData.files?.kz;
  const fileRU = packageData.files?.ru;

  return (
    <div className="page-container">
      <header className="page-header">
        <button onClick={() => navigate('/packages')} className="back-button">
          ← Назад
        </button>
        <h1>Файлы пакета: {packageData.name || packageData.name_kz || packageData.nameKZ || 'Без названия'}</h1>
      </header>
      <main className="page-content">
        <div className="description">
          <p>
            Загрузите Excel файлы с вопросами для этого пакета. Каждый файл должен содержать вопросы
            на соответствующем языке (казахском или русском).
          </p>
        </div>

        {error && (
          <div className="error-message">{error}</div>
        )}

        {success && (
          <div className="success-message">{success}</div>
        )}

        <div className="file-upload-blocks">
          {/* Блок загрузки для казахского языка */}
          <div className="file-upload-block">
            <div className="file-upload-header">
              <h3>📄 Excel на казахском языке</h3>
            </div>
            <div className="file-upload-content">
              {fileKZ?.file_url ? (
                <div className="file-info">
                  <div className="file-info-item">
                    <strong>Файл:</strong> {fileKZ.file_name || 'Неизвестно'}
                  </div>
                  <div className="file-info-item">
                    <strong>Размер:</strong> {formatFileSize(fileKZ.file_size)}
                  </div>
                  <div className="file-info-item">
                    <strong>Загружен:</strong> {formatDate(fileKZ.uploaded_at)}
                  </div>
                  <div className="file-status">
                    <span className="file-status-badge file-status-uploaded">✓ Загружен</span>
                  </div>
                </div>
              ) : (
                <div className="file-status">
                  <span className="file-status-badge file-status-empty">Файл не загружен</span>
                </div>
              )}

              <div className="file-actions">
                <label className="upload-button">
                  <input
                    type="file"
                    accept=".xlsx,.xls"
                    onChange={(e) => handleFileUpload('KZ', e.target.files[0])}
                    disabled={uploading.KZ}
                    style={{ display: 'none' }}
                  />
                  {uploading.KZ ? 'Загрузка...' : 'Загрузить Excel'}
                </label>
                {fileKZ?.file_url && (
                  <button
                    className="delete-button"
                    onClick={() => handleFileDelete('KZ')}
                    disabled={deleting.KZ}
                  >
                    {deleting.KZ ? 'Удаление...' : 'Удалить файл'}
                  </button>
                )}
              </div>
            </div>
          </div>

          {/* Блок загрузки для русского языка */}
          <div className="file-upload-block">
            <div className="file-upload-header">
              <h3>📄 Excel на русском языке</h3>
            </div>
            <div className="file-upload-content">
              {fileRU?.file_url ? (
                <div className="file-info">
                  <div className="file-info-item">
                    <strong>Файл:</strong> {fileRU.file_name || 'Неизвестно'}
                  </div>
                  <div className="file-info-item">
                    <strong>Размер:</strong> {formatFileSize(fileRU.file_size)}
                  </div>
                  <div className="file-info-item">
                    <strong>Загружен:</strong> {formatDate(fileRU.uploaded_at)}
                  </div>
                  <div className="file-status">
                    <span className="file-status-badge file-status-uploaded">✓ Загружен</span>
                  </div>
                </div>
              ) : (
                <div className="file-status">
                  <span className="file-status-badge file-status-empty">Файл не загружен</span>
                </div>
              )}

              <div className="file-actions">
                <label className="upload-button">
                  <input
                    type="file"
                    accept=".xlsx,.xls"
                    onChange={(e) => handleFileUpload('RU', e.target.files[0])}
                    disabled={uploading.RU}
                    style={{ display: 'none' }}
                  />
                  {uploading.RU ? 'Загрузка...' : 'Загрузить Excel'}
                </label>
                {fileRU?.file_url && (
                  <button
                    className="delete-button"
                    onClick={() => handleFileDelete('RU')}
                    disabled={deleting.RU}
                  >
                    {deleting.RU ? 'Удаление...' : 'Удалить файл'}
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>

        <div className="info-box">
          <h4>ℹ️ Информация:</h4>
          <ul>
            <li>Загружайте только Excel файлы (.xlsx, .xls)</li>
            <li>При загрузке нового файла старый автоматически заменяется</li>
            <li>Файлы нельзя скачать, они используются только в приложении</li>
            <li>После загрузки файла вопросы из пакета автоматически доступны в игре</li>
          </ul>
        </div>
      </main>
    </div>
  );
};

export default PackageDetail;

