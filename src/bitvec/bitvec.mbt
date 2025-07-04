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

pub impl BitvectorConvertible for Char with from(self) {
  { v: self.to_int().to_le_bytes()[:2].iter().collect() }
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

pub impl BitvectorConvertible for Bytes with from(self) {
  { v: self.to_array() }
}

pub impl BitvectorConvertible for Bytes with to(bv) {
  Bytes::from_array(bv.v)
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
