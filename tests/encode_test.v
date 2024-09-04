import vbech32
import encoding.hex

fn test_encode() {
	hrp := 'npub'
	hexstr := 'ba15f99324f1c8ed978e226bd0bf9cd532d1c43495ee6f7782b7463f8b54c174'
	encoded := vbech32.encode_from_base256(hrp, hex.decode(hexstr)!)!
	assert encoded == 'npub1hg2lnyey78ywm9uwyf4ap0uu65edr3p5jhhx7auzkarrlz65c96qj2ktxa'
}
