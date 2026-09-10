///|
fn Machine::allocate(self : Machine, count : Int) -> Unit raise ForthError {
  if count < -self.memory.length() || count > 65536 - self.memory.length() {
    raise Invalid("data space limit")
  }
  if count >= 0 {
    for _ in 0..<count {
      self.memory.push(0)
    }
  } else {
    for _ in 0..<-count {
      ignore(self.memory.pop())
    }
  }
}

///|
fn Machine::memory_range(
  self : Machine,
  address : Int,
  count : Int,
) -> Unit raise ForthError {
  if address < 0 ||
    count < 0 ||
    address > self.memory.length() ||
    count > self.memory.length() - address {
    raise Invalid("invalid data space range")
  }
}

///|
fn Machine::load(
  self : Machine,
  address : Int,
  cell : Bool,
) -> Int raise ForthError {
  self.memory_range(address, if cell { 4 } else { 1 })
  if cell {
    if address % 4 != 0 {
      raise Invalid("unaligned cell address")
    }
    self.memory[address].to_int() |
    (self.memory[address + 1].to_int() << 8) |
    (self.memory[address + 2].to_int() << 16) |
    (self.memory[address + 3].to_int() << 24)
  } else {
    self.memory[address].to_int()
  }
}

///|
fn Machine::save(
  self : Machine,
  address : Int,
  value : Int,
  cell : Bool,
) -> Unit raise ForthError {
  self.memory_range(address, if cell { 4 } else { 1 })
  if cell {
    if address % 4 != 0 {
      raise Invalid("unaligned cell address")
    }
    for i in 0..<4 {
      self.memory[address + i] = (value >> (8 * i)).to_byte()
    }
  } else {
    self.memory[address] = value.to_byte()
  }
}
