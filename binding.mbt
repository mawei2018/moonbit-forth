///|
fn Machine::binding_key(self : Machine) -> String raise ForthError {
  if self.binding_id >= 65536 {
    raise Invalid("compiled binding limit exceeded")
  }
  let key = "\u0000" + self.binding_id.to_string()
  self.binding_id += 1
  key
}

///|
fn Machine::compile_word(
  self : Machine,
  name : String,
  body : Array[String],
) -> Unit raise ForthError {
  let own = self.binding_key()
  let compiled = []
  let captures : Map[String, String] = Map([])
  let controls = [
    "if", "else", "then", "begin", "while", "repeat", "until", "again", "do", "?do",
    "loop", "+loop",
  ]

  let mut pc = 0
  while pc < body.length() {
    let word = body[pc]
    pc += 1
    if word == "[']" {
      if pc >= body.length() {
        raise Invalid("missing execution token name")
      }
      compiled.push(self.capture_xt(body[pc]).to_string())
      pc += 1
    } else if word == "recurse" {
      compiled.push(own)
    } else if controls.contains(word) || number(word) is Some(_) {
      compiled.push(word)
    } else if self.words.get(word) is Some(target) {
      let key = match captures.get(word) {
        Some(key) => key
        None => {
          let key = self.binding_key()
          self.words[key] = target
          captures[word] = key
          key
        }
      }
      compiled.push(key)
    } else if primitive_word(word) {
      compiled.push("\u0001" + word)
    } else {
      raise Invalid("unknown or unsupported compile-time word: " + word)
    }
  }
  self.words[own] = compiled
  self.words[name] = compiled
}

///|
fn primitive_word(word : String) -> Bool {
  [
    "dup", "drop", "swap", "over", "rot", "nip", "tuck", "2dup", "2drop", "2swap",
    "here", "allot", "align", "aligned", "cells", "cell+", "@", "c@", "!", "c!",
    "+!", ",", "c,", "fill", "erase", "move", "0=", "0<", "0>", "1+", "1-", "i",
    "j", "exit", "unloop", "leave", ">r", "r>", "r@", "2>r", "2r>", "2r@", "depth",
    ".", "negate", "+", "-", "*", "/", "mod", "=", "<", ">", "and", "or", "execute",
    "variable", "constant", "create", "'",
  ].contains(word)
}
