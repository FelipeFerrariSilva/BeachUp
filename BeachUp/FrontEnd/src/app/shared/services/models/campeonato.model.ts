export type StatusCampeonato =
  | 'INSCRICOES_ABERTAS'
  | 'INSCRICOES_FECHADAS'
  | 'EM_ANDAMENTO'
  | 'FINALIZADO';

export type StatusPartida = 'AGUARDANDO' | 'FINALIZADA';

export interface CampeonatoCadastroPayload {
  nome: string;
  descricao?: string;
  categoria?: string;
  dataInicio: string; // yyyy-MM-dd
  dataFim?: string; // yyyy-MM-dd
  arenaId: number;
}

export interface CampeonatoResponse {
  id: number;
  nome: string;
  descricao: string | null;
  categoria: string | null;
  dataInicio: string;
  dataFim: string | null;
  status: StatusCampeonato;
  tokenInscricao: string | null;
  idEmpresa: number;
  idArena: number;
  idTimeVencedor: number | null;
  totalInscritos: number;
}

export interface PartidaResponse {
  id: number;
  fase: string;
  rodada: number;
  idTimeCasa: number | null;
  nomeTimeCasa: string | null;
  idTimeVisitante: number | null;
  nomeTimeVisitante: string | null;
  placarTimeCasa: number | null;
  placarTimeVisitante: number | null;
  idTimeVencedor: number | null;
  dataHoraJogo: string | null;
  status: StatusPartida;
}

export interface ResultadoPartidaPayload {
  placarTimeCasa: number;
  placarTimeVisitante: number;
}

// Ordem fixa das fases para montar o bracket visual (eliminação simples)
export const ORDEM_FASES = ['Oitavas de final', 'Quartas de final', 'Semifinal', 'Final'];

export const STATUS_CAMPEONATO_LABEL: Record<StatusCampeonato, string> = {
  INSCRICOES_ABERTAS: 'Inscrições abertas',
  INSCRICOES_FECHADAS: 'Inscrições fechadas',
  EM_ANDAMENTO: 'Em andamento',
  FINALIZADO: 'Finalizado',
};
