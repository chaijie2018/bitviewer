priv struct Lexer {
  chars: Array[Char]
  mut pos: Int
}

fn Lexer::ch(self: Lexer) -> Char raise Malformed {
  if (self.pos == self.chars.length()) {
    raise Malformed("unexpected end of statement")
  }
  let c = self.chars[self.pos]
  self.pos += 1;
  c
}

fn Lexer::peek(self: Lexer) -> Char raise Malformed {
  if (self.pos == self.chars.length()) {
    raise Malformed("unexpected end of statement")
  }
  self.chars[self.pos]
}

fn Lexer::number(self: Lexer) -> Int raise Malformed {
  let digits = []
  while self.pos < self.chars.length() && self.chars[self.pos].is_digit(10) {
    digits.push(self.chars[self.pos])
    self.pos += 1
  }
  
  if digits.is_empty() {
    raise Malformed("expected digit")
  }
  
  let number_str = String::from_iter(digits.iter())
  match (try? @strconv.parse_int(number_str)) {
    Ok(num) => num
    Err(_) => raise Malformed("invalid number: \{number_str}")
  }
}

fn Lexer::ident(self: Lexer) -> String raise Malformed {
  if self.pos >= self.chars.length() {
    raise Malformed("expected identifier")
  }
  
  let first_char = self.chars[self.pos]
  if not(first_char.is_ascii_alphabetic() || first_char == '_') {
    raise Malformed("identifier must start with letter or underscore")
  }
  
  let chars = []
  while self.pos < self.chars.length() {
    let c = self.chars[self.pos]
    if c.is_ascii_alphabetic() || c.is_digit(10) || c == '_' {
      chars.push(c)
      self.pos += 1
    } else {
      break
    }
  }
  
  if chars.is_empty() {
    raise Malformed("expected identifier")
  }
  
  String::from_iter(chars.iter())
}

fn Lexer::check(self: Lexer, str: String) -> Bool {
  if (self.pos + str.length() > self.chars.length()) {
    return false;
  }
  let old = self.pos;
  for i in str {
    if ((try? self.ch()).unwrap() != i) {
      self.pos -= 1;
      self.pos = old;
      return false;
    }
  }
  true
}
