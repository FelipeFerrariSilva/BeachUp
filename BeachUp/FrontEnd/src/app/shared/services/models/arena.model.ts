export interface EnderecoPayload {
  logradouro: string;
  numero: string;
  bairro: string;
  cidade: string;
  estado: string;
  cep: string;
}

export interface ArenaCadastroPayload {
  nome: string;
  descricao: string;
  endereco: EnderecoPayload;
  latitude?: number;
  longitude?: number;
}

export interface ArenaResponse {
  id: number;
  nome: string;
  descricao: string;
  endereco: EnderecoPayload;
  latitute: number;
  longitude: number;
  distanciaKm: number | null;
  empresa: {
    id: number;
    cnpj: string;
    tipoPlano: string;
  };
  fotoUrl?: string | null;
}
