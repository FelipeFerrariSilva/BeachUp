import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute } from '@angular/router';
import { NavigationService } from '../../shared/services/models/navigation';

type Resultado = 'sucesso' | 'falha' | 'pendente';

@Component({
  selector: 'app-pagamento-retorno',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './pagamento-retorno.html',
  styleUrl: './pagamento-retorno.css',
})
export class PagamentoRetorno implements OnInit {
  private route = inject(ActivatedRoute);
  private navigation = inject(NavigationService);

  resultado: Resultado = 'sucesso';
  destino: 'reserva' | 'plano' | 'inscricao' = 'plano';
  segundosRestantes = 5;

  private readonly DESTINOS: Record<string, { rota: string; label: string }> = {
    reserva: { rota: 'minhas-reservas', label: 'Minhas Reservas' },
    inscricao: { rota: 'campeonatos', label: 'Campeonatos' },
    plano: { rota: 'planos', label: 'Planos' },
  };

  ngOnInit(): void {
    const path = this.route.snapshot.routeConfig?.path ?? '';
    if (path.endsWith('falha')) this.resultado = 'falha';
    else if (path.endsWith('pendente')) this.resultado = 'pendente';
    else this.resultado = 'sucesso';

    const externalReference = this.route.snapshot.queryParamMap.get('external_reference') ?? '';

    if (externalReference.startsWith('RESERVA_')) {
      this.destino = 'reserva';
    } else if (externalReference.startsWith('INSCRICAO_')) {
      this.destino = 'inscricao';
    } else {
      this.destino = 'plano';
    }

    this.iniciarContagemERedirecionar();
  }

  private iniciarContagemERedirecionar(): void {
    const intervalo = setInterval(() => {
      this.segundosRestantes--;
      if (this.segundosRestantes <= 0) {
        clearInterval(intervalo);
        this.irParaDestino();
      }
    }, 1000);
  }

  get rotaDestino(): string {
    return this.DESTINOS[this.destino].rota;
  }

  get labelDestino(): string {
    return this.DESTINOS[this.destino].label;
  }

  irParaDestino(): void {
    this.navigation.irPara(this.rotaDestino);
  }
}
