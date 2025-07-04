typealias @bitvec.Bitvector

struct Bitviewer {
  bytes: Bytes
}

pub fn Bitviewer::new(bytes: Bytes) -> Bitviewer {
  Bitviewer :: { bytes }
}

///|
/// The function accepts a custom specification language. Each statement in this language declares a field, with a name and the **bit-length**.
/// Note it's bits rather than bytes.
/// 
/// When the specification is malformed, this function panics. If you want it to raise an error, use `extract_malformable`.
/// 
/// An example:
/// ```c
/// opcode : 6;
/// funct3 : 5;
/// more : 32;
/// ```
/// 
/// This means the function would return a map with keys "opcode", "funct3" and "more".
/// The value of "opcode" would be **bits** 0-5, "funct3" would be **bits** 6-10, and "more" would be **bits** 11-42.
/// 
/// The semicolon is mandatory except for the last entry. All spaces will be ignored.
/// 
/// The identifier must only contain `A-Z`, `a-z`, numbers (not at start) and `_`. However, if you don't intend to refer to them later,
/// you can include every character except `:` or whitespace.
/// 
/// For fields that contain only whole bytes (i.e. whose bit length is a multiple of 8), you can use '<' for little-endian and '>' for big-endian.
/// 
/// For floating point fields, just declare their length; `Bitvector` type allows conversion to floating point.
/// 
pub fn Bitviewer::extract(self: Bitviewer, format: String) -> Map[String, Bitvector] {
  let r = try? self.extract_malformable(format);
  r.unwrap()
}

///|
/// Works the same as `extract()`, except that it reports an error on malformed specification string.
/// 
pub fn Bitviewer::extract_malformable(self: Bitviewer, format: String) -> Map[String, Bitvector] raise Malformed {
  let spec = parse_spec(format);
  let result = {};
  let mut from = 0;
  for k, v in spec {
    if (v.from is Some(v)) {
      from = eval(v, result);
    }
    let len = eval(v.len, result);

    let mut bv = bits(self.bytes, from, len) |> bit2byte |> Bitvector::from;
    // Currently we default to little endian. Perhaps make it configurable in the future.
    if (v.endian is Big) {
      if (len % 8 != 0) {
        raise Malformed("endianness only applies to whole-bytes");
      }
      bv = bv.rev();
    }
    result[k] = bv;
    from += len;
  }
  result
}

fn bits(bytes: Bytes, from: Int, len: Int) -> Array[Bool] {
  let result = Array::new(capacity=len)
  
  for i = 0; i < len; i = i + 1 {
    let bit_pos = from + i
    let ind = bit_pos / 8
    let offset = bit_pos % 8
    
    if ind < bytes.length() {
      let byte_val = bytes[ind]
      let bit = (byte_val.to_int() >> offset) & 1
      result.push(bit == 1)
    } else {
      result.push(false)
    }
  }
  
  result
}

fn bit2byte(bits: Array[Bool]) -> Array[Byte] {
  let byte_cnt = (bits.length() + 7) / 8
  let result = Array::new(capacity=byte_cnt)
  
  for i in 0..<byte_cnt {
    let mut v = 0
    
    for offset in 0..<8 {
      let bit = i * 8 + offset
      if bit < bits.length() && bits[bit] {
        v = v | (1 << offset)
      }
    }
    
    result.push(v.to_byte())
  }
  
  result
}
