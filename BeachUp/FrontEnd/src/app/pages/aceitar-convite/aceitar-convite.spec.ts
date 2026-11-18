import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AceitarConvite } from './aceitar-convite';

describe('AceitarConvite', () => {
  let component: AceitarConvite;
  let fixture: ComponentFixture<AceitarConvite>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AceitarConvite]
    })
    .compileComponents();

    fixture = TestBed.createComponent(AceitarConvite);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
