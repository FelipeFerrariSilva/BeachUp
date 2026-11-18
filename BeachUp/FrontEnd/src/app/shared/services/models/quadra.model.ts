export interface QuadraPayload {
  nome: string;
  tipoCobertura: 'COBERTA' | 'DESCOBERTA';
  valorHora: number;
}

export interface QuadraResponse {
  id: number;
  nome: string;
  tipoCobertura: 'COBERTA' | 'DESCOBERTA';
  valorHora: number;
  fotos?: string[];
}

export interface ReservaResponse {
  id: number;
  quadraId: number;
  nomeQuadra: string;
  jogadorId: number;
  nomeJogador: string;
  dataHoraInicio: string;
  dataHoraFim: string;
  valorTotal: number;
  status: 'PENDENTE' | 'CONFIRMADA' | 'CANCELADA';
}

export interface AssinaturaResponse {
  id: number;
  tipoPlano: 'GRATUITO' | 'PREMIUM';
  nome: string;
  limiteQuadras: number | null;
  valorMensal: number;
  dataInicio: string;
  dataFim: string | null;
  status: string;
  premiumAtivo: boolean;
}

export interface HorarioFuncionamento {
  id: number;
  diaSemana: string;
  diaSemanaLabel: string;
  horaAbertura: string;
  horaFechamento: string;
}
