priv enum Endianness { Little; Big; Unspecified } derive(Show)

priv enum Kind {
  Add; Sub; Mul; Div;
} derive(Show)

priv enum Expr {
  Const(Int)
  Var(String)
  Binary(Kind, Expr, Expr)
} derive(Show)

priv struct Spec {
  endian: Endianness
  from: Expr?
  len: Expr
} derive(Show)

pub suberror Malformed(String) derive(Show)

fn disspace(str: String) -> Array[Char] {
  let chars = str.to_array()
  chars.filter((x) => not(x.is_whitespace()));
}

fn primary(lexer: Lexer) -> Expr raise Malformed {
  match lexer.peek() {
    '0'..='9' => Const(lexer.number())
    '(' => {
      let x = expr(lexer);
      if (lexer.ch() != ')') {
        raise Malformed("unclosed parentheses")
      }
      x
    }
    _ => Var(lexer.ident())
  }
}

fn mul(lexer: Lexer) -> Expr raise Malformed {
  let mut n = primary(lexer);
  while (lexer.pos < lexer.chars.length()) {
    match lexer.ch() {
      '*' => {
        let x = primary(lexer);
        n = Binary(Mul, n, x);
      }
      '/' => {
        let x = primary(lexer);
        n = Binary(Div, n, x);
      }
      _ => { lexer.pos -= 1; break; }
    }
  }
  n
}

fn add(lexer: Lexer) -> Expr raise Malformed {
  let mut n = mul(lexer);
  while (lexer.pos < lexer.chars.length()) {
    match lexer.ch() {
      '+' => {
        let x = mul(lexer);
        n = Binary(Add, n, x);
      }
      '-' => {
        let x = mul(lexer);
        n = Binary(Sub, n, x);
      }
      _ => { lexer.pos -= 1; break; }
    }
  }
  n
}

fn expr(lexer: Lexer) -> Expr raise Malformed {
  add(lexer)
}

fn parse(spec: ArrayView[Char]) -> Spec raise Malformed {
  let mut place = 0;
  let peek = () => spec[place];

  let endian = match peek() {
    '>' => { place += 1; Big }
    '<' => { place += 1; Little }
    _ => Unspecified
  };
  
  let lexer = { chars: Array::from_iter(spec[place:].iter()), pos: 0 };
  let mut len = expr(lexer);
  let mut from = None;
  if (lexer.check("..")) {
    from = Some(len);
    // len = stop - start + 1 (inclusive)
    len = Binary(Add, Const(1), Binary(Sub, expr(lexer), len));
  }
  
  { endian, from, len }
}

fn parse_spec(str: String) -> Map[String, Spec] raise Malformed {
  let fields = disspace(str).split((x) => x == ';');
  let result = {};
  for field in fields {
    let colon = field.search_by((x) => x == ':');
    guard (colon is Some(ind)) else {
      raise Malformed("missing colon");
    }
    let name = field[:ind];
    let spec = parse(field[ind+1:]);
    result[String::from_iter(name.iter())] = spec;
  }
  result
}

fn eval(expr: Expr, k: Map[String, @bitvec.Bitvector]) -> Int {
  match expr {
    Binary(Add, x, y) => eval(x, k) + eval(y, k)
    Binary(Sub, x, y) => eval(x, k) - eval(y, k)
    Binary(Mul, x, y) => eval(x, k) * eval(y, k)
    Binary(Div, x, y) => eval(x, k) / eval(y, k)
    Const(x) => x
    Var(y) => k.get(y).unwrap().to(0)
  }
}
