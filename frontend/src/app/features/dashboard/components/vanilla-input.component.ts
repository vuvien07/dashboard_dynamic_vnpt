import { CommonModule } from '@angular/common';
import { Component, ElementRef, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { SelectOption } from '../../../core/models/dashboard.models';
import { debounceTime, distinctUntilChanged } from 'rxjs';

type InputType = 'number' | 'date' | 'datetime-local' | 'time' | 'text';

export interface InputValue {
  value: any;
}

@Component({
  selector: 'app-vanilla-input',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule],
  templateUrl: './vanilla-input.component.html',
  styleUrl: './vanilla-input.component.scss'
})
export class VanillaInputComponent implements OnInit{
  @Input() dataType: string = '';
  @Output() valueChange = new EventEmitter<InputValue>();
  @Input() placeholder: string = '';
  @Input() options: SelectOption[] = [];
  @ViewChild('inputRef') inputRef!: ElementRef<HTMLInputElement>;

  form!: FormGroup;
  isOpen = false;
  filteredOptions: SelectOption[] = [];

  get hasOptions(): boolean { return this.options.length > 0; }  

  get inputKind(): InputType {
    const ft = (this.dataType ?? '').toLowerCase().trim();

    if (ft === 'date') return 'date';

    if (['timestamp', 'timestamp without time zone',
      'timestamp with time zone', 'timestamptz'].includes(ft))
      return 'datetime-local';

    if (['time', 'time without time zone',
      'time with time zone', 'timetz'].includes(ft))
      return 'time';

    if (['integer', 'int', 'int2', 'int4', 'int8',
      'bigint', 'smallint', 'numeric', 'decimal',
      'real', 'float4', 'float8', 'double precision',
      'money', 'serial', 'bigserial'].includes(ft))
      return 'number';

    // character varying, text, uuid, char, ...
    return 'text';
  }

  constructor(private fb: FormBuilder) { }

  ngOnInit() {
    this.form = this.fb.group({ value: [null] });
    this.filteredOptions = [...this.options];

    this.form.get('value')!.valueChanges.pipe(
      debounceTime(150),
      distinctUntilChanged()
    ).subscribe(q => {
      const query = (q ?? '').toString().toLowerCase();
      this.filteredOptions = this.options.filter(o =>
        o.label.toString().toLowerCase().includes(query)
      );
      this.valueChange.emit({ value: q });
    });
  }

  openDropdown(): void {
    if (!this.hasOptions) return;
    this.filteredOptions = [...this.options];
    this.isOpen = true;
  }

  closeDropdown(): void {
    setTimeout(() => this.isOpen = false, 150);
  }

  selectOption(opt: SelectOption): void {
    this.form.get('value')!.setValue(opt.label, { emitEvent: false });
    this.valueChange.emit({ value: opt.value });
    this.isOpen = false;
  }

  toggleDropdown(): void {
    this.isOpen
      ? this.closeDropdown()
      : (this.inputRef.nativeElement.focus(), this.openDropdown());
  }  
}
