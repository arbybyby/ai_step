/**
 * Утилита для работы с аутентификацией в AdminPanel
 * Использует API контроллер для управления токенами
 */
const AuthService = {
  /**
   * Вход пользователя
   * @param {string} email - Email пользователя
   * @param {string} password - Пароль пользователя
   * @returns {Promise<Object>} Ответ сервера с токенами
   */
  login: async function(email, password) {
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email, password }),
        credentials: 'include' // Отправляем cookies
      });
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.message || 'Login failed');
      }
      return data;
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  },
  /**
   * Обновление токенов
   * @param {string} refreshToken - Refresh token
   * @returns {Promise<Object>} Новые токены
   */
  refreshToken: async function(refreshToken) {
    try {
      const response = await fetch('/api/auth/refresh', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ refreshToken }),
        credentials: 'include'
      });
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.message || 'Token refresh failed');
      }
      return data;
    } catch (error) {
      console.error('Token refresh error:', error);
      throw error;
    }
  },
  /**
   * Проверка статуса аутентификации
   * @returns {Promise<Object>} Статус аутентификации
   */
  checkAuth: async function() {
    try {
      const response = await fetch('/api/auth/check', {
        method: 'GET',
        credentials: 'include'
      });
      if (!response.ok) {
        return { authenticated: false };
      }
      return await response.json();
    } catch (error) {
      console.error('Auth check error:', error);
      return { authenticated: false };
    }
  },
  /**
   * Выход из системы
   * @param {string} refreshToken - Refresh token для инвалидации
   * @returns {Promise<void>}
   */
  logout: async function(refreshToken) {
    try {
      const response = await fetch('/api/auth/logout', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ refreshToken }),
        credentials: 'include'
      });
      if (!response.ok) {
        console.warn('Logout API warning:', response.statusText);
      }
      return await response.json();
    } catch (error) {
      console.error('Logout error:', error);
      // Все равно перенаправляем, даже если была ошибка
      window.location.href = '/Login';
    }
  },
  /**
   * Автоматическое обновление токена перед истечением срока
   * @param {number} accessTokenExpiration - Время истечения токена (мс)
   * @param {string} refreshToken - Refresh token
   * @param {number} buffer - Буфер времени перед истечением (мс, по умолчанию 60 сек)
   */
  scheduleTokenRefresh: function(accessTokenExpiration, refreshToken, buffer = 60000) {
    const now = Date.now();
    const expirationTime = new Date(accessTokenExpiration).getTime();
    const timeUntilExpiration = expirationTime - now - buffer;
    if (timeUntilExpiration > 0) {
      setTimeout(async () => {
        try {
          console.log('Auto-refreshing token...');
          const result = await this.refreshToken(refreshToken);
          if (result.success) {
            // Планируем новое обновление
            this.scheduleTokenRefresh(
              result.accessTokenExpiration,
              result.refreshToken,
              buffer
            );
          }
        } catch (error) {
          console.error('Auto-refresh failed:', error);
          // Перенаправляем на логин при ошибке обновления
          window.location.href = '/Login';
        }
      }, timeUntilExpiration);
    } else {
      // Токен уже истек
      window.location.href = '/Login';
    }
  }
};
/**
 * Вспомогательная функция для обработки ошибок API
 * @param {Response} response - Fetch response
 * @returns {Promise<Object>} Распарсенный JSON
 */
async function handleApiResponse(response) {
  const data = await response.json();
  if (!response.ok) {
    const error = new Error(data.message || response.statusText);
    error.status = response.status;
    error.data = data;
    throw error;
  }
  return data;
}
// Пример использования
/*
// Login
document.getElementById('loginForm')?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = document.getElementById('email').value;
  const password = document.getElementById('password').value;
  try {
    const result = await AuthService.login(email, password);
    console.log('Login successful:', result);
    // Планируем автоматическое обновление токена
    AuthService.scheduleTokenRefresh(
      result.accessTokenExpiration,
      result.refreshToken
    );
    // Перенаправляем на главную страницу
    window.location.href = '/';
  } catch (error) {
    console.error('Login failed:', error);
    alert('Login failed: ' + error.message);
  }
});
// Logout
document.getElementById('logoutBtn')?.addEventListener('click', async () => {
  const refreshToken = localStorage.getItem('refreshToken');
  try {
    await AuthService.logout(refreshToken);
    window.location.href = '/Login';
  } catch (error) {
    console.error('Logout error:', error);
  }
});
// Check auth on page load
document.addEventListener('DOMContentLoaded', async () => {
  const authStatus = await AuthService.checkAuth();
  if (!authStatus.authenticated) {
    console.log('User not authenticated');
  } else {
    console.log('User authenticated as:', authStatus.user.email);
  }
});
*/
