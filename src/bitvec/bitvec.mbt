pub struct Bitvector {
  v: Array[Byte]
}

pub impl Show for Bitvector with to_string(self) {
  self.raw().to_string()
}

pub impl Show for Bitvector with output(self, logger) {
  logger.write_string(self.to_string())
}

pub trait BitvectorConvertible {
  from(Self) -> Bitvector
  to(Bitvector) -> Self
}

pub impl BitvectorConvertible for Bool with from(self) {
  { v: [self.to_int().to_byte()] }
}

pub impl BitvectorConvertible for Bool with to(bv) {
  for v in bv.v {
    if (v != 0) {
      return true;
    }
  }
  return false;
}

pub impl BitvectorConvertible for Char with from(self) {
  { v: self.to_int().to_le_bytes().iter().collect() }
}

pub impl BitvectorConvertible for Char with to(bv) {
  Int::unsafe_to_char((bv.v[1].to_int() << 8) + bv.v[0].to_int())
}

pub impl BitvectorConvertible for Byte with from(self) {
  { v: [self] }
}

pub impl BitvectorConvertible for Byte with to(bv) {
  bv.v[0]
}

pub impl BitvectorConvertible for Int with from(self) {
  { v: self.to_le_bytes().iter().collect() }
}

pub impl BitvectorConvertible for Int with to(bv) {
  bv.to(0U).reinterpret_as_int()
}

pub impl BitvectorConvertible for UInt with from(self) {
  { v: self.to_le_bytes().iter().collect() }
}

pub impl BitvectorConvertible for UInt with to(bv) {
  let mut result = 0U
  for i in 0..<@math.minimum(bv.v.length(), 4) {
    result = result + (bv.v[i].to_uint() << (i * 8))
  }
  result
}

pub impl BitvectorConvertible for Int64 with from(self) {
  { v: self.to_le_bytes().iter().collect() }
}

pub impl BitvectorConvertible for Int64 with to(bv) {
  bv.to(0UL).reinterpret_as_int64()
}

pub impl BitvectorConvertible for UInt64 with from(self) {
  { v: self.to_le_bytes().iter().collect() }
}

pub impl BitvectorConvertible for UInt64 with to(bv) {
  let mut result = 0UL
  for i in 0..<@math.minimum(bv.v.length(), 8) {
    result = result + (bv.v[i].to_uint64() << (i * 8))
  }
  result
}

pub impl BitvectorConvertible for Array[Byte] with from(self) {
  { v: self }
}

pub impl BitvectorConvertible for Array[Byte] with to(bv) {
  bv.v
}

pub impl BitvectorConvertible for ArrayView[Byte] with from(self) {
  { v: self.to_array() }
}

pub impl BitvectorConvertible for ArrayView[Byte] with to(bv) {
  bv.v
}

pub impl BitvectorConvertible for Bytes with from(self) {
  { v: self.to_array() }
}

pub impl BitvectorConvertible for Bytes with to(bv) {
  Bytes::from_array(bv.v)
}

pub impl BitvectorConvertible for Bitvector with from(self) {
  self
}

pub impl BitvectorConvertible for Bitvector with to(bv) {
  bv
}

///|
/// Creates a Bitvector from various number types.
/// 
pub fn[T: BitvectorConvertible] Bitvector::from(x: T) -> Bitvector {
  x.from()
}

///|
/// Converts the Bitvector to the type given by the argument.
/// 
/// The argument itself is unused.
/// 
pub fn[T: BitvectorConvertible] Bitvector::to(self: Bitvector, _x: T) -> T {
  T::to(self)
}

///|
/// Create a raw byte representation. This is a **copy**.
/// 
pub fn Bitvector::raw(self: Bitvector) -> Bytes {
  self.to(b"")
}

///|
/// Create a raw bytes representation. This is a **reference**.
/// 
pub fn Bitvector::view(self: Bitvector) -> Array[Byte] {
  self.v
}

///|
/// Reverses the bytes inside the vector.
/// 
pub fn Bitvector::rev(self: Bitvector) -> Bitvector {
  { v: self.v.rev() }
}

test {
  let bv = Bitvector::from(2235);
  println(bv.to('_'));
  println(bv.to(0L));
  println(bv.to(0U));
  println(bv.to(0UL));

  let bv2 = Bitvector::from(b"hello world".to_array());
  println(bv2.to(0));
  println(bv2.raw());
}

///|
/// Sets the bits from `from` to `to` with `value`. Note that `to` is **excluded** from the range.
/// 
/// When `from` or `to` is longer than the bitvector's length, it panics.
/// 
/// The `value` will be truncated when it's too long, and will be sign-extended when it's too short.
/// 
pub fn[T: BitvectorConvertible] Bitvector::set(self: Bitvector, from: Int, to: Int, value: T) -> Unit {
  if (from > to) {
    return;
  }
  let value = value.from();
  
  let cnt = to - from;
  // Clear the bits in the target range.
  for i in 0..<cnt {
    let byte_idx = (from + i) / 8;
    let bit_idx = (from + i) % 8;
    if (byte_idx >= self.v.length()) {
      break;
    }
    self.v[byte_idx] = (self.v[byte_idx].to_int() & (1 << bit_idx).lnot()).to_byte();
  }
  
  // Set the bits from the value.
  for i in 0..<cnt {
    let src_byte = i / 8;
    let src_bit = i % 8;
    let dst_byte = (from + i) / 8;
    let dst_bit = (from + i) % 8;
    
    if (dst_byte >= self.v.length()) {
      break;
    }
    
    let v = if (src_byte < value.v.length()) { (value.v[src_byte].to_int() >> src_bit) & 1 } else { 0 };
    if v == 1 {
      self.v[dst_byte] = (self.v[dst_byte].to_int() | (1 << dst_bit)).to_byte();
    }
  }
}

test "set" {
  let v = Bitvector::from(0x22);
  v.set(4, 8, Bitvector::from(0xa));
  inspect(v.to(0), content="\{0xa2}");
  v.set(0, 4, Bitvector::from(0x5));
  inspect(v.to(0), content="\{0xa5}");
}

///|
/// Extracts some bits from this bitvector. Panics on out-of-bound access.
/// 
pub fn Bitvector::op_as_view(self: Bitvector, start~: Int, end?: Int) -> Bitvector {
  let end = if (end is Some(v)) { v } else { self.v.length() * 8 };
    if start >= end || start < 0 {
    return { v: [] };
  }
  
  let cnt = (end - start + 7) / 8;
  let res = Array::make(cnt, (0: Byte));
  
  for i in 0..<(end - start) {
    let src_byte = (start + i) / 8;
    let src_bit = (start + i) % 8;
    let dst_byte = i / 8;
    let dst_bit = i % 8;
    if src_byte >= self.v.length() {
      break;
    }
    if ((self.v[src_byte].to_int() >> src_bit) & 1) == 1 {
      res[dst_byte] = (res[dst_byte].to_int() | (1 << dst_bit)).to_byte();
    }
  }
  
  { v: res }
}

///|
/// Extract a single bit from this bitvector.
/// 
pub fn Bitvector::op_get(self: Bitvector, pos: Int) -> Int {
  self[pos:pos+1].to(0);
}

///|
/// Set a single bit for this bitvector.
/// 
pub fn Bitvector::op_set(self: Bitvector, pos: Int, val: Bool) -> Unit {
  self.set(pos, pos + 1, val)
}

test "get" {
  let v = Bitvector::from(0xa2);
  inspect(v[4:].to(0), content="\{0xa}");
  inspect(v[3], content="0");
  inspect(v[1], content="1");
  v[3] = true;
  inspect(v.to(0), content="\{0xaa}");
}
