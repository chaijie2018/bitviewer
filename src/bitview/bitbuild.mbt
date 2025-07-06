///|
/// Build a bitviewer from the specification and a list of bindings.
/// 
/// See `extract()` for the details of the specification language.
/// 
pub fn Bitviewer::build(spec: String, x: Map[String, Int]) -> Bitviewer {
  (try? Bitviewer::build_malformable(spec, x)).unwrap()
}

///|
/// Same as `extract()`, but raises an error on malformed specification, rather than panicking.
/// 
pub fn[T: @bitvec.BitvectorConvertible] Bitviewer::build_malformable(spec: String, x_: Map[String, T]) -> Bitviewer raise Malformed {
  let spec = parse_spec(spec);
  if (spec.size() == 0) {
    return Bitviewer::new(b"");
  }

  let x = {};
  for k, v in x_ {
    x[k] = v.from();
  }

  let places = {};
  let mut from = 0;
  for k, v in spec {
    let len = eval(v.len, x);
    places[k] = if (v.from is Some(f)) { let f = eval(f, x); from = f; (f, f + len, v.endian) } else { (from, from + len, v.endian) };
    from += len;
  }
  let max = places.values().map((x) => x.1).maximum().unwrap();
  let bv = Bitvector::from(Array::make((max + 7) / 8, (0: Byte)));
  for k, v in places {
    let (from, to, endian) = v;
    let mut w = x.get(k).unwrap();
    if (endian is Big) {
      if ((to - from) % 8 != 0) {
        raise Malformed("endianness only applies to whole-bytes");
      }
      w = w.rev();
    }
    bv.set(from, to, w);
  }
  { bytes: bv.raw() }
}

pub fn Bitviewer::raw(self: Bitviewer) -> Bitvector {
  Bitvector::from(self.bytes);
}
