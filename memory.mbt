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
  if count < 0 {
    raise Invalid("invalid data space range")
  }
  if address >= 0 &&
    address <= self.memory.length() &&
    count <= self.memory.length() - address {
    return
  }
  if address >= 65536 && address <= 66560 && count <= 66560 - address {
    return
  }
  if address >= 1048576 &&
    address - 1048576 <= self.strings.length() &&
    count <= self.strings.length() - (address - 1048576) {
    return
  }
  for frame in self.sources {
    if address >= frame.address &&
      address - frame.address <= frame.data.length() &&
      count <= frame.data.length() - (address - frame.address) {
      return
    }
  }
  raise Invalid("invalid data space range")
}

///|
fn Machine::load(
  self : Machine,
  address : Int,
  cell : Bool,
) -> Int raise ForthError {
  if address == -4 && cell {
    return if self.compilation_state { -1 } else { 0 }
  }
  if !cell && address == -4 {
    return if self.compilation_state { 255 } else { 0 }
  }
  if cell && address == -8 {
    return self.base
  }
  if cell && address == -12 {
    return self.source_frame().cursor
  }
  self.memory_range(address, if cell { 4 } else { 1 })
  if cell {
    if address % 4 != 0 {
      raise Invalid("unaligned cell address")
    }
    self.read_byte(address).to_int() |
    (self.read_byte(address + 1).to_int() << 8) |
    (self.read_byte(address + 2).to_int() << 16) |
    (self.read_byte(address + 3).to_int() << 24)
  } else {
    self.read_byte(address).to_int()
  }
}

///|
fn Machine::save(
  self : Machine,
  address : Int,
  value : Int,
  cell : Bool,
) -> Unit raise ForthError {
  if cell && address == -8 {
    if value < 2 || value > 36 {
      raise Invalid("BASE must be 2..36")
    }
    self.base = value
    return
  }
  if cell && address == -12 {
    let frame = self.source_frame()
    if value < 0 || value > frame.data.length() {
      raise Invalid("invalid input cursor")
    }
    frame.cursor = value
    return
  }
  self.memory_range(address, if cell { 4 } else { 1 })
  if cell {
    if address % 4 != 0 {
      raise Invalid("unaligned cell address")
    }
    for i in 0..<4 {
      self.write_byte(address + i, (value >> (8 * i)).to_byte())
    }
  } else {
    self.write_byte(address, value.to_byte())
  }
}
