//go:build arm64
#include "textflag.h"

// func OctVecAdd(x, y []byte)
// x: {x_base, x_len, x_cap}, y: {y_base, y_len, y_cap}
TEXT ·OctVecAdd(SB), NOSPLIT|NOFRAME, $0-48
    MOVD   x_base+0(FP), R0
    MOVD   y_base+24(FP), R1
    MOVD   x_len+8(FP), R2

    LSR    $8, R2, R3
    CBZ    R3, after256
loop256:
    // 8×(32B block) = 256B
    // blk1
    VLD1   (R0), [V0.B16, V1.B16]
    VLD1.P 32(R1), [V2.B16, V3.B16]
    VEOR   V2.B16, V0.B16, V0.B16
    VEOR   V3.B16, V1.B16, V1.B16
    VST1.P [V0.B16, V1.B16], 32(R0)
    // blk2
    VLD1   (R0), [V0.B16, V1.B16]
    VLD1.P 32(R1), [V2.B16, V3.B16]
    VEOR   V2.B16, V0.B16, V0.B16
    VEOR   V3.B16, V1.B16, V1.B16
    VST1.P [V0.B16, V1.B16], 32(R0)
    // blk3
    VLD1   (R0), [V0.B16, V1.B16]
    VLD1.P 32(R1), [V2.B16, V3.B16]
    VEOR   V2.B16, V0.B16, V0.B16
    VEOR   V3.B16, V1.B16, V1.B16
    VST1.P [V0.B16, V1.B16], 32(R0)
    // blk4
    VLD1   (R0), [V0.B16, V1.B16]
    VLD1.P 32(R1), [V2.B16, V3.B16]
    VEOR   V2.B16, V0.B16, V0.B16
    VEOR   V3.B16, V1.B16, V1.B16
    VST1.P [V0.B16, V1.B16], 32(R0)
    // blk5
    VLD1   (R0), [V0.B16, V1.B16]
    VLD1.P 32(R1), [V2.B16, V3.B16]
    VEOR   V2.B16, V0.B16, V0.B16
    VEOR   V3.B16, V1.B16, V1.B16
    VST1.P [V0.B16, V1.B16], 32(R0)
    // blk6
    VLD1   (R0), [V0.B16, V1.B16]
    VLD1.P 32(R1), [V2.B16, V3.B16]
    VEOR   V2.B16, V0.B16, V0.B16
    VEOR   V3.B16, V1.B16, V1.B16
    VST1.P [V0.B16, V1.B16], 32(R0)
    // blk7
    VLD1   (R0), [V0.B16, V1.B16]
    VLD1.P 32(R1), [V2.B16, V3.B16]
    VEOR   V2.B16, V0.B16, V0.B16
    VEOR   V3.B16, V1.B16, V1.B16
    VST1.P [V0.B16, V1.B16], 32(R0)
    // blk8
    VLD1   (R0), [V0.B16, V1.B16]
    VLD1.P 32(R1), [V2.B16, V3.B16]
    VEOR   V2.B16, V0.B16, V0.B16
    VEOR   V3.B16, V1.B16, V1.B16
    VST1.P [V0.B16, V1.B16], 32(R0)

    SUBS   $1, R3
    BNE    loop256
after256:
    AND    $255, R2, R2
    LSR    $6, R2, R3
    CBZ    R3, after64
loop64:
    // 32B × 2

    // block #1 (32B)
    VLD1   (R0), [V0.B16, V1.B16]
    VLD1.P 32(R1), [V2.B16, V3.B16]
    VEOR   V2.B16, V0.B16, V0.B16
    VEOR   V3.B16, V1.B16, V1.B16
    VST1.P [V0.B16, V1.B16], 32(R0)

    // block #2 (32B)
    VLD1   (R0), [V0.B16, V1.B16]
    VLD1.P 32(R1), [V2.B16, V3.B16]
    VEOR   V2.B16, V0.B16, V0.B16
    VEOR   V3.B16, V1.B16, V1.B16
    VST1.P [V0.B16, V1.B16], 32(R0)

    SUBS   $1, R3
    BNE    loop64
after64:
    AND    $63, R2, R2
    LSR    $5, R2, R3
    CBZ    R3, after32
loop32:
    VLD1   (R0), [V0.B16, V1.B16]
    VLD1.P 32(R1), [V2.B16, V3.B16]
    VEOR   V2.B16, V0.B16, V0.B16
    VEOR   V3.B16, V1.B16, V1.B16
    VST1.P [V0.B16, V1.B16], 32(R0)

    SUBS   $1, R3
    BNE    loop32
after32:
    AND    $31, R2, R2
    LSR    $4, R2, R3
    CBZ    R3, tail
loop16:
    VLD1   (R0), [V0.B16]
    VLD1.P 16(R1), [V1.B16]
    VEOR   V1.B16, V0.B16, V0.B16
    VST1.P [V0.B16], 16(R0)

    SUBS   $1, R3
    BNE    loop16

// ---- tail <16: 8/4/2/1 via TBZ (no NEON) ----
tail:
    TBZ    $3, R2, chk4
    MOVD   0(R0), R3
    MOVD   0(R1), R4
    EOR    R4, R3, R3
    MOVD   R3, 0(R0)
    ADD    $8, R0
    ADD    $8, R1
chk4:
    TBZ    $2, R2, chk2
    MOVW   0(R0), R3
    MOVW   0(R1), R4
    EORW   R4, R3, R3
    MOVW   R3, 0(R0)
    ADD    $4, R0
    ADD    $4, R1
chk2:
    TBZ    $1, R2, chk1
    MOVHU  0(R0), R3
    MOVHU  0(R1), R4
    EOR    R4, R3, R3
    MOVH   R3, 0(R0)
    ADD    $2, R0
    ADD    $2, R1
chk1:
    TBZ    $0, R2, done
    MOVBU  0(R0), R3
    MOVBU  0(R1), R4
    EOR    R4, R3, R3
    MOVB   R3, 0(R0)
done:
    RET

DATA  ·mask0f+0(SB)/8, $0x0f0f0f0f0f0f0f0f
DATA  ·mask0f+8(SB)/8, $0x0f0f0f0f0f0f0f0f
GLOBL ·mask0f(SB), RODATA, $16

// func OctVecMul(vector []byte, multiplier uint8)
TEXT ·OctVecMul(SB), $0-32
    MOVD   vector+0(FP), R0          // R0 = &vector[0]
    MOVD   vector_len+8(FP), R1      // R1 = len(vector)
    MOVBU  multiplier+24(FP), R2     // R2 = multiplier

    MOVD   $·_OctMulLo(SB), R3
    MOVD   $·_OctMulHi(SB), R4
    LSL    $4, R2, R5
    ADD    R5, R3, R3                // R3 = &OctMulLo[multiplier]
    ADD    R5, R4, R4                // R4 = &OctMulHi[multiplier]

    VLD1   (R3), [V2.B16]            // V2 = rowLo
    VLD1   (R4), [V3.B16]            // V3 = rowHi

    MOVD   $·mask0f(SB), R6
    VLD1   (R6), [V1.B16]            // V1 = 0x0f0f..0f0f

    LSR     $4, R1, R5
    CBZ     R5, tail
loop16:
    VLD1    (R0), [V0.B16]           // V0 = R0
    VAND    V1.B16, V0.B16, V4.B16   // V4 = V0 & 0x0f
    VUSHR   $4, V0.B16, V5.B16       // V5 = V0 >> 4
    VTBL    V4.B16, [V2.B16], V4.B16 // V4 = rowLo[V4]
    VTBL    V5.B16, [V3.B16], V5.B16 // V5 = rowHi[V5]
    VEOR    V4.B16, V5.B16, V6.B16   // V6 = V4 ^ V5
    VST1.P  [V6.B16], 16(R0)         // R0 = V6; R0 += 16

    SUBS    $1, R5, R5
    BNE     loop16
after16:
    AND     $15, R1, R1
    CBZ     R1, done
tail:
    MOVBU   0(R0), R2          // x
    AND     $0x0F, R2, R5      // low = x & 0x0F
    ADD     R3, R5, R5
    MOVBU   0(R5), R5          // loVal = rowLo[low]

    LSR     $4, R2, R2         // high = x >> 4
    ADD     R4, R2, R2
    MOVBU   0(R2), R2          // hiVal = rowHi[high]

    EOR     R2, R5, R5         // out = lo ^ hi
    MOVB    R5, 0(R0)          // store

    ADD     $1, R0
    SUBS    $1, R1
    BNE     tail
done:
    RET
