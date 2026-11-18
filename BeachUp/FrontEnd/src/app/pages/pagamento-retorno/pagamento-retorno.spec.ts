import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PagamentoRetorno } from './pagamento-retorno';

describe('PagamentoRetorno', () => {
  let component: PagamentoRetorno;
  let fixture: ComponentFixture<PagamentoRetorno>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PagamentoRetorno]
    })
    .compileComponents();

    fixture = TestBed.createComponent(PagamentoRetorno);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
