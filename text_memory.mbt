///|
fn Machine::read_bytes(
  self : Machine,
  address : Int,
  count : Int,
) -> Array[Byte] raise ForthError {
  self.memory_range(address, count)
  Array::makei(count, i => self.read_byte(address + i))
}

///|
fn Machine::read_byte(self : Machine, address : Int) -> Byte raise ForthError {
  if address >= 0 && address < self.memory.length() {
    return self.memory[address]
  }
  if address >= 65536 && address < 66560 {
    return self.scratch[address - 65536]
  }
  if address >= 1048576 && address - 1048576 < self.strings.length() {
    return self.strings[address - 1048576]
  }
  for frame in self.sources {
    if address >= frame.address && address - frame.address < frame.data.length() {
      return frame.data[address - frame.address]
    }
  }
  raise Invalid("invalid data space range")
}

///|
fn Machine::write_byte(
  self : Machine,
  address : Int,
  value : Byte,
) -> Unit raise ForthError {
  if address >= 0 && address < self.memory.length() {
    self.memory[address] = value
  } else if address >= 65536 && address < 66560 {
    self.scratch[address - 65536] = value
  } else {
    raise Invalid("invalid or read-only data space range")
  }
}

///|
fn Machine::write_text(self : Machine, text : String) -> Unit raise ForthError {
  self.write_bytes(@utf8.encode(text).to_array())
}

///|
fn Machine::write_bytes(
  self : Machine,
  bytes : Array[Byte],
) -> Unit raise ForthError {
  if self.terminal.length() + bytes.length() > 2000000 {
    raise Invalid("output byte limit")
  }
  for byte in bytes {
    self.terminal.push(byte)
  }
}

///|
pub fn Machine::output_bytes(self : Machine) -> Bytes {
  Bytes::from_array(self.terminal[:])
}

///|
pub fn Machine::output_text(self : Machine) -> String {
  @utf8.decode_lossy(self.output_bytes()[:])
}

///|
pub fn Machine::clear_output(self : Machine) -> Unit {
  self.terminal.clear()
  self.output.clear()
}
