import { ComponentFixture, TestBed } from '@angular/core/testing';
import { AvaliacaoReserva } from './avaliacao-reserva';

describe('AvaliacaoReserva', () => {
  let component: AvaliacaoReserva;
  let fixture: ComponentFixture<AvaliacaoReserva>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AvaliacaoReserva],
    }).compileComponents();

    fixture = TestBed.createComponent(AvaliacaoReserva);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
