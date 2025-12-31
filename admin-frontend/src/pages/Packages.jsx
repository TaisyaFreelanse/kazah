import React from 'react';
import { useNavigate } from 'react-router-dom';
import './Packages.css';

const Packages = () => {
  const navigate = useNavigate();

  return (
    <div className="page-container">
      <header className="page-header">
        <button onClick={() => navigate('/')} className="back-button">
          ← Назад
        </button>
        <h1>Пакетные вопросы</h1>
      </header>
      <main className="page-content">
        <p>Раздел в разработке...</p>
      </main>
    </div>
  );
};

export default Packages;

