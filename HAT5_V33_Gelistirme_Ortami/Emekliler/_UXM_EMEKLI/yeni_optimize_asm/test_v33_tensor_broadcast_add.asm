; UX-MINIMA x64 V3.3-stage12 generated NASM
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
    ; +k1600 inherit (T-4)
    mov r10, rbx
    sub r10, 4
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1600
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
    ; +k1 inherit (T-3)
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1
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
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
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
    ; +k2 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 2
    mov r10, rbx
    sub r10, 2
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
    ; 0(T-1)
    xor rax, rax
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_7
    or dx, FLAG_Z
__ux_noz_7:
    test eax, 80000000h
    jz __ux_nos_7
    or dx, FLAG_S
__ux_nos_7:
    mov word [ux_flags], dx
    pop rax
    ; +k3 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 3
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_8
    or dx, FLAG_Z
__ux_noz_8:
    test eax, 80000000h
    jz __ux_nos_8
    or dx, FLAG_S
__ux_nos_8:
    mov word [ux_flags], dx
    pop rax
    ; @560
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 560
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
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
    jne __ux_noz_9
    or dx, FLAG_Z
__ux_noz_9:
    test eax, 80000000h
    jz __ux_nos_9
    or dx, FLAG_S
__ux_nos_9:
    mov word [ux_flags], dx
    pop rax
    ; +k1600 inherit (T-4)
    mov r10, rbx
    sub r10, 4
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1600
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
    jne __ux_noz_10
    or dx, FLAG_Z
__ux_noz_10:
    test eax, 80000000h
    jz __ux_nos_10
    or dx, FLAG_S
__ux_nos_10:
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
    jne __ux_noz_11
    or dx, FLAG_Z
__ux_noz_11:
    test eax, 80000000h
    jz __ux_nos_11
    or dx, FLAG_S
__ux_nos_11:
    mov word [ux_flags], dx
    pop rax
    ; +k0 inherit (T-3)
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 0
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
    jne __ux_noz_12
    or dx, FLAG_Z
__ux_noz_12:
    test eax, 80000000h
    jz __ux_nos_12
    or dx, FLAG_S
__ux_nos_12:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_13
    or dx, FLAG_Z
__ux_noz_13:
    test eax, 80000000h
    jz __ux_nos_13
    or dx, FLAG_S
__ux_nos_13:
    mov word [ux_flags], dx
    pop rax
    ; +k0 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 0
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_14
    or dx, FLAG_Z
__ux_noz_14:
    test eax, 80000000h
    jz __ux_nos_14
    or dx, FLAG_S
__ux_nos_14:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-1)
    xor rax, rax
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_15
    or dx, FLAG_Z
__ux_noz_15:
    test eax, 80000000h
    jz __ux_nos_15
    or dx, FLAG_S
__ux_nos_15:
    mov word [ux_flags], dx
    pop rax
    ; +k0 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 0
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_16
    or dx, FLAG_Z
__ux_noz_16:
    test eax, 80000000h
    jz __ux_nos_16
    or dx, FLAG_S
__ux_nos_16:
    mov word [ux_flags], dx
    pop rax
    ; 0(T)
    xor rax, rax
    lea r11, [r12 + rbx*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_17
    or dx, FLAG_Z
__ux_noz_17:
    test eax, 80000000h
    jz __ux_nos_17
    or dx, FLAG_S
__ux_nos_17:
    mov word [ux_flags], dx
    pop rax
    ; +k1 inherit (T)
    lea r11, [r12 + rbx*4]
    mov eax, dword [r11]
    add rax, 1
    lea r11, [r12 + rbx*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_18
    or dx, FLAG_Z
__ux_noz_18:
    test eax, 80000000h
    jz __ux_nos_18
    or dx, FLAG_S
__ux_nos_18:
    mov word [ux_flags], dx
    pop rax
    ; @561
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 561
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
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
    jne __ux_noz_19
    or dx, FLAG_Z
__ux_noz_19:
    test eax, 80000000h
    jz __ux_nos_19
    or dx, FLAG_S
__ux_nos_19:
    mov word [ux_flags], dx
    pop rax
    ; +k1600 inherit (T-4)
    mov r10, rbx
    sub r10, 4
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1600
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
    jne __ux_noz_20
    or dx, FLAG_Z
__ux_noz_20:
    test eax, 80000000h
    jz __ux_nos_20
    or dx, FLAG_S
__ux_nos_20:
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
    jne __ux_noz_21
    or dx, FLAG_Z
__ux_noz_21:
    test eax, 80000000h
    jz __ux_nos_21
    or dx, FLAG_S
__ux_nos_21:
    mov word [ux_flags], dx
    pop rax
    ; +k0 inherit (T-3)
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 0
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
    jne __ux_noz_22
    or dx, FLAG_Z
__ux_noz_22:
    test eax, 80000000h
    jz __ux_nos_22
    or dx, FLAG_S
__ux_nos_22:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_23
    or dx, FLAG_Z
__ux_noz_23:
    test eax, 80000000h
    jz __ux_nos_23
    or dx, FLAG_S
__ux_nos_23:
    mov word [ux_flags], dx
    pop rax
    ; +k1 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_24
    or dx, FLAG_Z
__ux_noz_24:
    test eax, 80000000h
    jz __ux_nos_24
    or dx, FLAG_S
__ux_nos_24:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-1)
    xor rax, rax
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_25
    or dx, FLAG_Z
__ux_noz_25:
    test eax, 80000000h
    jz __ux_nos_25
    or dx, FLAG_S
__ux_nos_25:
    mov word [ux_flags], dx
    pop rax
    ; +k2 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 2
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_26
    or dx, FLAG_Z
__ux_noz_26:
    test eax, 80000000h
    jz __ux_nos_26
    or dx, FLAG_S
__ux_nos_26:
    mov word [ux_flags], dx
    pop rax
    ; 0(T)
    xor rax, rax
    lea r11, [r12 + rbx*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_27
    or dx, FLAG_Z
__ux_noz_27:
    test eax, 80000000h
    jz __ux_nos_27
    or dx, FLAG_S
__ux_nos_27:
    mov word [ux_flags], dx
    pop rax
    ; +k5 inherit (T)
    lea r11, [r12 + rbx*4]
    mov eax, dword [r11]
    add rax, 5
    lea r11, [r12 + rbx*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_28
    or dx, FLAG_Z
__ux_noz_28:
    test eax, 80000000h
    jz __ux_nos_28
    or dx, FLAG_S
__ux_nos_28:
    mov word [ux_flags], dx
    pop rax
    ; @561
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 561
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
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
    jne __ux_noz_29
    or dx, FLAG_Z
__ux_noz_29:
    test eax, 80000000h
    jz __ux_nos_29
    or dx, FLAG_S
__ux_nos_29:
    mov word [ux_flags], dx
    pop rax
    ; +k1700 inherit (T-4)
    mov r10, rbx
    sub r10, 4
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1700
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
    jne __ux_noz_30
    or dx, FLAG_Z
__ux_noz_30:
    test eax, 80000000h
    jz __ux_nos_30
    or dx, FLAG_S
__ux_nos_30:
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
    jne __ux_noz_31
    or dx, FLAG_Z
__ux_noz_31:
    test eax, 80000000h
    jz __ux_nos_31
    or dx, FLAG_S
__ux_nos_31:
    mov word [ux_flags], dx
    pop rax
    ; +k2 inherit (T-3)
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 2
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
    jne __ux_noz_32
    or dx, FLAG_Z
__ux_noz_32:
    test eax, 80000000h
    jz __ux_nos_32
    or dx, FLAG_S
__ux_nos_32:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_33
    or dx, FLAG_Z
__ux_noz_33:
    test eax, 80000000h
    jz __ux_nos_33
    or dx, FLAG_S
__ux_nos_33:
    mov word [ux_flags], dx
    pop rax
    ; +k1 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_34
    or dx, FLAG_Z
__ux_noz_34:
    test eax, 80000000h
    jz __ux_nos_34
    or dx, FLAG_S
__ux_nos_34:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-1)
    xor rax, rax
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_35
    or dx, FLAG_Z
__ux_noz_35:
    test eax, 80000000h
    jz __ux_nos_35
    or dx, FLAG_S
__ux_nos_35:
    mov word [ux_flags], dx
    pop rax
    ; +k3 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 3
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_36
    or dx, FLAG_Z
__ux_noz_36:
    test eax, 80000000h
    jz __ux_nos_36
    or dx, FLAG_S
__ux_nos_36:
    mov word [ux_flags], dx
    pop rax
    ; @560
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 560
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
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
    jne __ux_noz_37
    or dx, FLAG_Z
__ux_noz_37:
    test eax, 80000000h
    jz __ux_nos_37
    or dx, FLAG_S
__ux_nos_37:
    mov word [ux_flags], dx
    pop rax
    ; +k1700 inherit (T-4)
    mov r10, rbx
    sub r10, 4
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1700
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
    jne __ux_noz_38
    or dx, FLAG_Z
__ux_noz_38:
    test eax, 80000000h
    jz __ux_nos_38
    or dx, FLAG_S
__ux_nos_38:
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
    jne __ux_noz_39
    or dx, FLAG_Z
__ux_noz_39:
    test eax, 80000000h
    jz __ux_nos_39
    or dx, FLAG_S
__ux_nos_39:
    mov word [ux_flags], dx
    pop rax
    ; +k0 inherit (T-3)
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 0
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
    jne __ux_noz_40
    or dx, FLAG_Z
__ux_noz_40:
    test eax, 80000000h
    jz __ux_nos_40
    or dx, FLAG_S
__ux_nos_40:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_41
    or dx, FLAG_Z
__ux_noz_41:
    test eax, 80000000h
    jz __ux_nos_41
    or dx, FLAG_S
__ux_nos_41:
    mov word [ux_flags], dx
    pop rax
    ; +k0 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 0
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_42
    or dx, FLAG_Z
__ux_noz_42:
    test eax, 80000000h
    jz __ux_nos_42
    or dx, FLAG_S
__ux_nos_42:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-1)
    xor rax, rax
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_43
    or dx, FLAG_Z
__ux_noz_43:
    test eax, 80000000h
    jz __ux_nos_43
    or dx, FLAG_S
__ux_nos_43:
    mov word [ux_flags], dx
    pop rax
    ; +k0 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 0
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_44
    or dx, FLAG_Z
__ux_noz_44:
    test eax, 80000000h
    jz __ux_nos_44
    or dx, FLAG_S
__ux_nos_44:
    mov word [ux_flags], dx
    pop rax
    ; 0(T)
    xor rax, rax
    lea r11, [r12 + rbx*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_45
    or dx, FLAG_Z
__ux_noz_45:
    test eax, 80000000h
    jz __ux_nos_45
    or dx, FLAG_S
__ux_nos_45:
    mov word [ux_flags], dx
    pop rax
    ; +k10 inherit (T)
    lea r11, [r12 + rbx*4]
    mov eax, dword [r11]
    add rax, 10
    lea r11, [r12 + rbx*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_46
    or dx, FLAG_Z
__ux_noz_46:
    test eax, 80000000h
    jz __ux_nos_46
    or dx, FLAG_S
__ux_nos_46:
    mov word [ux_flags], dx
    pop rax
    ; @561
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 561
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
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
    jne __ux_noz_47
    or dx, FLAG_Z
__ux_noz_47:
    test eax, 80000000h
    jz __ux_nos_47
    or dx, FLAG_S
__ux_nos_47:
    mov word [ux_flags], dx
    pop rax
    ; +k1700 inherit (T-4)
    mov r10, rbx
    sub r10, 4
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1700
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
    jne __ux_noz_48
    or dx, FLAG_Z
__ux_noz_48:
    test eax, 80000000h
    jz __ux_nos_48
    or dx, FLAG_S
__ux_nos_48:
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
    jne __ux_noz_49
    or dx, FLAG_Z
__ux_noz_49:
    test eax, 80000000h
    jz __ux_nos_49
    or dx, FLAG_S
__ux_nos_49:
    mov word [ux_flags], dx
    pop rax
    ; +k1 inherit (T-3)
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1
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
    jne __ux_noz_50
    or dx, FLAG_Z
__ux_noz_50:
    test eax, 80000000h
    jz __ux_nos_50
    or dx, FLAG_S
__ux_nos_50:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_51
    or dx, FLAG_Z
__ux_noz_51:
    test eax, 80000000h
    jz __ux_nos_51
    or dx, FLAG_S
__ux_nos_51:
    mov word [ux_flags], dx
    pop rax
    ; +k0 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 0
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_52
    or dx, FLAG_Z
__ux_noz_52:
    test eax, 80000000h
    jz __ux_nos_52
    or dx, FLAG_S
__ux_nos_52:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-1)
    xor rax, rax
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_53
    or dx, FLAG_Z
__ux_noz_53:
    test eax, 80000000h
    jz __ux_nos_53
    or dx, FLAG_S
__ux_nos_53:
    mov word [ux_flags], dx
    pop rax
    ; +k2 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 2
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_54
    or dx, FLAG_Z
__ux_noz_54:
    test eax, 80000000h
    jz __ux_nos_54
    or dx, FLAG_S
__ux_nos_54:
    mov word [ux_flags], dx
    pop rax
    ; 0(T)
    xor rax, rax
    lea r11, [r12 + rbx*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_55
    or dx, FLAG_Z
__ux_noz_55:
    test eax, 80000000h
    jz __ux_nos_55
    or dx, FLAG_S
__ux_nos_55:
    mov word [ux_flags], dx
    pop rax
    ; +k20 inherit (T)
    lea r11, [r12 + rbx*4]
    mov eax, dword [r11]
    add rax, 20
    lea r11, [r12 + rbx*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_56
    or dx, FLAG_Z
__ux_noz_56:
    test eax, 80000000h
    jz __ux_nos_56
    or dx, FLAG_S
__ux_nos_56:
    mov word [ux_flags], dx
    pop rax
    ; @561
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 561
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
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
    jne __ux_noz_57
    or dx, FLAG_Z
__ux_noz_57:
    test eax, 80000000h
    jz __ux_nos_57
    or dx, FLAG_S
__ux_nos_57:
    mov word [ux_flags], dx
    pop rax
    ; +k60 inherit (T-4)
    mov r10, rbx
    sub r10, 4
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 60
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
    jne __ux_noz_58
    or dx, FLAG_Z
__ux_noz_58:
    test eax, 80000000h
    jz __ux_nos_58
    or dx, FLAG_S
__ux_nos_58:
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
    jne __ux_noz_59
    or dx, FLAG_Z
__ux_noz_59:
    test eax, 80000000h
    jz __ux_nos_59
    or dx, FLAG_S
__ux_nos_59:
    mov word [ux_flags], dx
    pop rax
    ; +k1600 inherit (T-3)
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1600
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
    jne __ux_noz_60
    or dx, FLAG_Z
__ux_noz_60:
    test eax, 80000000h
    jz __ux_nos_60
    or dx, FLAG_S
__ux_nos_60:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_61
    or dx, FLAG_Z
__ux_noz_61:
    test eax, 80000000h
    jz __ux_nos_61
    or dx, FLAG_S
__ux_nos_61:
    mov word [ux_flags], dx
    pop rax
    ; +k1700 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1700
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_62
    or dx, FLAG_Z
__ux_noz_62:
    test eax, 80000000h
    jz __ux_nos_62
    or dx, FLAG_S
__ux_nos_62:
    mov word [ux_flags], dx
    pop rax
    ; @582
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 582
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; 0(T-1)
    xor rax, rax
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_63
    or dx, FLAG_Z
__ux_noz_63:
    test eax, 80000000h
    jz __ux_nos_63
    or dx, FLAG_S
__ux_nos_63:
    mov word [ux_flags], dx
    pop rax
    ; +k61 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 61
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_64
    or dx, FLAG_Z
__ux_noz_64:
    test eax, 80000000h
    jz __ux_nos_64
    or dx, FLAG_S
__ux_nos_64:
    mov word [ux_flags], dx
    pop rax
    ; @95
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 95
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; @61
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 61
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; 0(T-1)
    xor rax, rax
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_65
    or dx, FLAG_Z
__ux_noz_65:
    test eax, 80000000h
    jz __ux_nos_65
    or dx, FLAG_S
__ux_nos_65:
    mov word [ux_flags], dx
    pop rax
    ; +k62 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 62
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_66
    or dx, FLAG_Z
__ux_noz_66:
    test eax, 80000000h
    jz __ux_nos_66
    or dx, FLAG_S
__ux_nos_66:
    mov word [ux_flags], dx
    pop rax
    ; @95
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 95
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; @61
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 61
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; 0(T-1)
    xor rax, rax
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_67
    or dx, FLAG_Z
__ux_noz_67:
    test eax, 80000000h
    jz __ux_nos_67
    or dx, FLAG_S
__ux_nos_67:
    mov word [ux_flags], dx
    pop rax
    ; +k63 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 63
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_68
    or dx, FLAG_Z
__ux_noz_68:
    test eax, 80000000h
    jz __ux_nos_68
    or dx, FLAG_S
__ux_nos_68:
    mov word [ux_flags], dx
    pop rax
    ; @95
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 95
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; @61
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 61
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; 0(T-1)
    xor rax, rax
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_69
    or dx, FLAG_Z
__ux_noz_69:
    test eax, 80000000h
    jz __ux_nos_69
    or dx, FLAG_S
__ux_nos_69:
    mov word [ux_flags], dx
    pop rax
    ; +k64 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 64
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_70
    or dx, FLAG_Z
__ux_noz_70:
    test eax, 80000000h
    jz __ux_nos_70
    or dx, FLAG_S
__ux_nos_70:
    mov word [ux_flags], dx
    pop rax
    ; @95
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 95
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; @61
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 61
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
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
    jne __ux_noz_71
    or dx, FLAG_Z
__ux_noz_71:
    test eax, 80000000h
    jz __ux_nos_71
    or dx, FLAG_S
__ux_nos_71:
    mov word [ux_flags], dx
    pop rax
    ; +k1800 inherit (T-4)
    mov r10, rbx
    sub r10, 4
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1800
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
    jne __ux_noz_72
    or dx, FLAG_Z
__ux_noz_72:
    test eax, 80000000h
    jz __ux_nos_72
    or dx, FLAG_S
__ux_nos_72:
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
    jne __ux_noz_73
    or dx, FLAG_Z
__ux_noz_73:
    test eax, 80000000h
    jz __ux_nos_73
    or dx, FLAG_S
__ux_nos_73:
    mov word [ux_flags], dx
    pop rax
    ; +k1600 inherit (T-3)
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1600
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
    jne __ux_noz_74
    or dx, FLAG_Z
__ux_noz_74:
    test eax, 80000000h
    jz __ux_nos_74
    or dx, FLAG_S
__ux_nos_74:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_75
    or dx, FLAG_Z
__ux_noz_75:
    test eax, 80000000h
    jz __ux_nos_75
    or dx, FLAG_S
__ux_nos_75:
    mov word [ux_flags], dx
    pop rax
    ; +k1700 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1700
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_76
    or dx, FLAG_Z
__ux_noz_76:
    test eax, 80000000h
    jz __ux_nos_76
    or dx, FLAG_S
__ux_nos_76:
    mov word [ux_flags], dx
    pop rax
    ; @581
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 581
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
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
    jne __ux_noz_77
    or dx, FLAG_Z
__ux_noz_77:
    test eax, 80000000h
    jz __ux_nos_77
    or dx, FLAG_S
__ux_nos_77:
    mov word [ux_flags], dx
    pop rax
    ; +k1800 inherit (T-4)
    mov r10, rbx
    sub r10, 4
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1800
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
    jne __ux_noz_78
    or dx, FLAG_Z
__ux_noz_78:
    test eax, 80000000h
    jz __ux_nos_78
    or dx, FLAG_S
__ux_nos_78:
    mov word [ux_flags], dx
    pop rax
    ; @573
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 573
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; @61
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 61
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
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
    jne __ux_noz_79
    or dx, FLAG_Z
__ux_noz_79:
    test eax, 80000000h
    jz __ux_nos_79
    or dx, FLAG_S
__ux_nos_79:
    mov word [ux_flags], dx
    pop rax
    ; +k1800 inherit (T-4)
    mov r10, rbx
    sub r10, 4
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1800
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
    jne __ux_noz_80
    or dx, FLAG_Z
__ux_noz_80:
    test eax, 80000000h
    jz __ux_nos_80
    or dx, FLAG_S
__ux_nos_80:
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
    jne __ux_noz_81
    or dx, FLAG_Z
__ux_noz_81:
    test eax, 80000000h
    jz __ux_nos_81
    or dx, FLAG_S
__ux_nos_81:
    mov word [ux_flags], dx
    pop rax
    ; +k1 inherit (T-3)
    mov r10, rbx
    sub r10, 3
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1
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
    jne __ux_noz_82
    or dx, FLAG_Z
__ux_noz_82:
    test eax, 80000000h
    jz __ux_nos_82
    or dx, FLAG_S
__ux_nos_82:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_83
    or dx, FLAG_Z
__ux_noz_83:
    test eax, 80000000h
    jz __ux_nos_83
    or dx, FLAG_S
__ux_nos_83:
    mov word [ux_flags], dx
    pop rax
    ; +k1 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 1
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_84
    or dx, FLAG_Z
__ux_noz_84:
    test eax, 80000000h
    jz __ux_nos_84
    or dx, FLAG_S
__ux_nos_84:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-1)
    xor rax, rax
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_85
    or dx, FLAG_Z
__ux_noz_85:
    test eax, 80000000h
    jz __ux_nos_85
    or dx, FLAG_S
__ux_nos_85:
    mov word [ux_flags], dx
    pop rax
    ; +k2 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov eax, dword [r11]
    add rax, 2
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10*4]
    mov dword [r11], eax
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_86
    or dx, FLAG_Z
__ux_noz_86:
    test eax, 80000000h
    jz __ux_nos_86
    or dx, FLAG_S
__ux_nos_86:
    mov word [ux_flags], dx
    pop rax
    ; @562
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 562
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; @61
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 61
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