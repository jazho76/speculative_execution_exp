# Speculative Execution Exploit

This is an experiment demonstrating how speculative execution can be used to leak data via microarchitectural side effects, using the CPU cache as a side-channel. The experiment is scoped to user-space memory to keep it reproducible and predictable.

## What this experiment demonstrates

- Transient execution of instructions past a faulting access before the fault is resolved architecturally.
- Using a Flush+Reload oracle buffer to encode and later recover byte values from CPU cache timing.
- Reliable byte-wise extraction via timing measurements.
- Noise reduction using repeated sampling and statistical decoding.

## High-Level Overview

1. Secret source

- A fake secret buffer is allocated in user space

This avoids kernel-mapping issues and keeps the experiment deterministic.

2. Communication buffer

- A shared communication buffer of 256 pages (256 × 4096 bytes) is used.
- One page per possible byte value

3. Transient gadget

The core gadget in in speculative_exploit.s:

- Reads a byte from the target address
- Uses that byte to index into the communication buffer
- Touches a specific CPU cache line transiently
- Eventually faults, but leaves cache state behind

4. Side-channel recovery

- All pages from communication buffer are flushed with clflush
- After the fault, reload times are measured
- The cached page will determine the leaked byte value

5. Noise handling

- Repeated sampling
- Histogram-based decoding
- Pseudo-random probing order to avoid prefetching

## Speculative Gadget

```asm
    # rdi = target address to leak
    # rsi = communication buffer base address
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
```

During speculative execution, the value loaded from the target address is used as an index into the communication buffer. Because the buffer is laid out as 256 page-sized regions, accessing `comm_buf[byte * 0x1000]` causes exactly one page corresponding to the secret byte to be loaded into the CPU cache. Although the faulting execution is later discarded architecturally, this cache state persists. After handling the fault, the program measures access latency to each page, the page that loads fastest reveals which value was accessed transiently, thereby leaking the secret byte through a microarchitectural side channel.

## Reference & Inspiration

[pwn.college Microarchitecture Exploitation Dojo](https://pwn.college/system-security/speculative-execution/)
