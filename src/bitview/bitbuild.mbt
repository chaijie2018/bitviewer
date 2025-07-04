struct Bitbuilder {
  spec: Map[String, Spec]
}

pub fn Bitbuilder::new(spec: String) -> Bitbuilder {
  (try? Bitbuilder::new_malformable(spec)).unwrap()
}

pub fn Bitbuilder::new_malformable(spec: String) -> Bitbuilder raise Malformed {
  Bitbuilder :: { spec: parse_spec(spec) }
}

pub fn Bitbuilder::build(spec: String) -> Bytes {
  ...
}
