import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MeusTimes } from './meus-times';

describe('MeusTimes', () => {
  let component: MeusTimes;
  let fixture: ComponentFixture<MeusTimes>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MeusTimes]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MeusTimes);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
