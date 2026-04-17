.text
.globl make_node
.globl insert
.globl get
.globl getAtMost

# =========================================================
# struct Node* make_node(int val)
# a0 = val
# Returns pointer to newly allocated Node in a0
# =========================================================
make_node:
    # Prologue: save return address and s0 (to preserve val)
    addi sp, sp, -16
    sd ra, 8(sp)
    sd s0, 0(sp)

    mv s0, a0             # s0 = val

    # Call malloc(24) for RV64 struct Node layout
    li a0, 24             # sizeof(struct Node) = 24 bytes
    call malloc           

    # Initialize the allocated node
    sw s0, 0(a0)          # node->val = val
    sd zero, 8(a0)        # node->left = NULL
    sd zero, 16(a0)       # node->right = NULL

    # Epilogue
    ld ra, 8(sp)
    ld s0, 0(sp)
    addi sp, sp, 16
    ret

# =========================================================
# struct Node* insert(struct Node* root, int val)
# a0 = root, a1 = val
# Returns new root pointer in a0
# =========================================================
insert:
    # Prologue
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)          # to hold root
    sd s1, 8(sp)          # to hold val

    mv s0, a0             # s0 = root
    mv s1, a1             # s1 = val

    bnez s0, insert_not_null # if (root != NULL) skip to normal insert

    # Base Case: root == NULL, return make_node(val)
    mv a0, s1             
    call make_node
    j insert_end          # Newly created node is in a0, return it

insert_not_null:
    lw t0, 0(s0)          # t0 = root->val
    beq s1, t0, insert_return_root # if val == root->val, do nothing (ignore duplicate)
    blt s1, t0, insert_left        # if val < root->val, go left

insert_right:
    # val > root->val
    ld a0, 16(s0)         # a0 = root->right
    mv a1, s1             # a1 = val
    call insert           # insert(root->right, val)
    sd a0, 16(s0)         # root->right = return value
    j insert_return_root

insert_left:
    # val < root->val
    ld a0, 8(s0)          # a0 = root->left
    mv a1, s1             # a1 = val
    call insert           # insert(root->left, val)
    sd a0, 8(s0)          # root->left = return value

insert_return_root:
    mv a0, s0             # return original root

insert_end:
    # Epilogue
    ld ra, 24(sp)
    ld s0, 16(sp)
    ld s1, 8(sp)
    addi sp, sp, 32
    ret

# =========================================================
# struct Node* get(struct Node* root, int val)
# a0 = root, a1 = val
# Returns pointer to node or NULL in a0
# Note: Iterative implementation to save stack space
# =========================================================
get:
get_loop:
    beqz a0, get_end      # if root == NULL, return NULL (a0 is already 0/NULL)
    lw t0, 0(a0)          # t0 = root->val
    beq a1, t0, get_end   # if val == root->val, found it, return root (in a0)
    blt a1, t0, get_left  # if val < root->val, go left

get_right:
    ld a0, 16(a0)         # root = root->right
    j get_loop

get_left:
    ld a0, 8(a0)          # root = root->left
    j get_loop

get_end:
    ret

# =========================================================
# int getAtMost(int val, struct Node* root)
# a0 = val, a1 = root
# Returns int in a0 (-1 if not found)
# Note: Iterative implementation
# =========================================================
getAtMost:
    li t1, -1             # res = -1 (default if no such node exists)

getAtMost_loop:
    beqz a1, getAtMost_end # if root == NULL, break loop
    
    lw t0, 0(a1)          # t0 = root->val
    beq t0, a0, getAtMost_exact # if root->val == val, we found the max possible
    blt t0, a0, getAtMost_less  # if root->val < val

    # if root->val > val
    ld a1, 8(a1)          # root = root->left
    j getAtMost_loop

getAtMost_less:
    # if root->val < val
    mv t1, t0             # res = root->val (this is a candidate)
    ld a1, 16(a1)         # root = root->right (check if there's a larger valid one)
    j getAtMost_loop

getAtMost_exact:
    mv t1, t0             # res = val

getAtMost_end:
    mv a0, t1             # set return value to res
    ret
