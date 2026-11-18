export type StatusMembroTime = 'PENDENTE' | 'ACEITO' | 'RECUSADO';

export interface MembroResponse {
  idJogador: number;
  nomeUsuario: string;
  status: StatusMembroTime;
}

export interface TimesResponse {
  id: number;
  nome: string;
  descricao: string | null;
  urlConvite: string | null;
  idJogadorDono: number;
  membros: MembroResponse[];
}

export interface TimesCadastroPayload {
  nome: string;
  descricao?: string;
}
