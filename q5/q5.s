.data
    filename:   .asciz "input.txt"
    yes_str:    .asciz "Yes\n"
    no_str:     .asciz "No\n"
    
.bss
    # We only allocate 2 bytes of space total to satisfy the O(1) space constraint
    char_left:  .space 1
    char_right: .space 1

.text
.global _start

_start:
    # ==========================================
    # 1. Open the file "input.txt"
    # ==========================================
    li a7, 56               # Syscall number for openat (56 in Linux RISC-V)
    li a0, -100             # dirfd: AT_FDCWD (-100) means current directory
    la a1, filename         # pathname
    li a2, 0                # flags: O_RDONLY (0)
    li a3, 0                # mode: 0
    ecall
    
    # Check if file opened successfully
    bltz a0, exit           # If fd < 0, error (just exit)
    mv s0, a0               # s0 = file descriptor

    # ==========================================
    # 2. Find the length of the file
    # ==========================================
    li a7, 62               # Syscall number for lseek (62)
    mv a0, s0               # fd
    li a1, 0                # offset = 0
    li a2, 2                # whence: SEEK_END (2)
    ecall
    mv s1, a0               # s1 = file length

    # If the file is empty or 1 char, it's a palindrome
    li t0, 1
    ble s1, t0, check_done_yes

    # ==========================================
    # 3. Handle trailing newline (common in txt files)
    # ==========================================
    # Seek to the last character
    addi t0, s1, -1         # t0 = length - 1
    
    li a7, 62               # lseek
    mv a0, s0               # fd
    mv a1, t0               # offset = length - 1
    li a2, 0                # whence: SEEK_SET (0)
    ecall

    # Read the last character
    li a7, 63               # Syscall for read (63)
    mv a0, s0               # fd
    la a1, char_right       # buffer
    li a2, 1                # count = 1 byte
    ecall

    # Check if the last character is a newline ('\n', ASCII 10)
    la a1, char_right
    lb t1, 0(a1)
    li t2, 10               # ASCII for '\n'
    bne t1, t2, setup_pointers
    
    # If it is a newline, ignore it by decrementing the effective length
    addi s1, s1, -1

setup_pointers:
    li s2, 0                # s2 = left index = 0
    addi s3, s1, -1         # s3 = right index = length - 1

    # ==========================================
    # 4. Two-Pointer Loop (Check Palindrome)
    # ==========================================
loop:
    bge s2, s3, check_done_yes  # If left_index >= right_index, it's a palindrome!

    # --- Read left character ---
    li a7, 62               # lseek
    mv a0, s0               # fd
    mv a1, s2               # offset = left index
    li a2, 0                # whence: SEEK_SET
    ecall

    li a7, 63               # read
    mv a0, s0
    la a1, char_left
    li a2, 1                # read 1 byte
    ecall

    # --- Read right character ---
    li a7, 62               # lseek
    mv a0, s0
    mv a1, s3               # offset = right index
    li a2, 0                # whence: SEEK_SET
    ecall

    li a7, 63               # read
    mv a0, s0
    la a1, char_right
    li a2, 1                # read 1 byte
    ecall

    # --- Compare characters ---
    la t0, char_left
    lb t1, 0(t0)            # t1 = left character
    la t0, char_right
    lb t2, 0(t0)            # t2 = right character

    bne t1, t2, check_done_no   # If they don't match, not a palindrome

    # --- Advance pointers ---
    addi s2, s2, 1          # left++
    addi s3, s3, -1         # right--
    j loop                  # repeat

    # ==========================================
    # 5. Output Results
    # ==========================================
check_done_yes:
    la a1, yes_str          # load "Yes\n"
    li a2, 4                # length is 4
    j print_result

check_done_no:
    la a1, no_str           # load "No\n"
    li a2, 3                # length is 3

print_result:
    li a7, 64               # Syscall for write (64)
    li a0, 1                # fd: stdout (1)
    # a1 (buffer) and a2 (length) are already set above
    ecall

    # ==========================================
    # 6. Cleanup & Exit
    # ==========================================
    # Close the file
    li a7, 57               # Syscall for close (57)
    mv a0, s0               # fd
    ecall

exit:
    li a7, 93               # Syscall for exit (93)
    li a0, 0                # exit code 0
    ecall
    