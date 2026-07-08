// Lógica do Painel Administrativo - Meu Correspondente

// Estado Global
let activeTab = 'banks'; // 'banks' | 'rates'
let allBanks = []; // Armazena a lista de bancos na memória
let allRates = []; // Armazena a lista de taxas na memória
let deleteCallback = null; // Armazena o callback para a exclusão ativa

// Elementos da DOM
const btnTabBanks = document.getElementById('btnTabBanks');
const btnTabRates = document.getElementById('btnTabRates');
const tabBanksSection = document.getElementById('tabBanks');
const tabRatesSection = document.getElementById('tabRates');

const pageTitle = document.getElementById('pageTitle');
const pageSubtitle = document.getElementById('pageSubtitle');
const headerStatsLabel = document.getElementById('headerStatsLabel');
const headerStatsValue = document.getElementById('headerStatsValue');

// Perfil Admin
const adminNameEl = document.getElementById('adminName');
const adminAvatarEl = document.getElementById('adminAvatar');

// Loader & Empty States
const banksLoader = document.getElementById('banksLoader');
const banksEmptyState = document.getElementById('banksEmptyState');
const banksTableBody = document.getElementById('banksTableBody');

const ratesLoader = document.getElementById('ratesLoader');
const ratesEmptyState = document.getElementById('ratesEmptyState');
const ratesTableBody = document.getElementById('ratesTableBody');

// Modais
const bankModal = document.getElementById('bankModal');
const rateModal = document.getElementById('rateModal');
const deleteModal = document.getElementById('deleteModal');

// Form de Bancos
const bankForm = document.getElementById('bankForm');
const bankIdInput = document.getElementById('bankId');
const bankNameInput = document.getElementById('bankName');
const bankLogoUrlInput = document.getElementById('bankLogoUrl');
const btnSaveBankSpinner = document.getElementById('btnSaveBankSpinner');
const btnSaveBankText = document.getElementById('btnSaveBankText');

// Form de Taxas
const rateForm = document.getElementById('rateForm');
const rateIdInput = document.getElementById('rateId');
const rateInstitutionSelect = document.getElementById('rateInstitution');
const rateTypeSelect = document.getElementById('rateType');
const rateValueInput = document.getElementById('rateValue');
const rateMaxLTVInput = document.getElementById('rateMaxLTV');
const rateMaxAgeInput = document.getElementById('rateMaxAge');
const rateMinTermInput = document.getElementById('rateMinTerm');
const rateMaxTermInput = document.getElementById('rateMaxTerm');
const btnSaveRateSpinner = document.getElementById('btnSaveRateSpinner');
const btnSaveRateText = document.getElementById('btnSaveRateText');

// Confirmação Exclusão
const btnConfirmDelete = document.getElementById('btnConfirmDelete');
const btnConfirmDeleteSpinner = document.getElementById('btnConfirmDeleteSpinner');
const btnConfirmDeleteText = document.getElementById('btnConfirmDeleteText');
const deleteModalTitle = document.getElementById('deleteModalTitle');
const deleteModalMessage = document.getElementById('deleteModalMessage');

// ================= AUTENTICAÇÃO E REQUISIÇÕES =================

/**
 * Invoca requisições HTTP incluindo o header Authorization com JWT
 * @param {string} url 
 * @param {object} options 
 */
async function fetchWithAuth(url, options = {}) {
  const token = getToken(); // de auth.js
  if (!token) {
    logout();
    return null;
  }

  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
    ...(options.headers || {})
  };

  try {
    const response = await fetch(url, { ...options, headers });
    
    if (response.status === 401 || response.status === 403) {
      console.warn('Sessão expirada ou não autorizada');
      showToast('Acesso negado ou sessão expirada. Faça login novamente.', 'error');
      setTimeout(() => logout(), 2000);
      return null;
    }

    return response;
  } catch (error) {
    console.error(`Falha na requisição para ${url}:`, error);
    showToast('Falha na comunicação com o servidor de backend.', 'error');
    throw error;
  }
}

// ================= INICIALIZAÇÃO E AVALIAÇÃO DE ABAS =================

document.addEventListener('DOMContentLoaded', () => {
  // Configurar Perfil
  const user = getSessionUser();
  if (user) {
    adminNameEl.textContent = user.name || user.email;
    adminAvatarEl.textContent = (user.name || user.email).charAt(0).toUpperCase();
  }

  // Bind das abas
  btnTabBanks.addEventListener('click', () => switchTab('banks'));
  btnTabRates.addEventListener('click', () => switchTab('rates'));

  // Bind de Modais (Abertura/Fechamento)
  document.getElementById('btnOpenAddBankModal').addEventListener('click', () => openBankModal());
  document.getElementById('btnCloseBankModal').addEventListener('click', () => closeBankModal());
  document.getElementById('btnCancelBank').addEventListener('click', () => closeBankModal());

  document.getElementById('btnOpenAddRateModal').addEventListener('click', () => openRateModal());
  document.getElementById('btnCloseRateModal').addEventListener('click', () => closeRateModal());
  document.getElementById('btnCancelRate').addEventListener('click', () => closeRateModal());

  document.getElementById('btnCancelDelete').addEventListener('click', () => closeDeleteModal());

  // Bind de Submits
  bankForm.addEventListener('submit', saveBank);
  rateForm.addEventListener('submit', saveRate);

  // Inicializa a primeira aba
  switchTab('banks');
});

/**
 * Altera a aba de navegação ativa
 * @param {string} tab 'banks' | 'rates'
 */
function switchTab(tab) {
  activeTab = tab;
  
  if (tab === 'banks') {
    // Atualizar navegação sidebar
    btnTabBanks.className = "w-full flex items-center space-x-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 bg-brandSecondary text-brandAccent shadow-sm";
    btnTabRates.className = "w-full flex items-center space-x-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 text-brandIceBlue/60 hover:bg-brandSecondary/40 hover:text-white";
    
    // Alternar visibilidade
    tabBanksSection.classList.remove('hidden');
    tabRatesSection.classList.add('hidden');

    // Header
    pageTitle.textContent = "Instituições Financeiras";
    pageSubtitle.textContent = "Gerencie as instituições ativas do sistema";
    headerStatsLabel.textContent = "Total de Bancos:";

    loadBanks();
  } else {
    // Atualizar navegação sidebar
    btnTabRates.className = "w-full flex items-center space-x-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 bg-brandSecondary text-brandAccent shadow-sm";
    btnTabBanks.className = "w-full flex items-center space-x-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 text-brandIceBlue/60 hover:bg-brandSecondary/40 hover:text-white";
    
    // Alternar visibilidade
    tabRatesSection.classList.remove('hidden');
    tabBanksSection.classList.add('hidden');

    // Header
    pageTitle.textContent = "Taxas de Simulação";
    pageSubtitle.textContent = "Configure as regras e taxas de juros por instituição";
    headerStatsLabel.textContent = "Total de Regras:";

    loadRates();
  }
}

// ================= TOAST NOTIFICATION SYSTEM =================

/**
 * Exibe um toast temporário na tela
 * @param {string} message 
 * @param {string} type 'success' | 'error' | 'info' | 'warning'
 */
function showToast(message, type = 'success') {
  const container = document.getElementById('toastContainer');
  const toast = document.createElement('div');
  
  toast.className = `p-4 rounded-xl shadow-xl flex items-center space-x-3 text-sm font-medium pointer-events-auto transition-all duration-300 transform translate-y-2 opacity-0 animate-slide-in`;
  
  let bgClass = 'bg-white border-l-4 border-slate-400 text-slate-800';
  let iconSvg = '';

  if (type === 'success') {
    bgClass = 'bg-white border-l-4 border-[#22C55E] text-slate-800';
    iconSvg = `<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-[#22C55E]" viewBox="0 0 20 20" fill="currentColor">
      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
    </svg>`;
  } else if (type === 'error') {
    bgClass = 'bg-white border-l-4 border-[#EF4444] text-slate-800';
    iconSvg = `<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-[#EF4444]" viewBox="0 0 20 20" fill="currentColor">
      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
    </svg>`;
  } else if (type === 'warning') {
    bgClass = 'bg-white border-l-4 border-[#F59E0B] text-slate-800';
    iconSvg = `<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-[#F59E0B]" viewBox="0 0 20 20" fill="currentColor">
      <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
    </svg>`;
  }

  toast.className += ` ${bgClass}`;
  toast.innerHTML = `${iconSvg} <span>${message}</span>`;
  
  container.appendChild(toast);
  
  // Fade out e remove
  setTimeout(() => {
    toast.classList.replace('opacity-0', 'opacity-100'); // Garante transição de entrada
  }, 10);

  setTimeout(() => {
    toast.className += ' transition-opacity duration-300 opacity-0 translate-y-1';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// ================= GERENCIAMENTO DE MODAIS =================

function openModal(modalEl) {
  modalEl.classList.remove('hidden');
  setTimeout(() => {
    modalEl.classList.add('modal-active');
  }, 10);
}

function closeModal(modalEl) {
  modalEl.classList.remove('modal-active');
  setTimeout(() => {
    modalEl.classList.add('hidden');
  }, 300);
}

// Modal de Confirmação de Deleção
function openDeleteModal(title, message, callback) {
  deleteModalTitle.textContent = title;
  deleteModalMessage.textContent = message;
  deleteCallback = callback;
  
  btnConfirmDelete.disabled = false;
  btnConfirmDeleteSpinner.classList.add('hidden');
  btnConfirmDeleteText.textContent = 'Excluir';

  openModal(deleteModal);
}

function closeDeleteModal() {
  closeModal(deleteModal);
  deleteCallback = null;
}

// Handler do botão do modal de deleção
btnConfirmDelete.addEventListener('click', async () => {
  if (deleteCallback) {
    btnConfirmDelete.disabled = true;
    btnConfirmDeleteSpinner.classList.remove('hidden');
    btnConfirmDeleteText.textContent = 'Removendo...';
    try {
      await deleteCallback();
    } catch (e) {
      console.error(e);
    } finally {
      closeDeleteModal();
    }
  }
});

// ================= CRUD: INSTITUIÇÕES FINANCEIRAS (BANCOS) =================

/**
 * Carrega os bancos do backend e renderiza
 */
async function loadBanks() {
  banksLoader.classList.remove('hidden');
  banksEmptyState.classList.add('hidden');
  
  // Limpar linhas dinâmicas anteriores
  const rows = banksTableBody.querySelectorAll('tr:not(#banksLoader):not(#banksEmptyState)');
  rows.forEach(r => r.remove());

  try {
    const res = await fetchWithAuth('/api/admin/institutions');
    if (!res) return;

    allBanks = await res.json();
    headerStatsValue.textContent = allBanks.length;
    banksLoader.classList.add('hidden');

    if (allBanks.length === 0) {
      banksEmptyState.classList.remove('hidden');
      return;
    }

    allBanks.forEach(bank => {
      const row = document.createElement('tr');
      row.className = "border-b border-brandIceBlue hover:bg-[#f0f4f8]/50 transition-colors text-slate-700";
      
      // Logo markup
      const logoContent = bank.logoUrl 
        ? `<img src="${escapeHtml(bank.logoUrl)}" alt="${escapeHtml(bank.name)}" class="w-9 h-9 object-contain bg-white rounded-lg p-1 border border-brandIceBlue shadow-inner flex items-center justify-center shrink-0">`
        : `<div class="w-9 h-9 bg-brandSecondary/25 border border-brandSecondary/20 rounded-lg text-brandSecondary font-bold flex items-center justify-center text-xs shrink-0 select-none">${escapeHtml(bank.name.substring(0, 2).toUpperCase())}</div>`;

      // Status switch checkbox
      const isChecked = bank.isActive ? 'checked' : '';

      row.innerHTML = `
        <td class="px-6 py-4 flex items-center">${logoContent}</td>
        <td class="px-6 py-4 font-semibold text-slate-200">${escapeHtml(bank.name)}</td>
        <td class="px-6 py-4 text-center">
          <label class="switch inline-block">
            <input type="checkbox" id="toggle-${bank.id}" ${isChecked}>
            <span class="slider"></span>
          </label>
        </td>
        <td class="px-6 py-4 text-right">
          <div class="flex items-center justify-end space-x-2.5">
            <button 
              id="edit-bank-${bank.id}"
              class="text-brandSecondary hover:text-brandSecondary/80 bg-brandSecondary/10 hover:bg-brandSecondary/20 border border-brandSecondary/20 hover:border-brandSecondary/30 p-2 rounded-xl transition-all duration-200"
              title="Editar Banco"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
              </svg>
            </button>
            <button 
              id="delete-bank-${bank.id}"
              class="text-[#EF4444] hover:text-red-700 bg-red-50 hover:bg-red-100 border border-red-200/60 p-2 rounded-xl transition-all duration-200"
              title="Excluir Banco"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </td>
      `;

      banksTableBody.appendChild(row);

      // Event listener for toggle switch
      row.querySelector(`#toggle-${bank.id}`).addEventListener('change', (e) => {
        toggleBankStatus(bank.id, e.target.checked);
      });

      // Event listener for Edit button
      row.querySelector(`#edit-bank-${bank.id}`).addEventListener('click', () => {
        openBankModal(bank);
      });

      // Event listener for Delete button
      row.querySelector(`#delete-bank-${bank.id}`).addEventListener('click', () => {
        openDeleteModal(
          'Excluir Instituição',
          `Tem certeza que deseja excluir o banco "${bank.name}"? Isso apagará também todas as taxas e regras vinculadas a ele.`,
          () => deleteBank(bank.id)
        );
      });
    });

  } catch (error) {
    banksLoader.classList.add('hidden');
    showToast('Erro ao carregar bancos.', 'error');
  }
}

/**
 * Ativa ou desativa um banco
 * @param {string} id 
 * @param {boolean} isActive 
 */
async function toggleBankStatus(id, isActive) {
  const bank = allBanks.find(b => b.id === id);
  if (!bank) return;

  try {
    const res = await fetchWithAuth(`/api/admin/institutions/${id}`, {
      method: 'PUT',
      body: JSON.stringify({
        name: bank.name,
        logoUrl: bank.logoUrl,
        isActive
      })
    });

    if (res && res.ok) {
      bank.isActive = isActive; // Atualizar estado na memória
      showToast(`Banco "${bank.name}" ${isActive ? 'ativado' : 'desativado'} com sucesso!`, 'success');
    } else {
      // Reverter checkbox no DOM se deu erro
      document.getElementById(`toggle-${id}`).checked = !isActive;
      showToast('Falha ao atualizar status do banco.', 'error');
    }
  } catch (error) {
    document.getElementById(`toggle-${id}`).checked = !isActive;
    showToast('Erro ao conectar ao servidor.', 'error');
  }
}

function openBankModal(bank = null) {
  // Limpar erros
  document.getElementById('bankNameError').classList.add('hidden');
  document.getElementById('bankLogoError').classList.add('hidden');

  btnSaveBankSpinner.classList.add('hidden');
  btnSaveBankText.textContent = 'Salvar Banco';
  bankForm.removeAttribute('disabled');

  if (bank) {
    document.getElementById('bankModalTitle').textContent = 'Editar Banco';
    bankIdInput.value = bank.id;
    bankNameInput.value = bank.name;
    bankLogoUrlInput.value = bank.logoUrl || '';
  } else {
    document.getElementById('bankModalTitle').textContent = 'Novo Banco';
    bankIdInput.value = '';
    bankForm.reset();
  }

  openModal(bankModal);
}

function closeBankModal() {
  closeModal(bankModal);
}

/**
 * Cria ou edita um banco no submit do formulário
 * @param {Event} e 
 */
async function saveBank(e) {
  e.preventDefault();

  const nameVal = bankNameInput.value.trim();
  const logoUrlVal = bankLogoUrlInput.value.trim();
  let hasError = false;

  // Validação
  if (!nameVal) {
    document.getElementById('bankNameError').classList.remove('hidden');
    hasError = true;
  }
  
  if (logoUrlVal) {
    try {
      new URL(logoUrlVal);
    } catch (_) {
      document.getElementById('bankLogoError').classList.remove('hidden');
      hasError = true;
    }
  }

  if (hasError) return;

  const bankId = bankIdInput.value;
  const isEditing = !!bankId;

  // Bloquear form e iniciar loader
  btnSaveBankSpinner.classList.remove('hidden');
  btnSaveBankText.textContent = isEditing ? 'Atualizando...' : 'Salvando...';

  const bodyData = {
    name: nameVal,
    logoUrl: logoUrlVal || null
  };

  try {
    let res;
    if (isEditing) {
      // Obter valor ativo atual na memória
      const currentBank = allBanks.find(b => b.id === bankId);
      bodyData.isActive = currentBank ? currentBank.isActive : true;

      res = await fetchWithAuth(`/api/admin/institutions/${bankId}`, {
        method: 'PUT',
        body: JSON.stringify(bodyData)
      });
    } else {
      res = await fetchWithAuth('/api/admin/institutions', {
        method: 'POST',
        body: JSON.stringify(bodyData)
      });
    }

    if (res && res.ok) {
      showToast(`Banco "${nameVal}" salvo com sucesso!`, 'success');
      closeBankModal();
      loadBanks();
    } else {
      const err = res ? await res.json() : { error: 'Sem resposta' };
      showToast(err.error || 'Erro ao processar requisição.', 'error');
    }
  } catch (error) {
    showToast('Falha na conexão de rede.', 'error');
  } finally {
    btnSaveBankSpinner.classList.add('hidden');
    btnSaveBankText.textContent = 'Salvar Banco';
  }
}

/**
 * Remove um banco via API
 * @param {string} id 
 */
async function deleteBank(id) {
  try {
    const res = await fetchWithAuth(`/api/admin/institutions/${id}`, {
      method: 'DELETE'
    });

    if (res && res.ok) {
      showToast('Banco excluído com sucesso!', 'success');
      loadBanks();
    } else {
      const err = res ? await res.json() : {};
      showToast(err.error || 'Erro ao deletar banco.', 'error');
    }
  } catch (error) {
    showToast('Erro de rede ao tentar deletar.', 'error');
  }
}

// ================= CRUD: REGRAS E TAXAS DE JUROS =================

/**
 * Carrega a lista de taxas do backend
 */
async function loadRates() {
  ratesLoader.classList.remove('hidden');
  ratesEmptyState.classList.add('hidden');
  
  // Limpar linhas dinâmicas anteriores
  const rows = ratesTableBody.querySelectorAll('tr:not(#ratesLoader):not(#ratesEmptyState)');
  rows.forEach(r => r.remove());

  try {
    const res = await fetchWithAuth('/api/admin/interest-rates');
    if (!res) return;

    allRates = await res.json();
    headerStatsValue.textContent = allRates.length;
    ratesLoader.classList.add('hidden');

    if (allRates.length === 0) {
      ratesEmptyState.classList.remove('hidden');
      return;
    }

    allRates.forEach(rate => {
      const row = document.createElement('tr');
      row.className = "border-b border-brandIceBlue hover:bg-[#f0f4f8]/50 transition-colors text-slate-700";
      
      // Amortização Badge
      const isSac = rate.type.toUpperCase() === 'SAC';
      const amortBadge = isSac
        ? `<span class="bg-emerald-50 text-emerald-700 border border-emerald-200 px-2.5 py-1 rounded-lg text-xs font-semibold uppercase tracking-wider">SAC</span>`
        : `<span class="bg-brandSecondary/10 text-brandSecondary border border-brandSecondary/20 px-2.5 py-1 rounded-lg text-xs font-semibold uppercase tracking-wider">Price</span>`;

      // Institution Name
      const institutionName = rate.institution ? rate.institution.name : 'Banco Removido';

      row.innerHTML = `
        <td class="px-6 py-4 font-semibold text-slate-700">${escapeHtml(institutionName)}</td>
        <td class="px-6 py-4">${amortBadge}</td>
        <td class="px-6 py-4 text-slate-600 font-medium">${rate.rateValue.toFixed(2)}%</td>
        <td class="px-6 py-4 text-slate-600 font-medium">${rate.maxLTV.toFixed(1)}%</td>
        <td class="px-6 py-4 text-slate-600">${rate.minTerm} a ${rate.maxTerm} m</td>
        <td class="px-6 py-4 text-slate-600">${rate.maxAge} anos</td>
        <td class="px-6 py-4 text-right">
          <div class="flex items-center justify-end space-x-2.5">
            <button 
              id="edit-rate-${rate.id}"
              class="text-brandSecondary hover:text-brandSecondary/80 bg-brandSecondary/10 hover:bg-brandSecondary/20 border border-brandSecondary/20 hover:border-brandSecondary/30 p-2 rounded-xl transition-all duration-200"
              title="Editar Taxa"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
              </svg>
            </button>
            <button 
              id="delete-rate-${rate.id}"
              class="text-[#EF4444] hover:text-red-700 bg-red-50 hover:bg-red-100 border border-red-200/60 p-2 rounded-xl transition-all duration-200"
              title="Excluir Taxa"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </td>
      `;

      ratesTableBody.appendChild(row);

      // Event listener for Edit button
      row.querySelector(`#edit-rate-${rate.id}`).addEventListener('click', () => {
        openRateModal(rate);
      });

      // Event listener for Delete button
      row.querySelector(`#delete-rate-${rate.id}`).addEventListener('click', () => {
        openDeleteModal(
          'Excluir Regra de Taxa',
          `Tem certeza que deseja excluir esta regra de taxa de juros do banco "${institutionName}"?`,
          () => deleteRate(rate.id)
        );
      });
    });

  } catch (error) {
    ratesLoader.classList.add('hidden');
    showToast('Erro ao carregar taxas.', 'error');
  }
}

/**
 * Carrega os bancos do select do modal e abre o modal de taxas
 * @param {object|null} rate 
 */
async function openRateModal(rate = null) {
  // Limpar erros anteriores
  document.getElementById('rateInstitutionError').classList.add('hidden');
  document.getElementById('rateValueError').classList.add('hidden');
  document.getElementById('rateMaxLTVError').classList.add('hidden');
  document.getElementById('rateMaxAgeError').classList.add('hidden');
  document.getElementById('rateMinTermError').classList.add('hidden');
  document.getElementById('rateMaxTermError').classList.add('hidden');

  btnSaveRateSpinner.classList.add('hidden');
  btnSaveRateText.textContent = 'Salvar Taxa';
  rateForm.removeAttribute('disabled');

  try {
    // Buscar bancos atualizados para alimentar o Select
    const res = await fetchWithAuth('/api/admin/institutions');
    if (!res) return;
    
    const banks = await res.json();
    
    // Limpar e popular o select de instituições
    rateInstitutionSelect.innerHTML = '<option value="" disabled selected>Selecione um banco...</option>';
    
    // Adicionar apenas bancos ativos (a não ser que estejamos editando uma taxa vinculada a um banco inativo)
    banks.forEach(b => {
      if (b.isActive || (rate && rate.institutionId === b.id)) {
        const opt = document.createElement('option');
        opt.value = b.id;
        opt.textContent = b.name;
        rateInstitutionSelect.appendChild(opt);
      }
    });

  } catch (error) {
    showToast('Erro ao obter lista de bancos para o formulário.', 'error');
    return;
  }

  // Preencher dados se for edição
  if (rate) {
    document.getElementById('rateModalTitle').textContent = 'Editar Regra de Taxa';
    rateIdInput.value = rate.id;
    rateInstitutionSelect.value = rate.institutionId;
    rateTypeSelect.value = rate.type;
    rateValueInput.value = rate.rateValue;
    rateMaxLTVInput.value = rate.maxLTV;
    rateMaxAgeInput.value = rate.maxAge;
    rateMinTermInput.value = rate.minTerm;
    rateMaxTermInput.value = rate.maxTerm;
  } else {
    document.getElementById('rateModalTitle').textContent = 'Nova Regra de Taxa';
    rateIdInput.value = '';
    rateForm.reset();
    rateTypeSelect.value = 'SAC'; // Default
  }

  openModal(rateModal);
}

function closeRateModal() {
  closeModal(rateModal);
}

/**
 * Cria ou atualiza uma taxa de juros
 * @param {Event} e 
 */
async function saveRate(e) {
  e.preventDefault();

  const instId = rateInstitutionSelect.value;
  const type = rateTypeSelect.value;
  const rateValue = parseFloat(rateValueInput.value);
  const maxLTV = parseFloat(rateMaxLTVInput.value);
  const maxAge = parseInt(rateMaxAgeInput.value);
  const minTerm = parseInt(rateMinTermInput.value);
  const maxTerm = parseInt(rateMaxTermInput.value);

  let hasError = false;

  // Validação simples
  if (!instId) {
    document.getElementById('rateInstitutionError').classList.remove('hidden');
    hasError = true;
  }
  if (isNaN(rateValue) || rateValue < 0) {
    document.getElementById('rateValueError').classList.remove('hidden');
    hasError = true;
  }
  if (isNaN(maxLTV) || maxLTV <= 0 || maxLTV > 100) {
    document.getElementById('rateMaxLTVError').classList.remove('hidden');
    hasError = true;
  }
  if (isNaN(maxAge) || maxAge < 18 || maxAge > 120) {
    document.getElementById('rateMaxAgeError').classList.remove('hidden');
    hasError = true;
  }
  if (isNaN(minTerm) || minTerm < 1) {
    document.getElementById('rateMinTermError').classList.remove('hidden');
    hasError = true;
  }
  if (isNaN(maxTerm) || maxTerm < minTerm) {
    document.getElementById('rateMaxTermError').classList.remove('hidden');
    hasError = true;
  }

  if (hasError) return;

  const rateId = rateIdInput.value;
  const isEditing = !!rateId;

  // Mostrar loading
  btnSaveRateSpinner.classList.remove('hidden');
  btnSaveRateText.textContent = isEditing ? 'Atualizando...' : 'Salvando...';

  const bodyData = {
    institutionId: instId,
    type,
    rateValue,
    maxLTV,
    maxAge,
    minTerm,
    maxTerm
  };

  try {
    let res;
    if (isEditing) {
      res = await fetchWithAuth(`/api/admin/interest-rates/${rateId}`, {
        method: 'PUT',
        body: JSON.stringify(bodyData)
      });
    } else {
      res = await fetchWithAuth('/api/admin/interest-rates', {
        method: 'POST',
        body: JSON.stringify(bodyData)
      });
    }

    if (res && res.ok) {
      showToast('Taxa de juros salva com sucesso!', 'success');
      closeRateModal();
      loadRates();
    } else {
      const err = res ? await res.json() : { error: 'Sem resposta' };
      showToast(err.error || 'Erro ao processar taxa.', 'error');
    }
  } catch (error) {
    showToast('Falha na comunicação com o servidor.', 'error');
  } finally {
    btnSaveRateSpinner.classList.add('hidden');
    btnSaveRateText.textContent = 'Salvar Taxa';
  }
}

/**
 * Remove uma taxa de juros do banco
 * @param {string} id 
 */
async function deleteRate(id) {
  try {
    const res = await fetchWithAuth(`/api/admin/interest-rates/${id}`, {
      method: 'DELETE'
    });

    if (res && res.ok) {
      showToast('Regra de taxa removida com sucesso!', 'success');
      loadRates();
    } else {
      const err = res ? await res.json() : {};
      showToast(err.error || 'Erro ao deletar taxa.', 'error');
    }
  } catch (error) {
    showToast('Erro de rede ao deletar taxa.', 'error');
  }
}

// ================= UTILITÁRIOS =================

/**
 * Escapa HTML básico para evitar vulnerabilidades XSS refletidas
 * @param {string} unsafe 
 */
function escapeHtml(unsafe) {
  if (typeof unsafe !== 'string') return unsafe;
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}
