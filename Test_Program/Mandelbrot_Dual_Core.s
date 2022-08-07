start:
# fixed point -> x << 8 , except for mult/div
#   32 Bit: 24MSB -> Int-Part, 8LSB -> fraction
# s0 : current four pixels
# s1 : fp_x
# s2 : fp_x_end
# s3 : fp_y
# s4 : fp_y_end
# s5 : fp_tresh
# s6 : max_iter
# s7 : frame_adr
# s9 : bytes per write - 1

# Check core_id
bgt t0, x0, core_1 

core_0:
    li s3, -150
    li s4, 0
    li s7, 0x1C010000
    beq x0, x0, actual_code

core_1:
    li s3, 0
    li s4, 150
    li s7, 0x1C027700     

# Actual code begins from here
actual_code:
li s2, 128
li s5, 1024
li s6, 31
li s9, 3

y_loop:
  # fp_x = fp_x_start
  li s1, -512
  
x_loop:
  # s10 : iter
  # s11 : x
  # a7  : y
  # a6  : sx
  # a5  : sy
  # init to zero
  add s10, x0, x0
  add s11, x0, x0
  add a7, x0, x0
  add a6, x0, x0
  add a5, x0, x0
  
iter_loop:
  # if (sx+sy) >= fp_tresh then leave iter_loop  
  add a0, a5, a6
  bge a0, s5, iter_end   
  
  # if iter = max_iter then leave iter_loop
  beq s10, s6, iter_end
  
  # sx = x * x
  add a1, x0, s11
  add a2, x0, s11
  jal ra, fp_mul  
  add a6, a0, x0
  
  # sy = y * y
  add a1, x0, a7
  add a2, x0, a7
  jal ra, fp_mul  
  add a5, a0, x0
  
  # y = 2 * x * y
  add a1, x0, s11
  add a2, x0, a7
  jal ra, fp_mul
  slli a7, a0, 1
  
  # y += fp_y
  add a7, a7, s3
  # x = sx - sy
  sub s11, a6, a5
  # x = x + fp_x
  add s11, s11, s1
  # iter = iter + 1
  addi s10, s10, 1  
  jal x0, iter_loop
  
iter_end:
  # make space for another pixel
  srli s0, s0, 8
  slli s10, s10, 24
  or s0, s0, s10
  
  #or s0, s0, s10
  
  # don't write if not 4 pixels computed
  addi s9, s9, -1
  bge s9, x0, iter_loop_header
  
  # store
  sw s0, 0(s7)
  # restore pixel cnt
  addi s9, x0, 3
  # incr frame pointer by 4*8 bit pixels
  addi s7, s7, 4
  
iter_loop_header:
  # fp_x += 1
  addi s1, s1, 1
  # if fp_x < fp_x_end then goto x_loop
  blt s1, s2, x_loop
  
  # fp_y = fp_y + fp_y_inc
  addi s3, s3, 1
  # if fp_y < fp_y_end then goto y_loop
  blt s3, s4, y_loop
  
done:
  jal x0, done

fp_mul:
  # a0 = a1 * a2
  mul a0, a1, a2
  # return a0 >> 8 (fixed point arithmetic)
  #   2^8*2^8 should be 2^8 (in this fixed point format 1=2^8)
  srai a0, a0, 8
  jalr x0, ra, 0
