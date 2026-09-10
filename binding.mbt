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
  validate_structure(body)
  let old_binding_id = self.binding_id
  let old_tokens = self.execution_tokens.length()
  errdefer {
    self.binding_id = old_binding_id
    while self.execution_tokens.length() > old_tokens {
      ignore(self.execution_tokens.pop())
    }
  }
  let pending : Map[String, Array[String]] = Map([])
  let own = self.binding_key()
  let compiled = []
  let previous_output = self.compile_output
  self.compile_output = Some(compiled)
  defer {
    self.compile_output = previous_output
  }
  let captures : Map[String, String] = Map([])
  let controls = [
    "if", "else", "then", "begin", "while", "repeat", "until", "again", "do", "?do",
    "loop", "+loop",
  ]

  let mut after_does = false
  let mut pc = 0
  while pc < body.length() {
    let word = body[pc]
    pc += 1
    if word == "[" {
      let (chunk, next) = bracket_chunk(body, pc)
      pc = next
      self.interpret_compile_chunk(chunk)
    } else if word == "literal" {
      compiled.push(self.pop().to_string())
    } else if word == "does>" {
      after_does = true
      compiled.push("\u0001does>")
    } else if word == "[']" {
      if pc >= body.length() {
        raise Invalid("missing execution token name")
      }
      compiled.push(self.capture_xt(body[pc]).to_string())
      pc += 1
    } else if word == "recurse" {
      if after_does {
        raise Invalid("RECURSE after DOES> is unsupported")
      }
      compiled.push(own)
    } else if controls.contains(word) || number(word) is Some(_) {
      compiled.push(word)
    } else if self.words.get(word) is Some(target) {
      if self.immediate_words.get(word) == Some(true) {
        pc = self.run_immediate(target, body, pc)
        continue
      }
      let key = match captures.get(word) {
        Some(key) => key
        None => {
          let key = self.binding_key()
          pending[key] = target
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
  for key, target in pending {
    self.words[key] = target
  }
  self.words[own] = compiled
  self.words[name] = compiled
  self.latest_created = None
  self.latest_name = if name.has_prefix("\u0000") { None } else { Some(name) }
  self.immediate_words[name] = false
}

///|
fn primitive_word(word : String) -> Bool {
  [
    "dup", "drop", "swap", "over", "rot", "nip", "tuck", "2dup", "2drop", "2swap",
    "here", "allot", "align", "aligned", "cells", "cell+", "@", "c@", "!", "c!",
    "+!", ",", "c,", "fill", "erase", "move", "0=", "0<", "0>", "1+", "1-", "i",
    "j", "exit", "unloop", "leave", ">r", "r>", "r@", "2>r", "2r>", "2r@", "depth",
    ".", "negate", "+", "-", "*", "/", "mod", "=", "<", ">", "and", "or", "execute",
    "variable", "constant", "create", "'", ">body", "immediate", "compile,",
  ].contains(word)
}
