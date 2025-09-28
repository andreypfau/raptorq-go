package discmath

import (
	"bytes"
	"math/rand"
	"testing"
	"time"
)

func TestOctVecAdd(t *testing.T) {
	rng := rand.New(rand.NewSource(1))

	sizes := []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 14, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128, 129, 255, 256, 257, 768, 4096}

	for _, n := range sizes {
		for iter := 0; iter < 3; iter++ {
			x := make([]byte, n)
			y := make([]byte, n)
			for i := 0; i < n; i++ {
				x[i] = byte(rng.Intn(256))
				y[i] = byte(rng.Intn(256))
			}

			want := make([]byte, n)
			copy(want, x)
			for i := 0; i < n; i++ {
				want[i] ^= y[i]
			}
			yKeep := append([]byte(nil), y...)

			OctVecAdd(x, y)

			if !bytes.Equal(x, want) {
				t.Fatalf("OctVecAdd mismatch (n=%d):\n got=%v\nwant=%v", n, x, want)
			}
			if !bytes.Equal(y, yKeep) {
				t.Fatalf("OctVecAdd modified y (n=%d)", n)
			}
		}
	}

	for iter := 0; iter < 8; iter++ {
		n := 8192 + rng.Intn(4096)
		x := make([]byte, n)
		y := make([]byte, n)
		for i := 0; i < n; i++ {
			x[i] = byte(rng.Intn(256))
			y[i] = byte(rng.Intn(256))
		}
		want := append([]byte(nil), x...)
		for i := 0; i < n; i++ {
			want[i] ^= y[i]
		}
		OctVecAdd(x, y)
		if !bytes.Equal(x, want) {
			t.Fatalf("OctVecAdd stress mismatch (iter=%d, n=%d)", iter, n)
		}
	}
}

func octVecMul_generic(vector []byte, multiplier uint8) {
	for i := 0; i < len(vector); i++ {
		vector[i] = OctMul(vector[i], multiplier)
	}
}

func TestOctVecMul_BasicSizes(t *testing.T) {
	rng := rand.New(rand.NewSource(1))
	sizes := []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 14, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128, 129, 255, 256, 257, 768, 4096}
	mults := []byte{0x00, 0x01, 0x02, 0x03, 0x1b, 0x53, 0x80, 0x8d, 0xff} // набор репрезентативных множителей

	for _, n := range sizes {
		for iter := 0; iter < 3; iter++ {
			x := make([]byte, n)
			for i := 0; i < n; i++ {
				x[i] = byte(rng.Intn(256))
			}

			for _, u := range mults {
				want := make([]byte, n)
				copy(want, x)
				octVecMul_generic(want, u)

				in := make([]byte, n)
				copy(in, x)
				OctVecMul(in, u)

				if !bytes.Equal(in, want) {
					t.Fatalf("OctVecMul mismatch (n=%d, u=0x%02x):\n got=%v\nwant=%v", n, u, in, want)
				}
			}
		}
	}
}

func TestOctVecMul_Invertibility(t *testing.T) {
	rng := rand.New(rand.NewSource(2))

	sizes := []int{1, 13, 16, 31, 64, 127, 256, 768}
	for _, n := range sizes {
		x := make([]byte, n)
		for i := 0; i < n; i++ {
			x[i] = byte(rng.Intn(256))
		}
		for iter := 0; iter < 8; iter++ {
			u := byte(rng.Intn(255) + 1) // u != 0
			inv := OctInverse(u)

			got := append([]byte(nil), x...)
			OctVecMul(got, u)
			OctVecMul(got, inv)

			if !bytes.Equal(got, x) {
				t.Fatalf("Invertibility failed (n=%d, u=0x%02x, inv=0x%02x)", n, u, inv)
			}
		}
	}
}

func TestOctVecMul_DistributivityOverAdd(t *testing.T) {
	rng := rand.New(rand.NewSource(3))

	sizes := []int{1, 7, 15, 16, 17, 63, 64, 65, 255, 256, 257}
	for _, n := range sizes {
		for iter := 0; iter < 4; iter++ {
			x := make([]byte, n)
			y := make([]byte, n)
			for i := 0; i < n; i++ {
				x[i] = byte(rng.Intn(256))
				y[i] = byte(rng.Intn(256))
			}
			u := byte(rng.Intn(256))

			// left = (x ^ y) * u
			left := append([]byte(nil), x...)
			OctVecAdd(left, y)
			OctVecMul(left, u)

			// right = x*u ^ y*u
			right := append([]byte(nil), x...)
			yy := append([]byte(nil), y...)
			OctVecMul(right, u)
			OctVecMul(yy, u)
			OctVecAdd(right, yy)

			if !bytes.Equal(left, right) {
				t.Fatalf("Distributivity failed (n=%d, u=0x%02x)", n, u)
			}
		}
	}
}

func TestOctVecMul_Stress(t *testing.T) {
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))
	for iter := 0; iter < 8; iter++ {
		n := 8192 + rng.Intn(4096)
		x := make([]byte, n)
		for i := 0; i < n; i++ {
			x[i] = byte(rng.Intn(256))
		}
		u := byte(rng.Intn(256))

		want := append([]byte(nil), x...)
		for i := 0; i < n; i++ {
			if u == 0 {
				want[i] = 0
			} else if u == 1 {
				// no-op
			} else {
				want[i] = OctMul(want[i], u)
			}
		}

		OctVecMul(x, u)

		if !bytes.Equal(x, want) {
			t.Fatalf("OctVecMul stress mismatch (iter=%d, n=%d, u=0x%02x)", iter, n, u)
		}
	}
}

func TestOctVecMul_test(t *testing.T) {
	OctVecMul([]byte{1, 2, 3, 4, 5}, 0x02)
}
