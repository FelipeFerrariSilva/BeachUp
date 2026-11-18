import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CampeonatoInscricao } from './campeonato-inscricao';

describe('CampeonatoInscricao', () => {
  let component: CampeonatoInscricao;
  let fixture: ComponentFixture<CampeonatoInscricao>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CampeonatoInscricao]
    })
    .compileComponents();

    fixture = TestBed.createComponent(CampeonatoInscricao);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
