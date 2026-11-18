import { Routes } from '@angular/router';
import { Home } from './pages/home/home';
import { Sobre } from './pages/sobre/sobre';
import { Login } from './pages/login/login';
import { Perfil } from './pages/perfil/perfil';
import { DashboardDono } from './pages/dashboard-dono/dashboard-dono';
import { Arena } from './pages/arena/arena';
import { QuadrasDono } from './pages/quadras-dono/quadras-dono';
import { Reservas } from './pages/reservas/reservas';
import { authGuard } from './shared/guards/auth.guard';
import { MinhasReservas } from './pages/minhas-reservas/minhas-reservas';
import { Campeonatos } from './pages/campeonatos/campeonatos';
import { CampeonatosDono } from './pages/campeonatos-dono/campeonatos-dono';
import { CampeonatoDetalhe } from './pages/campeonato-detalhe/campeonato-detalhe';
import { CampeonatoInscricao } from './pages/campeonato-inscricao/campeonato-inscricao';
import { ConvidarJogadores } from './pages/convidar-jogadores/convidar-jogadores';
import { AceitarConvite } from './pages/aceitar-convite/aceitar-convite';
import { EsqueciSenha } from './pages/esqueceu-senha/esqueceu-senha';
import { RedefinirSenha } from './pages/redefinir-senha/redefinir-senha';
import { AvaliacaoReserva } from './pages/avaliacao-reserva/avaliacao-reserva';
import { Planos } from './pages/planos/planos';
import { Pagamentos } from './pages/pagamentos/pagamentos';
import { PagamentoRetorno } from './pages/pagamento-retorno/pagamento-retorno';
import { MetricasDono } from './pages/metricas-dono/metricas-dono';

export const routes: Routes = [
  { path: '', component: Home },
  { path: 'sobre', component: Sobre },
  { path: 'login', component: Login },
  { path: 'login/cadastrar', component: Login },
  { path: 'esqueci-senha', component: EsqueciSenha },
  { path: 'redefinir-senha', component: RedefinirSenha },

  { path: 'arena', component: Arena, canActivate: [authGuard] },
  { path: 'dashboard-dono', component: DashboardDono, canActivate: [authGuard] },
  { path: 'quadras-dono', component: QuadrasDono, canActivate: [authGuard] },
  { path: 'perfil', component: Perfil, canActivate: [authGuard] },
  { path: 'reservas', component: Reservas, canActivate: [authGuard] },
  { path: 'minhas-reservas', component: MinhasReservas, canActivate: [authGuard] },
  { path: 'avaliacao', component: AvaliacaoReserva, canActivate: [authGuard] },
  { path: 'planos', component: Planos, canActivate: [authGuard] },
  { path: 'conta', component: Pagamentos, canActivate: [authGuard] },
  { path: 'pagamento', component: PagamentoRetorno, canActivate: [authGuard] },
  { path: 'metricas', component: MetricasDono, canActivate: [authGuard] },

  { path: 'convidar-jogadores', component: ConvidarJogadores, canActivate: [authGuard] },
  { path: 'aceitar-convite/:token', component: AceitarConvite },

  { path: 'campeonatos/inscrever/:token', component: CampeonatoInscricao },
  { path: 'campeonatos-dono', component: CampeonatosDono, canActivate: [authGuard] },
  { path: 'campeonatos/:id', component: CampeonatoDetalhe, canActivate: [authGuard] },
  { path: 'campeonatos', component: Campeonatos, canActivate: [authGuard] },

  { path: '**', redirectTo: '' },
];
