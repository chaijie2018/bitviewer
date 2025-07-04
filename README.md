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

For a detailed usage introduction, see the [bitvector](#bitvector) and [bitviewer](#bitviewer) sections below.

## Bitvector

You can view it as an easy conversion layer between different integer types and byte arrays. It doesn't support bit operations on its own. If you want that, please use kesmeey's [immut_bitvector](https://mooncakes.io/docs/kesmeey/immut_BitVector), though it might have gone outdated.

You can use `Bitvector::from(x)` for various types of `x`, including integer types, Byte, Char, Bytes and byte array. The method `raw()` copies the content into `Bytes`, and `view()` returns its internal representation `Array[Byte]`. 

To convert it into other types, you can use the `to` method, and supply a value of type `T` as its argument to make it return type `T`. For example, `bv.to(0)` returns an `Int`, and `bv.to('_')` returns a `Char`.

## Bitviewer

The specification language goes as follows:

```antlr
Statement ::= Ident `:` Spec `;`;
Spec ::= (`<` | `>`)? Expr;
Expr ::= Mul ((`+` | `-`) Mul)*;
Mul ::= Primary ((`*` | `/`) Primary)*;
Primary ::= `(` Expr `)` | Number | Ident;

Ident ::= [A-Za-z0-9][A-Za-z0-9_]*;
Number ::= [0-9]+;
```

In human language, this means each statement is of the form `something : 1+2*(3-a);`. You can refer to values that are previously read (for example a `length` field).

Note that the `;` at the end is **mandatory**. Without it, the parser will **IGNORE** everything after the first statement that is not semicolon-terminated.

You can use `<` and `>` to specify little/big endianness, but it is only applicable on bit-length that is a multiple of 8.
