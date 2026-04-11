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
    sw ra, 12(sp)
    sw s0, 8(sp)

    mv s0, a0             # s0 = val

    # Call malloc(12) for struct Node
    li a0, 12             # sizeof(struct Node) = 12 bytes
    call malloc           

    # Initialize the allocated node
    sw s0, 0(a0)          # node->val = val
    sw zero, 4(a0)        # node->left = NULL
    sw zero, 8(a0)        # node->right = NULL

    # Epilogue
    lw ra, 12(sp)
    lw s0, 8(sp)
    addi sp, sp, 16
    ret

# =========================================================
# struct Node* insert(struct Node* root, int val)
# a0 = root, a1 = val
# Returns new root pointer in a0
# =========================================================
insert:
    # Prologue
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)          # to hold root
    sw s1, 4(sp)          # to hold val

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
    lw a0, 8(s0)          # a0 = root->right
    mv a1, s1             # a1 = val
    call insert           # insert(root->right, val)
    sw a0, 8(s0)          # root->right = return value
    j insert_return_root

insert_left:
    # val < root->val
    lw a0, 4(s0)          # a0 = root->left
    mv a1, s1             # a1 = val
    call insert           # insert(root->left, val)
    sw a0, 4(s0)          # root->left = return value

insert_return_root:
    mv a0, s0             # return original root

insert_end:
    # Epilogue
    lw ra, 12(sp)
    lw s0, 8(sp)
    lw s1, 4(sp)
    addi sp, sp, 16
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
    lw a0, 8(a0)          # root = root->right
    j get_loop

get_left:
    lw a0, 4(a0)          # root = root->left
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
    lw a1, 4(a1)          # root = root->left
    j getAtMost_loop

getAtMost_less:
    # if root->val < val
    mv t1, t0             # res = root->val (this is a candidate)
    lw a1, 8(a1)          # root = root->right (check if there's a larger valid one)
    j getAtMost_loop

getAtMost_exact:
    mv t1, t0             # res = val

getAtMost_end:
    mv a0, t1             # set return value to res
    ret