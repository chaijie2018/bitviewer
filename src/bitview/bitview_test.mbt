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

test "ref" {
  let spec =
#|length: 8;
#|string: length*8;

  let viewer = Bitviewer::new(b"\x05abcde");
  let map = viewer.extract(spec);
  inspect(map.get("length").unwrap().to(0), content="5");
  println(map.get("string")); // Some(b"\x61...\x65"), which is indeed "abcde"
}

test "range" {
  let spec =
#|opcode: 0..6;
#|rd    : 7..11;
#|funct3: 12..14;
#|rs    : 15..19;
#|rs2   : 20..24;
#|funct7: 25..31;

  // RISC-V: add x5, x10, x22
  // opcode = 0b0110011 (0x33), funct3 = funct7 = 0
  let viewer = Bitviewer::new(Bitvector::from(0x016502b3).raw());
  let map = viewer.extract(spec);
  inspect(map, content={
    "opcode": b"\x33",
    "rd": b"\x05",
    "funct3": b"\x00",
    "rs": b"\x0a", // 10
    "rs2": b"\x16", // 22
    "funct7": b"\x00",
  }.to_string())
}
