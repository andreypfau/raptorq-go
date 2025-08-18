//go:build amd64

package discmath

import "unsafe"

//go:noescape
func asmSSSE3MulAdd(x, y unsafe.Pointer, table unsafe.Pointer, blocks int)

func OctVecMulAdd(x, y []byte, multiplier uint8) {
	n := len(x)
	if n == 0 {
		return
	}
	table := _Mul4bitPreCalc[multiplier]
	blocks := n / 16
	if blocks > 0 {
		asmSSSE3MulAdd(
			unsafe.Pointer(&x[0]),
			unsafe.Pointer(&y[0]),
			unsafe.Pointer(&table[0]),
			blocks,
		)
	}
	full := _MulPreCalc[multiplier]
	for i := blocks * 16; i < n; i++ {
		x[i] ^= full[y[i]]
	}
}
