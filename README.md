# AdUhTkJm/bitviewer

This is a binary parser. It uses C-bitfield like syntax to guide parsing. Moreover, it carries a data structure `Bitvector` that represents bits and allows conversion between different types.

A simple example:

```mbt
let spec =
#|a : 3;
#|b : 4;

// 7'b1011_100
let viewer = Bitviewer::new(b"\x5c");
let map = viewer.extract(spec); // a: 4, b: 11
// This is because `a` is 3'b100 = 4, and `b` is 4'b1011, which is 11.
```

It also allows specifying big and little endian. The default is little endian. In future versions, it might be configurable.

The following example turns a little endian `int32_t` to big endian.

```mbt
let spec = "rev: >32";
let viewer = Bitviewer::new(Bitvector::from(0x12345678).raw())
let map = viewer.extract(spec);
inspect(map.get("rev").unwrap().to(0), content="\{0x78563412}");
```

Moreover, if you want to specify the exact location, you can do it:

```mbt
// RISC-V instruction format, R-type
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
```

Note the `..` is inclusive on both ends.

Besides extracting bits, you can also build up bits from a specification:

```mbt
let spec =
#|h1 : 3*5-4+1;
#|h2 : 4;

let viewer = Bitviewer::build(spec, {
  "h1": 0x234,
  "h2": 1
});
// This will return a bitvector.
viewer.raw();
// The content is 0x3412, because it's little endian by default. As an int, it's 0x1234.
```

For a detailed usage introduction, see the [bitvector](#bitvector) and [bitviewer](#bitviewer) sections below.

## Bitvector

You can view it as an easy conversion layer between different integer types and byte arrays. It doesn't support bit operations on its own. If you want that, please use kesmeey's [immut_bitvector](https://mooncakes.io/docs/kesmeey/immut_BitVector), though it might have gone outdated.

You can use `Bitvector::from(x)` for various types of `x`, including integer types, Byte, Char, Bytes and byte array. The method `raw()` copies the content into `Bytes`, and `view()` returns its internal representation `Array[Byte]`. 

To convert it into other types, you can use the `to` method, and supply a value of type `T` as its argument to make it return type `T`. For example, `bv.to(0)` returns an `Int`, and `bv.to('_')` returns a `Char`.

The method `set(from, to, bv)` will copy the content of the argument `bv` to the bits `[from:to]`. Moreover, you can use the view syntax `bv[from:to]` to extract bits from the bitvector.

## Bitviewer

The specification language goes as follows:

```antlr
Statement ::= Ident `:` Spec `;`;
Spec ::= (`<` | `>`)? Expr;
Expr ::= Add `..` Add | Add;
Add ::= Mul ((`+` | `-`) Mul)*;
Mul ::= Primary ((`*` | `/`) Primary)*;
Primary ::= `(` Expr `)` | Number | Ident;

Ident ::= [A-Za-z0-9][A-Za-z0-9_]*;
Number ::= [0-9]+;
```

In human language, this means each statement is of the form `something : 1+2*(3-a);`. You can refer to values that are previously read (for example a `length` field).

Note that the `;` at the end is **mandatory**. Without it, the parser will **IGNORE** everything after the first statement that is not semicolon-terminated.

You can use `<` and `>` to specify little/big endianness, but it is only applicable on bit-length that is a multiple of 8.
