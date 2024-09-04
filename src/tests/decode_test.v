import vbech32
import encoding.hex

fn test_decode() {
	npub := 'npub1hg2lnyey78ywm9uwyf4ap0uu65edr3p5jhhx7auzkarrlz65c96qj2ktxa'
	hrp, decoded := vbech32.decode_to_base256(npub)!
	assert hrp == 'npub'
	assert decoded.hex() == 'ba15f99324f1c8ed978e226bd0bf9cd532d1c43495ee6f7782b7463f8b54c174'
}
