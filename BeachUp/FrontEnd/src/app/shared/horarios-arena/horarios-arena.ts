import { Component, Input, OnChanges, SimpleChanges, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { AlertService } from '../../shared/services/sweetalert2.service';

interface HorarioResponse {
  diaSemana: string;
  horaAbertura: string;
  horaFechamento: string;
}

const DIA_LABELS: Record<string, string> = {
  MONDAY: 'Segunda-feira',
  TUESDAY: 'Terça-feira',
  WEDNESDAY: 'Quarta-feira',
  THURSDAY: 'Quinta-feira',
  FRIDAY: 'Sexta-feira',
  SATURDAY: 'Sábado',
  SUNDAY: 'Domingo',
};

const DIAS_SEMANA = Object.keys(DIA_LABELS);

@Component({
  selector: 'app-horarios-arena',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './horarios-arena.html',
  styleUrls: ['./horarios-arena.css'],
})
export class HorariosArena implements OnChanges {
  @Input() arenaId!: number;

  private http = inject(HttpClient);
  private fb = inject(FormBuilder);
  private alertService = inject(AlertService);

  private baseUrl = 'http://localhost:8080';

  horarios: HorarioResponse[] = [];
  carregando = false;
  salvando = false;

  diasSemana = DIAS_SEMANA;
  diaLabels = DIA_LABELS;

  diaAtivo: string | null = null;

  horarioForm: FormGroup = this.fb.group({
    diaSemana: ['', Validators.required],
    horaAbertura: ['08:00', Validators.required],
    horaFechamento: ['22:00', Validators.required],
  });

  get f() {
    return this.horarioForm.controls;
  }

  private headers(): HttpHeaders {
    const token = localStorage.getItem('token') ?? '';
    return new HttpHeaders({ Authorization: `Bearer ${token}` });
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['arenaId'] && this.arenaId) {
      this.carregar();
    }
  }

  carregar(): void {
    this.carregando = true;
    this.http.get<HorarioResponse[]>(`${this.baseUrl}/arenas/${this.arenaId}/horarios`).subscribe({
      next: (data) => {
        this.horarios = data;
        this.carregando = false;
      },
      error: () => {
        this.carregando = false;
      },
    });
  }

  horarioDoDia(dia: string): HorarioResponse | undefined {
    return this.horarios.find((h) => h.diaSemana === dia);
  }

  abrirFormDia(dia: string): void {
    const existente = this.horarioDoDia(dia);
    this.diaAtivo = dia;
    this.horarioForm.patchValue({
      diaSemana: dia,
      horaAbertura: existente?.horaAbertura ?? '08:00',
      horaFechamento: existente?.horaFechamento ?? '22:00',
    });
  }

  fecharForm(): void {
    this.diaAtivo = null;
    this.horarioForm.reset({ horaAbertura: '08:00', horaFechamento: '22:00' });
  }

  salvar(): void {
    if (this.horarioForm.invalid) {
      this.horarioForm.markAllAsTouched();
      return;
    }

    const { diaSemana, horaAbertura, horaFechamento } = this.horarioForm.value;
    this.salvando = true;

    this.http
      .post<HorarioResponse>(
        `${this.baseUrl}/arenas/${this.arenaId}/horarios`,
        { diaSemana, horaAbertura, horaFechamento },
        { headers: this.headers() },
      )
      .subscribe({
        next: (salvo) => {
          const idx = this.horarios.findIndex((h) => h.diaSemana === diaSemana);
          if (idx >= 0) this.horarios[idx] = salvo;
          else this.horarios.push(salvo);
          this.salvando = false;
          this.fecharForm();
          this.alertService.sucesso('Horário salvo!');
        },
        error: () => {
          this.salvando = false;
          this.alertService.erro('Erro ao salvar horário.');
        },
      });
  }

  remover(dia: string): void {
    this.alertService
      .confirmar('Remover horário?', `${DIA_LABELS[dia]} ficará como fechado.`)
      .then((ok) => {
        if (!ok) return;
        this.http
          .delete(`${this.baseUrl}/arenas/${this.arenaId}/horarios/${dia}`, {
            headers: this.headers(),
          })
          .subscribe({
            next: () => {
              this.horarios = this.horarios.filter((h) => h.diaSemana !== dia);
              this.alertService.sucesso('Horário removido.');
            },
            error: () => this.alertService.erro('Erro ao remover horário.'),
          });
      });
  }
}
