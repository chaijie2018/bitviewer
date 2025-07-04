typealias @bitvec.Bitvector

test "arith" {
  let spec =
#|h1 : 3*5-4+1;
#|h2 : 4;
  
  let viewer = Bitviewer::new(Bitvector::from(0x1234).raw());
  let map = viewer.extract(spec);
  inspect(map.get("h1").unwrap().to(0), content="\{0x234}");
  inspect(map.get("h2").unwrap().to(0), content="1");
}

test "endian" {
  let spec = "rev: >32";
  let viewer = Bitviewer::new(Bitvector::from(0x12345678).raw())
  let map = viewer.extract(spec);
  inspect(map.get("rev").unwrap().to(0), content="\{0x78563412}");
}

test "mixed endian" {
  let spec =
#|a : 7;
#|b : <16;
#|c : >16;
#|d : 3;
  
  let viewer = Bitviewer::new(Bitvector::from(0b110_1000110111001111_0010011011011001_0010110L).raw())
  let map = viewer.extract(spec);
  inspect(map.get("a").unwrap().to(0), content="\{0b0010110}");
  inspect(map.get("b").unwrap().to(0), content="\{0b0010011011011001}");
  inspect(map.get("c").unwrap().to(0), content="\{0b1100111110001101}");
  inspect(map.get("d").unwrap().to(0), content="\{0b110}");
}
