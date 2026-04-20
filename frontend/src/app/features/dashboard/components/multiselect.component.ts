import { CommonModule } from '@angular/common';
import {
  Component, Input, Output, EventEmitter,
  HostListener, forwardRef,
  NgModule
} from '@angular/core';
import { ControlValueAccessor, FormsModule, NG_VALUE_ACCESSOR } from '@angular/forms';
import { SelectOption } from '../../../core/models/dashboard.models';

@Component({
  selector: 'app-multiselect',
  templateUrl: './multiselect.component.html',
  styleUrls: ['./multiselect.component.scss'],
  imports: [FormsModule, CommonModule],
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => MultiselectComponent),
    multi: true
  }]
})
export class MultiselectComponent implements ControlValueAccessor {
  @Input() options: SelectOption[] = [];
  @Input() placeholder = 'Chọn mục...';

  isOpen = false;
  searchText: string = '';
  selectedValues: any[] = [];
  customTags: any[] = [];
  disabled = false;

  private onChange = (_: any) => {};
  private onTouched = () => {};

  get isTagMode(): boolean {
    return this.options.length === 0;
  }

  get filteredOptions(): SelectOption[] {
    return this.options.filter(o =>
      o.label.toString().toLowerCase().includes(this.searchText.toLowerCase())
    );
  }

  get canAddTag(): boolean {
    const q = this.searchText.trim();
    return this.isTagMode && !!q && !this.customTags.includes(q);
  }  

  get summary(): string {
    if (!this.selectedValues.length) return '';
    return `${this.selectedValues.length} mục đã chọn`;
  }

  get selectedOptions(): SelectOption[] {
    return this.options.filter(o => this.selectedValues.includes(o.value));
  }

  isSelected(value: any): boolean {
    return this.selectedValues.includes(value);
  }

  toggleDropdown(): void {
    if (this.disabled) return;
    this.isOpen = !this.isOpen;
    if (!this.isOpen) this.searchText = '';
    this.onTouched();
  }

  toggleOption(value: any): void {
    const idx = this.selectedValues.indexOf(value);
    
    if (idx > -1) {
      this.selectedValues = this.selectedValues.filter(v => v !== value);
    } else {
      this.selectedValues = [...this.selectedValues, value];
    }
    this.onChange(this.selectedValues);
    this.isOpen = false;
  }

  removeOption(value: any, event: Event): void {
    event.stopPropagation();
    this.selectedValues = this.selectedValues.filter(v => v !== value);
    this.onChange(this.selectedValues);
  }

  selectAll(): void {
    this.selectedValues = this.options.map(o => o.value);
    this.onChange(this.selectedValues);
  }

  // ── Tag mode ────────────────────────────────────────────────────
  addTag(raw?: string): void {
    const tag = (raw ?? this.searchText).trim();
    if (!tag || this.customTags.includes(tag)) return;
    this.customTags = [...this.customTags, tag];
    this.searchText = '';
    this.emit();
  }

  removeTag(tag: string): void {
    this.customTags = this.customTags.filter(t => t !== tag);
    this.emit();
  }  

  // ── Emit ────────────────────────────────────────────────────────
  private emit(): void {
    this.onChange([...this.selectedValues, ...this.customTags]);
  }  

  clearAll(): void {
    this.selectedValues = [];
    this.customTags = [];
    this.emit();
  }

  @HostListener('document:click', ['$event'])
  onClickOutside(event: Event): void {
    const el = event.target as HTMLElement;
    if (!el.closest('app-multiselect')) {
      this.isOpen = false;
      this.searchText = '';
    }
  }

  // ── Keyboard ────────────────────────────────────────────────────
  onSearchKeydown(event: KeyboardEvent): void {
    if (event.key === 'Enter') {
      event.preventDefault();
      if (this.isTagMode) {
        this.addTag();
      } else if (this.filteredOptions.length === 1) {
        this.toggleOption(this.filteredOptions[0].value);
      }
    }
    // Backspace xóa tag cuối khi input đang trống (chỉ tag mode)
    if (event.key === 'Backspace' && this.isTagMode
        && !this.searchText && this.customTags.length) {
      this.removeTag(this.customTags[this.customTags.length - 1]);
    }
  }  

  // ControlValueAccessor
  writeValue(value: any[]): void {
    this.selectedValues = value ?? [];
  }
  registerOnChange(fn: any): void { this.onChange = fn; }
  registerOnTouched(fn: any): void { this.onTouched = fn; }
  setDisabledState(isDisabled: boolean): void { this.disabled = isDisabled; }
}