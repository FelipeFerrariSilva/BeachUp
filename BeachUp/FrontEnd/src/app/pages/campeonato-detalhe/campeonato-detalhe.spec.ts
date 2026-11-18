import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CampeonatoDetalhe } from './campeonato-detalhe';

describe('CampeonatoDetalhe', () => {
  let component: CampeonatoDetalhe;
  let fixture: ComponentFixture<CampeonatoDetalhe>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CampeonatoDetalhe]
    })
    .compileComponents();

    fixture = TestBed.createComponent(CampeonatoDetalhe);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
