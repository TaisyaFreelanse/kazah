import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import './Dashboard.css';

const Dashboard = () => {
  const navigate = useNavigate();
  const { user, logout } = useAuth();

  const handleLogout = () => {
    logout();
  };

  const sections = [
    {
      id: 'public-questions',
      title: 'Общедоступные',
      description: 'Управление основным пулом вопросов',
      icon: '📚',
      color: '#4CAF50',
    },
    {
      id: 'packages',
      title: 'Пакетные',
      description: 'Управление платными пакетами',
      icon: '📦',
      color: '#2196F3',
    },
    {
      id: 'phrases',
      title: 'ФинФразы',
      description: 'Управление финальными мотивирующими фразами',
      icon: '💬',
      color: '#FF9800',
    },
  ];

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <div className="header-content">
          <h1 className="dashboard-title">Blim Bilem - Админ Панель</h1>
          <div className="header-actions">
            <span className="user-name">Администратор: {user?.username}</span>
            <button onClick={handleLogout} className="logout-button">
              Выйти
            </button>
          </div>
        </div>
      </header>

      <main className="dashboard-main">
        <div className="sections-grid">
          {sections.map((section) => (
            <div
              key={section.id}
              className="section-card"
              onClick={() => navigate(`/${section.id}`)}
              style={{ '--card-color': section.color }}
            >
              <div className="section-icon">{section.icon}</div>
              <h2 className="section-title">{section.title}</h2>
              <p className="section-description">{section.description}</p>
              <div className="section-arrow">→</div>
            </div>
          ))}
        </div>
      </main>
    </div>
  );
};

export default Dashboard;

