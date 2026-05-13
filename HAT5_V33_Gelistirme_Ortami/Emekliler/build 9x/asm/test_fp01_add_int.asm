; UX-MINIMA x64 V3.3-stage9 generated NASM
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
%define UXM_TOTAL_BYTES 53248
%define TAPE_BYTES 32768
%define STACK_BYTES 4096
%define DATA_BYTES 16384
%define QUEUE_BYTES 4096
%define STACK_OFFSET 32768
%define DATA_OFFSET 36864
%define TAPE_CELLS 32768
%define STACK_CELLS 4096
%define DATA_CELLS 16384
%define QUEUE_CELLS 4096
%define CELL_BITS 8
%define CELL_BYTES 1
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
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_1
    or dx, FLAG_Z
__ux_noz_1:
    test al, 80h
    jz __ux_nos_1
    or dx, FLAG_S
__ux_nos_1:
    mov word [ux_flags], dx
    pop rax
    ; +k100 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    movzx rax, byte [r11]
    add rax, 100
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_2
    or dx, FLAG_Z
__ux_noz_2:
    test al, 80h
    jz __ux_nos_2
    or dx, FLAG_S
__ux_nos_2:
    mov word [ux_flags], dx
    pop rax
    ; @200
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 200
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_3
    or dx, FLAG_Z
__ux_noz_3:
    test al, 80h
    jz __ux_nos_3
    or dx, FLAG_S
__ux_nos_3:
    mov word [ux_flags], dx
    pop rax
    ; +k140 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    movzx rax, byte [r11]
    add rax, 140
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_4
    or dx, FLAG_Z
__ux_noz_4:
    test al, 80h
    jz __ux_nos_4
    or dx, FLAG_S
__ux_nos_4:
    mov word [ux_flags], dx
    pop rax
    ; @200
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 200
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_5
    or dx, FLAG_Z
__ux_noz_5:
    test al, 80h
    jz __ux_nos_5
    or dx, FLAG_S
__ux_nos_5:
    mov word [ux_flags], dx
    pop rax
    ; +k180 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    movzx rax, byte [r11]
    add rax, 180
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_6
    or dx, FLAG_Z
__ux_noz_6:
    test al, 80h
    jz __ux_nos_6
    or dx, FLAG_S
__ux_nos_6:
    mov word [ux_flags], dx
    pop rax
    ; @200
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 200
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_7
    or dx, FLAG_Z
__ux_noz_7:
    test al, 80h
    jz __ux_nos_7
    or dx, FLAG_S
__ux_nos_7:
    mov word [ux_flags], dx
    pop rax
    ; +k100 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    movzx rax, byte [r11]
    add rax, 100
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_8
    or dx, FLAG_Z
__ux_noz_8:
    test al, 80h
    jz __ux_nos_8
    or dx, FLAG_S
__ux_nos_8:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-1)
    xor rax, rax
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_9
    or dx, FLAG_Z
__ux_noz_9:
    test al, 80h
    jz __ux_nos_9
    or dx, FLAG_S
__ux_nos_9:
    mov word [ux_flags], dx
    pop rax
    ; +k12 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    movzx rax, byte [r11]
    add rax, 12
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_10
    or dx, FLAG_Z
__ux_noz_10:
    test al, 80h
    jz __ux_nos_10
    or dx, FLAG_S
__ux_nos_10:
    mov word [ux_flags], dx
    pop rax
    ; @220
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 220
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_11
    or dx, FLAG_Z
__ux_noz_11:
    test al, 80h
    jz __ux_nos_11
    or dx, FLAG_S
__ux_nos_11:
    mov word [ux_flags], dx
    pop rax
    ; +k140 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    movzx rax, byte [r11]
    add rax, 140
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_12
    or dx, FLAG_Z
__ux_noz_12:
    test al, 80h
    jz __ux_nos_12
    or dx, FLAG_S
__ux_nos_12:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-1)
    xor rax, rax
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_13
    or dx, FLAG_Z
__ux_noz_13:
    test al, 80h
    jz __ux_nos_13
    or dx, FLAG_S
__ux_nos_13:
    mov word [ux_flags], dx
    pop rax
    ; +k34 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    movzx rax, byte [r11]
    add rax, 34
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_14
    or dx, FLAG_Z
__ux_noz_14:
    test al, 80h
    jz __ux_nos_14
    or dx, FLAG_S
__ux_nos_14:
    mov word [ux_flags], dx
    pop rax
    ; @220
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 220
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; 0(T-2)
    xor rax, rax
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_15
    or dx, FLAG_Z
__ux_noz_15:
    test al, 80h
    jz __ux_nos_15
    or dx, FLAG_S
__ux_nos_15:
    mov word [ux_flags], dx
    pop rax
    ; +k180 inherit (T-2)
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    movzx rax, byte [r11]
    add rax, 180
    mov r10, rbx
    sub r10, 2
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_16
    or dx, FLAG_Z
__ux_noz_16:
    test al, 80h
    jz __ux_nos_16
    or dx, FLAG_S
__ux_nos_16:
    mov word [ux_flags], dx
    pop rax
    ; 0(T-1)
    xor rax, rax
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_17
    or dx, FLAG_Z
__ux_noz_17:
    test al, 80h
    jz __ux_nos_17
    or dx, FLAG_S
__ux_nos_17:
    mov word [ux_flags], dx
    pop rax
    ; +k100 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    movzx rax, byte [r11]
    add rax, 100
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_18
    or dx, FLAG_Z
__ux_noz_18:
    test al, 80h
    jz __ux_nos_18
    or dx, FLAG_S
__ux_nos_18:
    mov word [ux_flags], dx
    pop rax
    ; 0(T)
    xor rax, rax
    lea r11, [r12 + rbx]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_19
    or dx, FLAG_Z
__ux_noz_19:
    test al, 80h
    jz __ux_nos_19
    or dx, FLAG_S
__ux_nos_19:
    mov word [ux_flags], dx
    pop rax
    ; +k140 inherit (T)
    lea r11, [r12 + rbx]
    movzx rax, byte [r11]
    add rax, 140
    lea r11, [r12 + rbx]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_20
    or dx, FLAG_Z
__ux_noz_20:
    test al, 80h
    jz __ux_nos_20
    or dx, FLAG_S
__ux_nos_20:
    mov word [ux_flags], dx
    pop rax
    ; @210
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 210
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
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_21
    or dx, FLAG_Z
__ux_noz_21:
    test al, 80h
    jz __ux_nos_21
    or dx, FLAG_S
__ux_nos_21:
    mov word [ux_flags], dx
    pop rax
    ; +k180 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    movzx rax, byte [r11]
    add rax, 180
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_22
    or dx, FLAG_Z
__ux_noz_22:
    test al, 80h
    jz __ux_nos_22
    or dx, FLAG_S
__ux_nos_22:
    mov word [ux_flags], dx
    pop rax
    ; @223
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 223
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
