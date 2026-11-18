import { Injectable } from '@angular/core';
import Swal, { SweetAlertOptions } from 'sweetalert2';

const BASE: SweetAlertOptions = {
  background: '#141414',
  color: '#f0f0f0',
  allowOutsideClick: true,
  showClass: {
    popup: 'animate__animated animate__fadeInDown animate__faster',
  },
  hideClass: {
    popup: 'animate__animated animate__fadeOutUp animate__faster',
  },
  customClass: {
    popup: 'swal-beachup-popup',
    confirmButton: 'swal-beachup-btn-confirm',
    cancelButton: 'swal-beachup-btn-cancel',
    title: 'swal-beachup-title',
    htmlContainer: 'swal-beachup-text',
  },
};

const logout: SweetAlertOptions = {
  background: '#141414',
  color: '#fff',
  iconColor: '#ef4444',
  allowOutsideClick: true,
  customClass: {
    popup: 'swal-beachup-popup',
    confirmButton: 'swal-beachup-btn-confirm',
    cancelButton: 'swal-beachup-btn-cancel',
    title: 'swal-beachup-title',
    htmlContainer: 'swal-beachup-text',
  },
};

@Injectable({ providedIn: 'root' })
export class AlertService {

  sucesso(mensagem: string) {
    return Swal.fire({
      ...BASE,
      icon: 'success',
      title: 'Tudo certo!',
      text: mensagem,
      confirmButtonText: 'Continuar',
      timer: 3000,
      timerProgressBar: true,
    });
  }

  erro(mensagem?: string) {
    return Swal.fire({
      ...BASE,
      icon: 'error',
      title: 'Algo deu errado',
      text: mensagem || 'Ocorreu um erro inesperado. Tente novamente.',
      confirmButtonText: 'Entendi',
    });
  }

  erroLogin() {
    return Swal.fire({
      ...BASE,
      icon: 'error',
      title: 'Não foi possível entrar',
      text: 'Email ou senha incorretos. Verifique seus dados e tente novamente.',
      confirmButtonText: 'Tentar novamente',
    });
  }

  erroNaoAutorizado() {
    return Swal.fire({
      ...BASE,
      icon: 'error',
      title: 'Acesso negado',
      text: 'Você não tem permissão para realizar esta ação.',
      confirmButtonText: 'Entendi',
    });
  }

  erroServidor() {
    return Swal.fire({
      ...BASE,
      icon: 'error',
      title: 'Erro no servidor',
      text: 'O servidor está com problemas. Aguarde alguns instantes e tente novamente.',
      confirmButtonText: 'Entendi',
    });
  }

  erroConexao() {
    return Swal.fire({
      ...BASE,
      icon: 'error',
      title: 'Sem conexão',
      text: 'Não foi possível conectar ao servidor. Verifique sua internet e tente novamente.',
      confirmButtonText: 'Entendi',
    });
  }

  erroEmailJaCadastrado() {
    return Swal.fire({
      ...BASE,
      icon: 'error',
      title: 'Email já cadastrado',
      text: 'Este email já está em uso. Tente fazer login ou use outro email.',
      confirmButtonText: 'Entendi',
    });
  }

  aviso(mensagem: string) {
    return Swal.fire({
      ...BASE,
      icon: 'warning',
      title: 'Atenção',
      text: mensagem,
      confirmButtonText: 'Ok',
    });
  }

  senha() {
    return Swal.fire({
      ...BASE,
      icon: 'success',
      title: 'Senhas redefinidas com sucesso!',
      text: 'A nova senha já está disponível para uso.',
      confirmButtonText: 'Ok',
    });
  }

  avisoCamposObrigatorios() {
    return Swal.fire({
      ...BASE,
      icon: 'warning',
      title: 'Campos incompletos',
      text: 'Preencha todos os campos obrigatórios antes de continuar.',
      confirmButtonText: 'Revisar',
    });
  }

  avisoSessaoExpirada() {
    return Swal.fire({
      ...BASE,
      icon: 'warning',
      title: 'Sessão expirada',
      text: 'Sua sessão expirou. Faça login novamente para continuar.',
      confirmButtonText: 'Fazer login',
    });
  }


  confirmar(titulo: string, mensagem: string) {
    return Swal.fire({
      ...BASE,
      icon: 'question',
      title: titulo,
      text: mensagem,
      showCancelButton: true,
      confirmButtonText: 'Confirmar',
      cancelButtonText: 'Cancelar',
      reverseButtons: true,
    });
  }

  confirmarExclusao(item = 'este item') {
    return Swal.fire({
      ...BASE,
      icon: 'warning',
      title: 'Excluir?',
      text: `Você tem certeza que deseja excluir ${item}? Esta ação não poderá ser desfeita.`,
      showCancelButton: true,
      confirmButtonText: 'Sim, excluir',
      cancelButtonText: 'Cancelar',
      reverseButtons: true,
    });
  }

  Sair() {
    return Swal.fire({
      ...BASE,
      icon: 'error',
      title: 'Você deseja sair do sistema?',
      text: `Após sair, será redirecionado para o login.`,
      showCancelButton: true,
      confirmButtonText: 'Sair',
      cancelButtonText: 'Cancelar',
      reverseButtons: true,
    });
  }

  erroHttp(err: any) {
    if (!err?.status || err.status === 0) return this.erroConexao();
    if (err.status === 401) return this.erroLogin();
    if (err.status === 403) return this.erroNaoAutorizado();
    if (err.status === 500) return this.erroServidor();

    const mensagem = err?.error?.message || err?.error?.error || null;
    return this.erro(mensagem);
  }
}
