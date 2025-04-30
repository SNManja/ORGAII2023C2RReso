; /** defines bool y puntero **/
%define NULL 0
%define TRUE 1
%define FALSE 0

section .data

section .text

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

; FUNCIONES auxiliares que pueden llegar a necesitar:
extern malloc
extern free
extern str_concat

STRINGPROCLIST_FIRST equ 0
STRINGPROCLIST_LAST equ 8
STRINGPROCLIST_SIZE equ 16

STRINGPROCNODE_NEXT equ 0
STRINGPROCNODE_PREV equ 8
STRINGPROCNODE_TYPE equ 16
STRINGPROCNODE_HASH equ 24
STRINGPROCNODE_SIZE equ 32 ; ! Revisar  


string_proc_list_create_asm:
    push rbp; 
    mov rbp, rsp;

    mov rdi, STRINGPROCLIST_SIZE
    call malloc
    mov qword [rax+STRINGPROCLIST_FIRST], 0 
    mov qword [rax+STRINGPROCLIST_LAST], 0

    pop rbp;
    ret

string_proc_node_create_asm:
    push rbp
    mov rbp, rsp

    push r12
    push r13

    mov r12b, dil; de bytes, pasa el tipo
    mov r13, rsi
    mov rdi, STRINGPROCNODE_SIZE
    call malloc
    mov qword [rax+STRINGPROCNODE_NEXT], 0 
    mov qword [rax+STRINGPROCNODE_PREV], 0
    mov byte [rax+STRINGPROCNODE_TYPE], r12b
    mov qword [rax+STRINGPROCNODE_HASH], R13

    pop r12
    pop r13

    pop rbp
    ret

; void string_proc_list_add_node(string_proc_list* list, uint8_t type, char* hash)
string_proc_list_add_node_asm:
    push rbp
    mov rbp, rsp

    push r12 ; lista
    push r13 ; Nuevo nodo
    push r14 ; Viejo last 
    push r15

    mov r12, rdi

    mov rdi, rsi
    mov rsi, rdx
    call string_proc_node_create_asm
    ; No me preocupa perder el hash y el type una vez instanciado el nodo

    mov r13, rax

    ; * Aca tengo varios casos
    ; * -> Cuando la lista esta vacia. Con checkear si no hay first se que no hay last
    cmp qword [r12+STRINGPROCLIST_FIRST], 0
    jne .noEsCasoSinNodosEnLista

    mov [r12+STRINGPROCLIST_FIRST], r13
    mov [r12+STRINGPROCLIST_LAST], r13
    jmp .end

.noEsCasoSinNodosEnLista:
    ;* -> En este caso se que va a haber un first y un last, porque si hay first hay last
    ;* El last va a dejar de ser last, pero me va a servir su referencia para cambiarle el next al nuevo nodo y el prev del nuevo al viejo last
    mov r14, qword [r12+STRINGPROCLIST_LAST]
    
    ; ! Aca detona, como si no hubiera ningun last aunque haya first
    ; Esto tira gdb en $r12
    ;>>> x/4dg $r12
    ;   0x7fffffffddd8: 140737488347486 0 <- Este 0 seria el last

    mov qword [r14+STRINGPROCNODE_NEXT], r13
    mov qword [r13+STRINGPROCNODE_PREV], r14
    mov qword [r12+STRINGPROCLIST_LAST], r13

.end:
    pop r15
    pop r14
    pop r13
    pop r12

    pop rbp
    ret

; char* string_proc_list_concat(string_proc_list* list, uint8_t type , char* hash)
string_proc_list_concat_asm:
    push rbp
    mov rbp, rsp

    push r12 ; lista
    push r13 ; nodo curr
    push r14 ; tipo 
    push r15 ; hash general

    mov r12, rdi
    mov r14b, sil
    mov r15, rdx ; Hash pasado por param
    mov r13, [r12+STRINGPROCLIST_FIRST]
.loop:
    cmp r13, 0
    je .end
    
    cmp byte [r13 + STRINGPROCNODE_TYPE], r14b
    jne .continue

    mov rdi, [r13+ STRINGPROCNODE_HASH]
    mov rsi, r15
    call str_concat
    mov r15, rax

    mov r13, [r13+STRINGPROCNODE_NEXT]
    jmp .continue 

.continue:
    jmp .loop

.end:
    pop r15
    pop r14
    pop r13
    pop r12

    pop rbp
    ret