; UX-MINIMA x64 V3.1 generated NASM
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
global ux_stack_offset
global ux_data_offset
extern ux_putc
extern ux_getc
extern ux_print_data_string
extern ux_meta_call_ex
extern ux_runtime_error
%define UXM_TOTAL_BYTES 65536
%define TAPE_BYTES 32768
%define STACK_BYTES 8192
%define DATA_BYTES 24576
%define STACK_OFFSET 32768
%define DATA_OFFSET 40960
%define TAPE_CELLS 32768
%define STACK_CELLS 8192
%define DATA_CELLS 24576
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
ux_stack_offset: resd 1
ux_data_offset: resd 1
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
    mov dword [ux_stack_offset], STACK_OFFSET
    mov dword [ux_data_offset], DATA_OFFSET
    lea r12, [ux_mem]
    xor rbx, rbx
    lea r13, [ux_mem + STACK_OFFSET]
    xor r14, r14
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov byte [ux_status], 0
    mov word [ux_flags], 0
    or word [ux_flags], FLAG_BND
    ; data string initializers
    mov byte [ux_mem + 40960], 49
    mov byte [ux_mem + 40961], 50
    mov byte [ux_mem + 40962], 46
    mov byte [ux_mem + 40963], 51
    mov byte [ux_mem + 40964], 52
    mov byte [ux_mem + 40965], 0
    mov byte [ux_mem + 40980], 53
    mov byte [ux_mem + 40981], 46
    mov byte [ux_mem + 40982], 54
    mov byte [ux_mem + 40983], 0
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
    ; @221
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 221
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
    jne __ux_noz_10
    or dx, FLAG_Z
__ux_noz_10:
    test al, 80h
    jz __ux_nos_10
    or dx, FLAG_S
__ux_nos_10:
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
    jne __ux_noz_11
    or dx, FLAG_Z
__ux_noz_11:
    test al, 80h
    jz __ux_nos_11
    or dx, FLAG_S
__ux_nos_11:
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
    jne __ux_noz_12
    or dx, FLAG_Z
__ux_noz_12:
    test al, 80h
    jz __ux_nos_12
    or dx, FLAG_S
__ux_nos_12:
    mov word [ux_flags], dx
    pop rax
    ; +k20 inherit (T-1)
    mov r10, rbx
    sub r10, 1
    cmp r10, TAPE_CELLS
    jae __ux_err_ptr
    lea r11, [r12 + r10]
    movzx rax, byte [r11]
    add rax, 20
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
    ; @221
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 221
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
    jne __ux_noz_14
    or dx, FLAG_Z
__ux_noz_14:
    test al, 80h
    jz __ux_nos_14
    or dx, FLAG_S
__ux_nos_14:
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
    jne __ux_noz_15
    or dx, FLAG_Z
__ux_noz_15:
    test al, 80h
    jz __ux_nos_15
    or dx, FLAG_S
__ux_nos_15:
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
    jne __ux_noz_16
    or dx, FLAG_Z
__ux_noz_16:
    test al, 80h
    jz __ux_nos_16
    or dx, FLAG_S
__ux_nos_16:
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
    jne __ux_noz_17
    or dx, FLAG_Z
__ux_noz_17:
    test al, 80h
    jz __ux_nos_17
    or dx, FLAG_S
__ux_nos_17:
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
    jne __ux_noz_18
    or dx, FLAG_Z
__ux_noz_18:
    test al, 80h
    jz __ux_nos_18
    or dx, FLAG_S
__ux_nos_18:
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
    jne __ux_noz_19
    or dx, FLAG_Z
__ux_noz_19:
    test al, 80h
    jz __ux_nos_19
    or dx, FLAG_S
__ux_nos_19:
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
    jne __ux_noz_20
    or dx, FLAG_Z
__ux_noz_20:
    test al, 80h
    jz __ux_nos_20
    or dx, FLAG_S
__ux_nos_20:
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
    jne __ux_noz_21
    or dx, FLAG_Z
__ux_noz_21:
    test al, 80h
    jz __ux_nos_21
    or dx, FLAG_S
__ux_nos_21:
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
