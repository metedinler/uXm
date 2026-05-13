; UX-MINIMA x64 V3.3-stage2 generated NASM
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
    ; data string initializers
    mov byte [ux_mem + 36864], 52
    mov byte [ux_mem + 36865], 32
    mov byte [ux_mem + 36866], 78
    mov byte [ux_mem + 36867], 69
    mov byte [ux_mem + 36868], 85
    mov byte [ux_mem + 36869], 82
    mov byte [ux_mem + 36870], 79
    mov byte [ux_mem + 36871], 78
    mov byte [ux_mem + 36872], 32
    mov byte [ux_mem + 36873], 78
    mov byte [ux_mem + 36874], 78
    mov byte [ux_mem + 36875], 32
    mov byte [ux_mem + 36876], 84
    mov byte [ux_mem + 36877], 69
    mov byte [ux_mem + 36878], 83
    mov byte [ux_mem + 36879], 84
    mov byte [ux_mem + 36880], 10
    mov byte [ux_mem + 36881], 0
    mov byte [ux_mem + 36896], 88
    mov byte [ux_mem + 36897], 49
    mov byte [ux_mem + 36898], 61
    mov byte [ux_mem + 36899], 0
    mov byte [ux_mem + 36904], 32
    mov byte [ux_mem + 36905], 88
    mov byte [ux_mem + 36906], 50
    mov byte [ux_mem + 36907], 61
    mov byte [ux_mem + 36908], 0
    mov byte [ux_mem + 36912], 10
    mov byte [ux_mem + 36913], 0
    mov byte [ux_mem + 36920], 78
    mov byte [ux_mem + 36921], 49
    mov byte [ux_mem + 36922], 61
    mov byte [ux_mem + 36923], 0
    mov byte [ux_mem + 36928], 32
    mov byte [ux_mem + 36929], 78
    mov byte [ux_mem + 36930], 50
    mov byte [ux_mem + 36931], 61
    mov byte [ux_mem + 36932], 0
    mov byte [ux_mem + 36936], 32
    mov byte [ux_mem + 36937], 78
    mov byte [ux_mem + 36938], 51
    mov byte [ux_mem + 36939], 61
    mov byte [ux_mem + 36940], 0
    mov byte [ux_mem + 36944], 32
    mov byte [ux_mem + 36945], 79
    mov byte [ux_mem + 36946], 85
    mov byte [ux_mem + 36947], 84
    mov byte [ux_mem + 36948], 61
    mov byte [ux_mem + 36949], 0
    ; p1
    mov ecx, 0
    mov edx, CELL_BITS
    call ux_print_data_string
    ; 0(T:0)
    xor rax, rax
    lea r11, [r12 + 0]
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
    ; +k1 inherit (T:0)
    lea r11, [r12 + 0]
    movzx rax, byte [r11]
    add rax, 1
    lea r11, [r12 + 0]
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
    ; 0(T:1)
    xor rax, rax
    lea r11, [r12 + 1]
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
    ; >
    inc rbx
    cmp rbx, TAPE_CELLS
    jae __ux_err_ptr
    ; >
    inc rbx
    cmp rbx, TAPE_CELLS
    jae __ux_err_ptr
    ; p2
    mov ecx, 32
    mov edx, CELL_BITS
    call ux_print_data_string
    ; $(T:0)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 0]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:23)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 23]
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
    ; @61
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 61
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; p3
    mov ecx, 40
    mov edx, CELL_BITS
    call ux_print_data_string
    ; $(T:1)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 1]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:23)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 23]
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
    ; @61
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 61
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; p4
    mov ecx, 48
    mov edx, CELL_BITS
    call ux_print_data_string
    ; $(T:0)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 0]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:20)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 20]
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
    ; $(T:1)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 1]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:21)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 21]
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
    ; @20
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 20
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; 0(T:11)
    xor rax, rax
    lea r11, [r12 + 11]
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
    ; $(T:23)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 23]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; !(T:11)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx r15, byte [r13 + r14]
    lea r11, [r12 + 11]
    movzx rax, byte [r11]
    cmp r15, rax
    seta al
    movzx rax, al
    lea r11, [r12 + 11]
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
    ; $(T:11)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 11]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:12)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 12]
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
    ; $(T:0)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 0]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:20)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 20]
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
    ; $(T:1)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 1]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:21)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 21]
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
    ; @20
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 20
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; 0(T:11)
    xor rax, rax
    lea r11, [r12 + 11]
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
    ; +k1 inherit (T:11)
    lea r11, [r12 + 11]
    movzx rax, byte [r11]
    add rax, 1
    lea r11, [r12 + 11]
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
    ; $(T:23)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 23]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; !(T:11)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx r15, byte [r13 + r14]
    lea r11, [r12 + 11]
    movzx rax, byte [r11]
    cmp r15, rax
    seta al
    movzx rax, al
    lea r11, [r12 + 11]
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
    ; $(T:11)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 11]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:13)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 13]
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
    ; 0(T:11)
    xor rax, rax
    lea r11, [r12 + 11]
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
    ; $(T:0)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 0]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; !(T:11)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx r15, byte [r13 + r14]
    lea r11, [r12 + 11]
    movzx rax, byte [r11]
    cmp r15, rax
    seta al
    movzx rax, al
    lea r11, [r12 + 11]
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
    ; $(T:11)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 11]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:14)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 14]
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
    ; $(T:12)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 12]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:20)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 20]
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
    ; $(T:13)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 13]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:21)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 21]
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
    ; @20
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 20
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; $(T:23)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 23]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:20)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 20]
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
    ; $(T:14)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 14]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:21)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 21]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_23
    or dx, FLAG_Z
__ux_noz_23:
    test al, 80h
    jz __ux_nos_23
    or dx, FLAG_S
__ux_nos_23:
    mov word [ux_flags], dx
    pop rax
    ; @20
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 20
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; 0(T:11)
    xor rax, rax
    lea r11, [r12 + 11]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_24
    or dx, FLAG_Z
__ux_noz_24:
    test al, 80h
    jz __ux_nos_24
    or dx, FLAG_S
__ux_nos_24:
    mov word [ux_flags], dx
    pop rax
    ; +k1 inherit (T:11)
    lea r11, [r12 + 11]
    movzx rax, byte [r11]
    add rax, 1
    lea r11, [r12 + 11]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_25
    or dx, FLAG_Z
__ux_noz_25:
    test al, 80h
    jz __ux_nos_25
    or dx, FLAG_S
__ux_nos_25:
    mov word [ux_flags], dx
    pop rax
    ; $(T:23)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 23]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; !(T:11)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx r15, byte [r13 + r14]
    lea r11, [r12 + 11]
    movzx rax, byte [r11]
    cmp r15, rax
    seta al
    movzx rax, al
    lea r11, [r12 + 11]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_26
    or dx, FLAG_Z
__ux_noz_26:
    test al, 80h
    jz __ux_nos_26
    or dx, FLAG_S
__ux_nos_26:
    mov word [ux_flags], dx
    pop rax
    ; $(T:11)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 11]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:15)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 15]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_27
    or dx, FLAG_Z
__ux_noz_27:
    test al, 80h
    jz __ux_nos_27
    or dx, FLAG_S
__ux_nos_27:
    mov word [ux_flags], dx
    pop rax
    ; p5
    mov ecx, 56
    mov edx, CELL_BITS
    call ux_print_data_string
    ; $(T:12)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 12]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:23)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 23]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_28
    or dx, FLAG_Z
__ux_noz_28:
    test al, 80h
    jz __ux_nos_28
    or dx, FLAG_S
__ux_nos_28:
    mov word [ux_flags], dx
    pop rax
    ; @61
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 61
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; p6
    mov ecx, 64
    mov edx, CELL_BITS
    call ux_print_data_string
    ; $(T:13)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 13]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:23)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 23]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_29
    or dx, FLAG_Z
__ux_noz_29:
    test al, 80h
    jz __ux_nos_29
    or dx, FLAG_S
__ux_nos_29:
    mov word [ux_flags], dx
    pop rax
    ; @61
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 61
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; p7
    mov ecx, 72
    mov edx, CELL_BITS
    call ux_print_data_string
    ; $(T:14)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 14]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:23)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 23]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_30
    or dx, FLAG_Z
__ux_noz_30:
    test al, 80h
    jz __ux_nos_30
    or dx, FLAG_S
__ux_nos_30:
    mov word [ux_flags], dx
    pop rax
    ; @61
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 61
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; p8
    mov ecx, 80
    mov edx, CELL_BITS
    call ux_print_data_string
    ; $(T:15)
    cmp r14, STACK_CELLS
    jae __ux_err_stack_over
    lea r11, [r12 + 15]
    movzx rax, byte [r11]
    mov byte [r13 + r14], al
    inc r14
    ; %(T:23)
    cmp r14, 0
    je __ux_err_stack_under
    dec r14
    movzx rax, byte [r13 + r14]
    lea r11, [r12 + 23]
    mov byte [r11], al
    push rax
    mov dx, word [ux_flags]
    and dx, 0FFF0h
    cmp rax, 0
    jne __ux_noz_31
    or dx, FLAG_Z
__ux_noz_31:
    test al, 80h
    jz __ux_nos_31
    or dx, FLAG_S
__ux_nos_31:
    mov word [ux_flags], dx
    pop rax
    ; @61
    mov qword [ux_ptr], rbx
    mov qword [ux_sp], r14
    mov ecx, 61
    lea rdx, [ux_mem]
    call ux_meta_call_ex
    mov rbx, qword [ux_ptr]
    mov r14, qword [ux_sp]
    ; p4
    mov ecx, 48
    mov edx, CELL_BITS
    call ux_print_data_string
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
