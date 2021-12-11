.global _start 
_start:
	sb	x0, 0(x0)
    addi x1,x1,1
	sb	x1, 5(x0)
    addi x2,x2,2
	sw	x2, 8(x0)
    addi x31,x31,5
	sh	x31, 14(x0)
    auipc x4, 1
    sw x4, 16(x0)
    slti x2, x1,2
    sh x2, 20(x0)
    lui x3, 16
    sw x3, 24(x0)
    

