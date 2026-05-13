; UX-MINIMA x64 V3.3-stage11 generated NASM
default rel
global uxm_entry
global ux_mem
global ux_status
global ux_flags
global ux_ptr
global ux_sp
global ux_cell_bits
global ux_cell_bytes
global ux_tape_cells
global ux_stack_cells
global ux_data_cells
global ux_queue_cells
global ux_stack_offset
global ux_data_offset
global ux_pragma_seed_enabled
global ux_pragma_seed_value
global ux_pragma_arge_json
global ux_pragma_arge_interpreter
global ux_pragma_arge_step
global ux_pragma_arge_trace
global ux_pragma_arge_watch
extern ux_putc
extern ux_getc
extern ux_print_data_string
extern ux_meta_call_ex
extern ux_runtime_error
%define UXM_TOTAL_BYTES 335872
%define TAPE_BYTES 65536
%define STACK_BYTES 8192
%define DATA_BYTES 262144
%define QUEUE_BYTES 4096
%define STACK_OFFSET 65536
%define DATA_OFFSET 73728
%define TAPE_CELLS 16384
%define STACK_CELLS 2048
%define DATA_CELLS 65536
%define QUEUE_CELLS 1024
%define CELL_BITS 32
%define CELL_BYTES 4
%define FLAG_Z 1
%define FLAG_C 2
%define FLAG_O 4
%define FLAG_S 8
%define FLAG_SGN 16
%define FLAG_END 32
%define FLAG_WILD 64
%define FLAG_BND 128
%define FLAG_TRC 256
%define FLAG_FIFO 512
%define FLAG_ERR 1024
%define FLAG_DIRTY 2048
%define FLAG_PCHG 4096
section .bss
align 16
ux_mem: resb UXM_TOTAL_BYTES
ux_status: resb 1
ux_flags: resw 1
ux_ptr: resq 1
ux_sp: resq 1
ux_cell_bits: resd 1
ux_cell_bytes: resd 1
ux_tape_cells: resd 1
ux_stack_cells: resd 1
ux_data_cells: resd 1
ux_queue_cells: resd 1
ux_stack_offset: resd 1
ux_data_offset: resd 1
ux_pragma_seed_enabled: resd 1
ux_pragma_seed_value: resd 1
ux_pragma_arge_json: resd 1
ux_pragma_arge_interpreter: resd 1
ux_pragma_arge_step: resd 1
ux_pragma_arge_trace: resd 1
ux_pragma_arge_watch: resd 1
section .text
uxm_entry:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    mov dword [ux_cell_bits], CELL_BITS
    mov dword [ux_cell_bytes], CELL_BYTES
    mov dword [ux_tape_cells], TAPE_CELLS
    mov dword [ux_stack_cells], STACK_CELLS
    mov dword [ux_data_cells], DATA_CELLS
    mov dword [ux_queue_cells], QUEUE_CELLS
    mov dword [ux_stack_offset], STACK_OFFSET
    mov dword [ux_data_offset], DATA_OFFSET
    mov dword [ux_pragma_seed_enabled], 0
    mov dword [ux_pragma_seed_value], 1
    mov dword [ux_pragma_arge_json], 0
    mov dword [ux_pragma_arge_interpreter], 0
    mov dword [ux_pragma_arge_step], 0
    mov dword [ux_pragma_arge_trace], 0
    mov dword [ux_pragma_arge_watch], 0
    lea r12, [ux_mem]
    xor rbx, rbx
    lea r13, [ux_mem + STACK_OFFSET]
    xor r14, r14
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov byte [ux_status], 0
    mov word [ux_flags], 0
    or word [ux_flags], FLAG_BND
    mov dword [ux_mem + 74128] , 77
    mov dword [ux_mem + 74132] , 1
    mov dword [ux_mem + 74136] , 2
    mov dword [ux_mem + 74140] , 0
    mov dword [ux_mem + 74144] , 0
    mov dword [ux_mem + 74148] , 2
    mov dword [ux_mem + 74152] , 2
    mov dword [ux_mem + 74156] , 0
    mov dword [ux_mem + 74160] , 1
    mov dword [ux_mem + 74164] , 16
    mov dword [ux_mem + 74168] , 4
    mov dword [ux_mem + 74172] , 20
    mov dword [ux_mem + 74176] , 2
    mov dword [ux_mem + 74180] , 1
    mov dword [ux_mem + 74184] , 0
    mov dword [ux_mem + 74188] , 0
    mov dword [ux_mem + 74192] , 1
    mov dword [ux_mem + 74196] , 0
    mov dword [ux_mem + 74200] , 0
    mov dword [ux_mem + 74204] , 1
    ; >
    inc rbx
    cmp rbx, TAPE_CELLS
    jae __ux_err_ptr
    ; >
    inc rbx
    cmp rbx, TAPE_CELLS
    jae __ux_err_ptr
    ; >
    inc rbx
    cmp rbx, TAPE_CELLS
    jae __ux_err_ptr
    ; >
    inc rbx
    cmp rbx, TAPE_CELLS
    jae __ux_err_ptr
    ; >
    inc rbx
    cmp rbx, TAPE_CELLS
    jae __ux_err_ptr
    ; 0(T-4)
    xor rax, rax
    mov r10, rbx
    sub r10, 4
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_1
    or dx, FLAG_Z
__ux_noz_1:
    test eax, 80000000h
    jz __ux_nos_1
    or dx, FLAG_S
__ux_nos_1:
    mov word [ux_flags], dx
    pop rax
    ; +k200 inherit (T-4)
    mov r10, rbx
    sub r10, 4
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 200
    mov r10, rbx
    sub r10, 4
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_2
    or dx, FLAG_Z
__ux_noz_2:
    test eax, 80000000h
    jz __ux_nos_2
    or dx, FLAG_S
__ux_nos_2:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-3)
    xor rax, rax
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_3
    or dx, FLAG_Z
__ux_noz_3:
    test eax, 80000000h
    jz __ux_nos_3
    or dx, FLAG_S
__ux_nos_3:
    mov word [ux_flags], dx
    pop rax
    ; +k100 inherit (T-3)
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 100
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_4
    or dx, FLAG_Z
__ux_noz_4:
    test eax, 80000000h
    jz __ux_nos_4
    or dx, FLAG_S
__ux_nos_4:
    mov word [ux_flags], dx
    pop rax
    ; @513
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 513
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; 0(T-3)
    xor rax, rax
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_5
    or dx, FLAG_Z
__ux_noz_5:
    test eax, 80000000h
    jz __ux_nos_5
    or dx, FLAG_S
__ux_nos_5:
    mov word [ux_flags], dx
    pop rax
    ; +k200 inherit (T-3)
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 200
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_6
    or dx, FLAG_Z
__ux_noz_6:
    test eax, 80000000h
    jz __ux_nos_6
    or dx, FLAG_S
__ux_nos_6:
    mov word [ux_flags], dx
    pop rax
    ; @166
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 166
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
__ux_ok_exit:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
__ux_err_ptr:
    mov byte [ux_status], 10
    mov ecx, 10
    call ux_runtime_error
    jmp __ux_ok_exit
__ux_err_stack_over:
    mov byte [ux_status], 11
    mov ecx, 11
    call ux_runtime_error
    jmp __ux_ok_exit
__ux_err_stack_under:
    mov byte [ux_status], 12
    mov ecx, 12
    call ux_runtime_error
    jmp __ux_ok_exit
__ux_err_data:
    mov byte [ux_status], 16
    mov ecx, 16
    call ux_runtime_error
    jmp __ux_ok_exit
