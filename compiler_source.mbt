///|
priv struct Compiler {
  own : String
  name : String
  old_binding : Int
  old_tokens : Int
  stack_depth : Int
  mut bracket_stack : Array[Int]?
  output : Array[String]
  captures : Map[String, String]
  pending : Map[String, Array[String]]
  mut after_does : Bool
} derive(Debug)

///|
fn Machine::compile_token(
  self : Machine,
  compiler : Compiler,
  word : String,
  depth : Int,
) -> Unit raise ForthError {
  let output = compiler.output
  if output.length() >= 65536 {
    raise Invalid("compiled definition limit")
  }
  if string_word(word) {
    for token in self.string_code(word) {
      output.push(token)
    }
  } else if word == "[char]" {
    output.push(@utf8.encode(self.source_name())[0].to_int().to_string())
  } else if word == "postpone" {
    self.postpone_into(self.source_name().to_lower(), output)
  } else if word == "[" {
    compiler.bracket_stack = Some(self.stack.copy())
    self.compilation_state = false
  } else if word == "literal" {
    output.push(self.pop().to_string())
  } else if word == "does>" {
    compiler.after_does = true
    output.push("\u0001does>")
  } else if word == "[']" {
    output.push(self.capture_xt(self.source_name().to_lower()).to_string())
  } else if word == "recurse" {
    if compiler.after_does {
      raise Invalid("RECURSE after DOES> is unsupported")
    }
    output.push(compiler.own)
  } else if control_word(word) {
    output.push(word)
  } else if self.words.get(word) is Some(target) {
    if self.immediate_words.get(word) == Some(true) {
      self.execute_frame(target, depth + 1, true)
    } else {
      let key = match compiler.captures.get(word) {
        Some(key) => key
        None => {
          let key = self.binding_key()
          compiler.pending[key] = target
          compiler.captures[word] = key
          key
        }
      }
      output.push(key)
    }
  } else if primitive_word(word) {
    output.push("\u0001" + word)
  } else if self.read_number(word) is Some(n) {
    output.push(n.to_string())
  } else {
    raise Invalid("unknown or unsupported compile-time word: " + word)
  }
}

///|
fn Machine::compile_word(
  self : Machine,
  name : String,
  _depth : Int,
) -> Unit raise ForthError {
  if self.active_compiler is Some(_) {
    raise Invalid("nested compilation")
  }
  let old_binding = self.binding_id
  let own = self.binding_key()
  let compiler = Compiler::{
    own,
    name,
    old_binding,
    old_tokens: self.execution_tokens.length(),
    stack_depth: self.stack.length(),
    bracket_stack: None,
    output: [],
    captures: Map([]),
    pending: Map([]),
    after_does: false,
  }
  self.compilation_state = true
  self.compile_output = Some(compiler.output)
  self.active_compiler = Some(compiler)
  self.compile_eval = true
}

///|
fn Machine::abort_compilation(self : Machine) -> Unit {
  if self.active_compiler is Some(compiler) {
    self.binding_id = compiler.old_binding
    while self.execution_tokens.length() > compiler.old_tokens {
      ignore(self.execution_tokens.pop())
    }
    if compiler.bracket_stack is Some(saved) {
      self.stack.clear()
      for value in saved {
        self.stack.push(value)
      }
    }
  }
  self.active_compiler = None
  self.compile_output = None
  self.compilation_state = false
  self.compile_eval = false
}

///|
fn Machine::finish_compilation(
  self : Machine,
  compiler : Compiler,
) -> Unit raise ForthError {
  if self.stack.length() != compiler.stack_depth {
    raise Thrown(-2)
  }
  validate_structure(
    compiler.output.map(word => {
      if word == "\u0001does>" {
        "does>"
      } else {
        word
      }
    }),
  )
  for key, target in compiler.pending {
    self.words[key] = target
  }
  self.words[compiler.own] = compiler.output
  self.words[compiler.name] = compiler.output
  self.latest_created = None
  let anonymous = compiler.name.has_prefix("\u0000")
  self.latest_name = if anonymous { None } else { Some(compiler.name) }
  self.immediate_words[compiler.name] = false
  self.active_compiler = None
  self.compile_output = None
  self.compilation_state = false
  self.compile_eval = false
  if anonymous {
    self.stack.push(self.capture_xt(compiler.name))
  }
}
