import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import './ChangePassword.css';

const ChangePassword = () => {
  const navigate = useNavigate();
  const { changePassword } = useAuth();
  const [formData, setFormData] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  });
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
    setError(null);
    setSuccess(null);
  };

  const validateForm = () => {
    if (!formData.currentPassword || !formData.newPassword || !formData.confirmPassword) {
      setError('Все поля обязательны для заполнения');
      return false;
    }

    if (formData.newPassword.length < 6) {
      setError('Новый пароль должен содержать минимум 6 символов');
      return false;
    }

    if (formData.newPassword !== formData.confirmPassword) {
      setError('Новые пароли не совпадают');
      return false;
    }

    if (formData.currentPassword === formData.newPassword) {
      setError('Новый пароль должен отличаться от текущего');
      return false;
    }

    return true;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);

    if (!validateForm()) {
      return;
    }

    setLoading(true);

    try {
      const result = await changePassword(formData.currentPassword, formData.newPassword);
      
      if (result.success) {
        setSuccess('Пароль успешно изменен');
        setFormData({
          currentPassword: '',
          newPassword: '',
          confirmPassword: '',
        });
        // Перенаправляем на главную страницу через 2 секунды
        setTimeout(() => {
          navigate('/');
        }, 2000);
      } else {
        setError(result.error || 'Ошибка смены пароля');
      }
    } catch (err) {
      setError('Произошла ошибка при смене пароля');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="page-container">
      <header className="page-header">
        <button onClick={() => navigate('/')} className="back-button">
          ← Назад
        </button>
        <h1>Смена пароля</h1>
      </header>
      <main className="page-content">
        <div className="change-password-card">
          <div className="card-header">
            <h2>Изменить пароль администратора</h2>
            <p>Введите текущий пароль и новый пароль для изменения</p>
          </div>

          {error && (
            <div className="error-message">{error}</div>
          )}

          {success && (
            <div className="success-message">{success}</div>
          )}

          <form onSubmit={handleSubmit} className="change-password-form">
            <div className="form-group">
              <label htmlFor="currentPassword">Текущий пароль</label>
              <input
                type="password"
                id="currentPassword"
                name="currentPassword"
                value={formData.currentPassword}
                onChange={handleChange}
                className="form-input"
                placeholder="Введите текущий пароль"
                required
                disabled={loading}
              />
            </div>

            <div className="form-group">
              <label htmlFor="newPassword">Новый пароль</label>
              <input
                type="password"
                id="newPassword"
                name="newPassword"
                value={formData.newPassword}
                onChange={handleChange}
                className="form-input"
                placeholder="Введите новый пароль (минимум 6 символов)"
                required
                minLength={6}
                disabled={loading}
              />
              <small className="form-hint">
                Минимум 6 символов
              </small>
            </div>

            <div className="form-group">
              <label htmlFor="confirmPassword">Подтвердите новый пароль</label>
              <input
                type="password"
                id="confirmPassword"
                name="confirmPassword"
                value={formData.confirmPassword}
                onChange={handleChange}
                className="form-input"
                placeholder="Повторите новый пароль"
                required
                minLength={6}
                disabled={loading}
              />
            </div>

            <div className="form-actions">
              <button
                type="button"
                onClick={() => navigate('/')}
                className="cancel-button"
                disabled={loading}
              >
                Отмена
              </button>
              <button
                type="submit"
                className="submit-button"
                disabled={loading}
              >
                {loading ? 'Изменение...' : 'Изменить пароль'}
              </button>
            </div>
          </form>

          <div className="security-info">
            <h4>🔒 Рекомендации по безопасности:</h4>
            <ul>
              <li>Используйте пароль длиной не менее 8 символов</li>
              <li>Включайте буквы, цифры и специальные символы</li>
              <li>Не используйте простые пароли (123456, password и т.д.)</li>
              <li>Регулярно меняйте пароль</li>
              <li>Не сообщайте пароль третьим лицам</li>
            </ul>
          </div>
        </div>
      </main>
    </div>
  );
};

export default ChangePassword;

