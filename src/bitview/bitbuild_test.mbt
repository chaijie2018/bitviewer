test "arith" {
  let spec =
#|h1 : 3*5-4+1;
#|h2 : 4;
  
  let viewer = Bitviewer::build(spec, {
    "h1": 0x234,
    "h2": 1
  });
  inspect(viewer.raw(), content=b"\x34\x12".to_string());
  inspect(viewer.raw().to(0), content="\{0x1234}");
}

test "endian" {
  let viewer = Bitviewer::build("rev: >32", { "rev": 0x12345678 });
  inspect(viewer.raw(), content=b"\x12\x34\x56\x78".to_string());
}
