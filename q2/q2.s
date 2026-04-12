.data
fmt:        .asciz "%d "
newline:    .asciz "\n"

.text
.globl main

main:
    # Prologue: 16-byte aligned stack frame
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    sd s1, 40(sp)
    sd s2, 32(sp)
    sd s3, 24(sp)
    sd s4, 16(sp)
    sd s5, 8(sp)

    # Save argc and argv
    mv s0, a0           # s0 = argc
    mv s1, a1           # s1 = argv

    # If argc <= 1, no numbers were provided. Print newline and exit.
    li t0, 1
    ble s0, t0, finish_up

    addi s2, s0, -1     # s2 = n (number of elements to process)

    # Allocate 'arr' (n * 4 bytes)
    slli a0, s2, 2      
    call malloc
    mv s3, a0           

    # Allocate 'result' (n * 4 bytes)
    slli a0, s2, 2      
    call malloc
    mv s4, a0           

    # Parse argv[1...n]
    li s5, 0            # i = 0
parse_loop:
    bge s5, s2, parse_done
    
    addi t0, s5, 1      
    slli t0, t0, 3      # 8-byte pointers for 64-bit
    add t1, s1, t0      
    ld a0, 0(t1)        # Load the string pointer

    call atoi           # Convert to int

    slli t0, s5, 2      
    add t1, s3, t0      
    sw a0, 0(t1)        # Store 32-bit int

    addi s5, s5, 1      
    j parse_loop

parse_done:
    mv a0, s3           
    mv a1, s2           
    mv a2, s4           
    call next_greater

    # Print results
    li s5, 0            
print_loop:
    bge s5, s2, print_done
    
    slli t0, s5, 2
    add t1, s4, t0
    lw a1, 0(t1)        
    la a0, fmt          
    call printf

    addi s5, s5, 1      
    j print_loop

print_done:
    la a0, newline
    call printf

    # Free memory
    mv a0, s3
    call free
    mv a0, s4
    call free

finish_up:
    li a0, 0            
    ld ra, 56(sp)
    ld s0, 48(sp)
    ld s1, 40(sp)
    ld s2, 32(sp)
    ld s3, 24(sp)
    ld s4, 16(sp)
    ld s5, 8(sp)
    addi sp, sp, 64
    ret

# --- next_greater function ---
next_greater:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    sd s1, 24(sp)
    sd s2, 16(sp)
    sd s3, 8(sp)
    sd s4, 0(sp)

    mv s0, a0           # arr
    mv s1, a1           # n
    mv s2, a2           # result

    # 1. Init result with -1
    li t0, -1
    li t1, 0            
init_res:
    bge t1, s1, init_done
    slli t2, t1, 2
    add t3, s2, t2      
    sw t0, 0(t3)        
    addi t1, t1, 1
    j init_res
init_done:

    # 2. Stack (n * 4 bytes)
    slli a0, s1, 2      
    call malloc
    mv s3, a0           # base
    mv s4, a0           # top

    # 3. Algorithm
    addi t1, s1, -1     # i = n - 1
ng_for:
    bltz t1, ng_exit 

ng_while:
    beq s3, s4, ng_while_end 
    addi t2, s4, -4     
    lw a3, 0(t2)        # a3 = top index
    
    slli t4, a3, 2
    add t5, s0, t4
    lw t6, 0(t5)        # arr[top]

    slli t4, t1, 2
    add t5, s0, t4
    lw a4, 0(t5)        # arr[i]

    bgt t6, a4, ng_while_end
    addi s4, s4, -4     # pop
    j ng_while

ng_while_end:
    beq s3, s4, ng_push
    addi t2, s4, -4     
    lw a3, 0(t2)        
    slli t4, t1, 2      
    add t5, s2, t4      
    sw a3, 0(t5)        

ng_push:
    sw t1, 0(s4)        
    addi s4, s4, 4      
    addi t1, t1, -1
    j ng_for

ng_exit:
    mv a0, s3
    call free
    ld ra, 40(sp)
    ld s0, 32(sp)
    ld s1, 24(sp)
    ld s2, 16(sp)
    ld s3, 8(sp)
    ld s4, 0(sp)
    addi sp, sp, 48
    ret
    