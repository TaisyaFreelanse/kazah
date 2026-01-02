import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useAuth } from '../context/AuthContext';
import './PublicQuestions.css';

const PublicQuestions = () => {
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();
  const [files, setFiles] = useState({ KZ: null, RU: null });
  const [loading, setLoading] = useState({ KZ: false, RU: false });
  const [deleting, setDeleting] = useState({ KZ: false, RU: false });
  const [error, setError] = useState({ KZ: null, RU: null });
  const [success, setSuccess] = useState({ KZ: null, RU: null });

  useEffect(() => {
    loadFiles();
  }, []);

  const loadFiles = async () => {
    try {
      const response = await axios.get('/api/public-questions');
      const filesData = { KZ: null, RU: null };
      
      response.data.forEach((file) => {
        if (file.language === 'KZ') {
          filesData.KZ = file;
        } else if (file.language === 'RU') {
          filesData.RU = file;
        }
      });
      
      setFiles(filesData);
    } catch (err) {
      console.error('Ошибка загрузки файлов:', err);
    }
  };

  const handleFileUpload = async (language, file) => {
    if (!file) return;

    const validTypes = [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-excel',
    ];
    
    if (!validTypes.includes(file.type)) {
      setError({ ...error, [language]: 'Разрешены только Excel файлы (.xlsx, .xls)' });
      return;
    }

    if (file.size > 10 * 1024 * 1024) {
      setError({ ...error, [language]: 'Размер файла не должен превышать 10MB' });
      return;
    }

    setLoading({ ...loading, [language]: true });
    setError({ ...error, [language]: null });
    setSuccess({ ...success, [language]: null });

    const formData = new FormData();
    formData.append('file', file);
    formData.append('language', language);

    try {
      await axios.post('/api/public-questions/upload', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      setSuccess({ ...success, [language]: 'Файл успешно загружен!' });
      await loadFiles();
    } catch (err) {
      setError({
        ...error,
        [language]: err.response?.data?.error || 'Ошибка загрузки файла',
      });
    } finally {
      setLoading({ ...loading, [language]: false });
    }
  };

  const handleDelete = async (language, fileId) => {
    if (!window.confirm(`Вы уверены, что хотите удалить файл для языка ${language}?`)) {
      return;
    }

    setDeleting({ ...deleting, [language]: true });
    setError({ ...error, [language]: null });
    setSuccess({ ...success, [language]: null });

    try {
      await axios.delete(`/api/public-questions/${fileId}`);
      setSuccess({ ...success, [language]: 'Файл успешно удален!' });
      await loadFiles();
    } catch (err) {
      setError({
        ...error,
        [language]: err.response?.data?.error || 'Ошибка удаления файла',
      });
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
    return date.toLocaleString('ru-RU', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const FileBlock = ({ language, label }) => {
    const file = files[language];
    const fileInputRef = React.useRef(null);

    return (
      <div className="file-block">
        <div className="file-block-header">
          <h3>{label}</h3>
          <span className="language-badge">{language}</span>
        </div>

        {file ? (
          <div className="file-info">
            <div className="file-details">
              <div className="file-icon">📄</div>
              <div className="file-meta">
                <div className="file-name">{file.file_name || file.fileName}</div>
                <div className="file-stats">
                  <span>Размер: {formatFileSize(file.file_size || file.fileSize)}</span>
                  <span className="separator">•</span>
                  <span>Загружен: {formatDate(file.uploaded_at || file.uploadedAt)}</span>
                </div>
              </div>
            </div>
            <button
              className="delete-button"
              onClick={() => handleDelete(language, file.id)}
              disabled={deleting[language]}
            >
              {deleting[language] ? 'Удаление...' : 'Удалить файл'}
            </button>
          </div>
        ) : (
          <div className="no-file">
            <p>Файл не загружен</p>
          </div>
        )}

        <div className="file-actions">
          <input
            ref={fileInputRef}
            type="file"
            accept=".xlsx,.xls"
            style={{ display: 'none' }}
            onChange={(e) => {
              const selectedFile = e.target.files[0];
              if (selectedFile) {
                handleFileUpload(language, selectedFile);
              }
              e.target.value = ''; // Сброс для возможности повторной загрузки того же файла
            }}
          />
          <button
            className="upload-button"
            onClick={() => fileInputRef.current?.click()}
            disabled={loading[language]}
          >
            {loading[language] ? 'Загрузка...' : 'Загрузить Excel'}
          </button>
        </div>

        {error[language] && (
          <div className="error-message">{error[language]}</div>
        )}

        {success[language] && (
          <div className="success-message">{success[language]}</div>
        )}
      </div>
    );
  };

  return (
    <div className="page-container">
      <header className="page-header">
        <button onClick={() => navigate('/')} className="back-button">
          ← Назад
        </button>
        <h1>Общедоступные вопросы</h1>
      </header>
      <main className="page-content">
        <div className="description">
          <p>
            Управление основным пулом вопросов, доступным всем пользователям без покупки.
            Загруженные файлы автоматически применяются в игре без обновления приложения.
          </p>
        </div>

        <div className="file-blocks-container">
          <FileBlock language="KZ" label="Excel на казахском языке" />
          <FileBlock language="RU" label="Excel на русском языке" />
        </div>

        <div className="info-box">
          <h4>ℹ️ Важная информация:</h4>
          <ul>
            <li>Новый файл полностью заменяет предыдущий</li>
            <li>Данные автоматически применяются в игре</li>
            <li>Обновление приложения не требуется</li>
            <li>Загруженный файл нельзя скачать</li>
            <li>Максимальный размер файла: 10MB</li>
            <li>Поддерживаемые форматы: .xlsx, .xls</li>
          </ul>
        </div>
      </main>
    </div>
  );
};

export default PublicQuestions;
