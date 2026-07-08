// Gerenciamento de token JWT e estado de autenticação do administrador

const AUTH_TOKEN_KEY = 'mc_admin_token';
const AUTH_USER_KEY = 'mc_admin_user';

/**
 * Decodifica o payload de um token JWT (sem validar a assinatura, apenas para leitura)
 * @param {string} token 
 * @returns {object|null}
 */
function decodeJwt(token) {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch (error) {
    console.error('Erro ao decodificar JWT:', error);
    return null;
  }
}

/**
 * Salva as credenciais obtidas no login
 * @param {string} token 
 * @param {object} user 
 */
function setSession(token, user) {
  localStorage.setItem(AUTH_TOKEN_KEY, token);
  localStorage.setItem(AUTH_USER_KEY, JSON.stringify(user));
}

/**
 * Retorna o token atual se estiver válido
 * @returns {string|null}
 */
function getToken() {
  const token = localStorage.getItem(AUTH_TOKEN_KEY);
  if (!token) return null;

  // Verificar expiração
  const payload = decodeJwt(token);
  if (!payload) {
    logout();
    return null;
  }

  const currentTime = Math.floor(Date.now() / 1000);
  if (payload.exp && payload.exp < currentTime) {
    console.warn('Token expirado');
    logout();
    return null;
  }

  // Verificar role
  if (payload.role !== 'admin') {
    console.warn('Acesso negado: não é administrador');
    logout();
    return null;
  }

  return token;
}

/**
 * Retorna o usuário armazenado na sessão
 * @returns {object|null}
 */
function getSessionUser() {
  const userStr = localStorage.getItem(AUTH_USER_KEY);
  try {
    return userStr ? JSON.parse(userStr) : null;
  } catch (e) {
    return null;
  }
}

/**
 * Remove a sessão e redireciona para a tela de login
 */
function logout() {
  localStorage.removeItem(AUTH_TOKEN_KEY);
  localStorage.removeItem(AUTH_USER_KEY);
  
  // Evitar loop se já estiver no login.html
  if (!window.location.pathname.endsWith('login.html')) {
    window.location.href = 'login.html';
  }
}

/**
 * Checa a autenticação. Deve ser chamada no início de cada página
 */
function checkAuth() {
  const isLoginPage = window.location.pathname.endsWith('login.html');
  const token = getToken();

  if (isLoginPage) {
    if (token) {
      // Se já está logado, vai para o dashboard
      window.location.href = 'index.html';
    }
  } else {
    if (!token) {
      // Se não está logado, vai para o login
      window.location.href = 'login.html';
    }
  }
}

// Executar checagem inicial
checkAuth();
