module vbech32

pub const max_length_bip173 = 90
pub const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l'
pub const separator = '1'

const gen = [u32(0x3b6a57b2), 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]

pub fn encode_from_base256(hrp string, data []u8) !string {
	converted := convert_bits(data, 8, 5, true)!
	return encode(hrp, converted)
}

pub fn decode_to_base256(bech string) !(string, []u8) {
	hrp, data := decode(bech)!
	converted := convert_bits(data, 5, 8, false)!
	return hrp, converted
}

pub fn encode(hrp string, data []u8) !string {
	mut combined := []u8{cap: hrp.len + 1 + data.len + 6}
	combined << hrp.bytes()
	combined << vbech32.separator[0]
	combined << data
	checksum := bech32_create_checksum(hrp, data)
	combined << checksum

	mut result := hrp + vbech32.separator
	for b in combined[hrp.len + 1..] {
		if b >= vbech32.charset.len {
			return error('Invalid data byte: ${b}')
		}
		result += vbech32.charset[b].ascii_str()
	}
	return result
}

pub fn decode(bech string) !(string, []u8) {
	if bech.len > vbech32.max_length_bip173 {
		return error('Bech32 string too long')
	}
	if bech.to_lower() != bech && bech.to_upper() != bech {
		return error('Mixed case string')
	}
	bech_lower := bech.to_lower()
	pos := bech_lower.last_index(vbech32.separator) or { return error('No separator character') }
	if pos < 1 || pos + 7 > bech_lower.len {
		return error('Invalid separator position')
	}
	hrp := bech_lower[..pos]
	data := bech_lower[pos + 1..]
	mut decoded_data := []u8{cap: data.len}
	for ch in data {
		index := vbech32.charset.index(ch.ascii_str()) or { return error('Invalid character') }
		decoded_data << u8(index)
	}
	if !verify_checksum(hrp, decoded_data) {
		return error('Invalid checksum')
	}
	return hrp, decoded_data[..decoded_data.len - 6]
}

pub fn convert_bits(data []u8, from_bits u8, to_bits u8, pad bool) ![]u8 {
	mut acc := u32(0)
	mut bits := u8(0)
	mut result := []u8{}
	maxv := u32((1 << to_bits) - 1)

	for value in data {
		if value >> from_bits != 0 {
			return error('Invalid value')
		}
		acc = (acc << from_bits) | u32(value)
		bits += from_bits
		for bits >= to_bits {
			bits -= to_bits
			result << u8((acc >> bits) & maxv)
		}
	}

	if pad {
		if bits > 0 {
			result << u8((acc << (to_bits - bits)) & maxv)
		}
	} else if bits >= from_bits || ((acc << (to_bits - bits)) & maxv) != 0 {
		return error('Invalid padding')
	}

	return result
}

fn verify_checksum(hrp string, data []u8) bool {
	mut combined := bech32_hrp_expand(hrp)
	combined << data
	return bech32_polymod(combined) == 1
}

fn bech32_polymod(values []u8) u32 {
	mut chk := u32(1)
	for v in values {
		top := chk >> 25
		chk = (chk & 0x1ffffff) << 5 ^ u32(v)
		for i := u8(0); i < 5; i++ {
			if ((top >> i) & 1) == 1 {
				chk ^= vbech32.gen[i]
			}
		}
	}
	return chk
}

fn bech32_hrp_expand(hrp string) []u8 {
	mut result := []u8{len: (hrp.len * 2) + 1}
	for i, ch in hrp {
		result[i] = u8(ch) >> 5
		result[hrp.len + 1 + i] = u8(ch) & 31
	}
	result[hrp.len] = 0
	return result
}

fn bech32_create_checksum(hrp string, data []u8) []u8 {
	mut values := bech32_hrp_expand(hrp)
	values << data
	values << [u8(0), 0, 0, 0, 0, 0]
	polymod := bech32_polymod(values) ^ 1
	mut result := []u8{len: 6}
	for i := 0; i < 6; i++ {
		result[i] = u8((polymod >> (5 * (5 - i))) & 31)
	}
	return result
}
