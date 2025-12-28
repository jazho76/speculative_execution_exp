# Speculative Execution Exploit

This is a minimal proof-of-concept demonstrating how speculative execution can be used to leak data via microarchitectural side effects, using the CPU cache as a side channel. The PoC is scoped to user-space memory to keep it reproducible and educational.

## What this PoC demonstrates

- Speculative execution past a faulting instruction
- Encoding secret data into cache state using a Flush+Reload side channel
- Reliable byte-wise extraction via timing measurements
- Noise reduction using repeated sampling and statistical decoding

## High-Level Overview

1. Secret source

- A fake secret buffer is allocated in user space

This avoids kernel-mapping issues and keeps the PoC deterministic.

2. Encoding buffer

- A shared communication buffer of 256 pages (256 × 4096 bytes) is used.
- One page per possible byte value

3. Transient gadget

The core gadget in in speculative_exploit.s:

- Reads a byte from the target address
- Uses that byte to index into the encoding buffer
- Touches a specific cache line transiently
- Eventually faults, but leaves cache state behind

4. Side-channel recovery

- All pages are flushed with clflush
- After the fault, reload times are measured
- The cached page will determine the leaked byte value

5. Noise handling

- Repeated sampling
- Histogram-based decoding
- Pseudo-random probing order to avoid prefetching

## Speculative Gadget

```asm
    # rdi = target address to leak
    # rsi = encoding buffer base address
    xor rcx, rcx
    mov rbx, rsi

    # This is the first dependent group of
    # instructions. It's only purpose is to be
    # slow and cause the CPU to increase the
    # chance of speculatively execute the
    # next group of instructions.
    mov rax, 0x1337
    push rax
    fild qword ptr [rsp]
    fsqrt
    fistp qword ptr [rsp]
    pop rax
    mov rax, [rax]            # Intentional fault by dereferencing an invalid address

    # These instructions will never effectively
    # execute, but can be speculatively executed
    # as transient instructions while the CPU is
    # waiting for the slow dependent chain of
    # instructions above to complete.
    mov cl, byte ptr [rdi]    # Read one byte from target address to leak
    shl rcx, 12               # Makes it a page offset (byte * 0x1000)
    add rbx, rcx              # Select page in the communication buffer
    mov rbx, [rbx]            # Touch selected page, encoding the byte into CPU cache state
```

During speculative execution, the value loaded from the target address is used as an index into the communication buffer. Because the buffer is laid out as 256 page-sized regions, accessing `comm_buf[byte * 0x1000]` causes exactly one page corresponding to the secret byte to be loaded into the CPU cache. Although the faulting execution is later discarded architecturally, this cache state persists. After handling the fault, the program measures access latency to each page, the page that loads fastest reveals which value was accessed transiently, thereby leaking the secret byte through a microarchitectural side channel.

## References & inspiration

[pwn.college Microarchitecture Exploitation Dojo](https://pwn.college/system-security/speculative-execution/)
