export interface UsuarioCreate {
  nome: string;
  cpf: string;
  email: string;
  senha: string;
  confirmarSenha: string;
}

export interface EmpresaCreate {
  nome: string;
  cnpj: string;
  email: string;
  senha: string;
  confirmarSenha: string;
}

export interface LoginPayload {
  email: string;
  senha: string;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
}
