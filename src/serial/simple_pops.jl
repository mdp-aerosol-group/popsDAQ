# Simple script to test if the POPS is reading correctly from the serial port

using LibSerialPort
using Dates
using Reactive
using DataStructures

include("serial_io.jl")

const POPSLine = Signal(CircularBuffer{String}(10))

port, type = configure_port(:POPS, "/dev/ttyUSB0")

read_POPS(port,"/dev/null")