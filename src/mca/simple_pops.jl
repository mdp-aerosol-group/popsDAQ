# Simple script to test if the POPS is reading correctly from the serial port

using LibSerialPort
using Dates
using Reactive
using DataStructures
using DataFrames

include("serial_io.jl")

const POPSLine = Signal(CircularBuffer{String}(10))

port, type = configure_port(:POPS, "/dev/ttyUSB0")


t = now()
const datestr = Signal(Dates.format(now(), "yyyymmdd"))
const HHMM = Signal(Dates.format(now(), "HHMM"))
const path = mapreduce(a->"/"*a,*,(pwd() |> x->split(x,"/"))[2:3])*"/Data/"

Dmin = [70.0, 165.0, 185.0, 205.0,235.0,290.0, 365.0, 512.0,560.0,637.0,960.0,1180.0,1480.0, 1530, 1990, 2585]
Dmax = [165.0, 185.0, 205.0,235.0,290.0, 365.0, 512.0,560.0,637.0,960.0,1180.0,1480.0, 1530, 1990, 2585, 3370.0]

# Dmin = [115.0, 125, 135, 150, 165, 185, 210, 250, 350, 475, 575, 855, 1220, 1530, 1990, 2585]
# Dmax = [125, 135, 150, 165, 185, 210, 250, 350, 475, 575, 855, 1220, 1530, 1990, 2585, 3370.0]
const Dp = Dmin .+ (Dmax .- Dmin)./2.

const POPSdataFilename = Signal(path*"POPSdataStream_"*datestr.value*"_"*HHMM.value*".txt")
const POPSLine = Signal(CircularBuffer{String}(10))

const rs = DataFrame(t=t,tint=Dates.value(t),POPS=0.0,Q=0.0,POPSDistribution=[Dp])
const RS232dataFilename = Signal(path*"RS232dataStream_"*datestr.value*"_"*HHMM.value*".csv")
const RS232dataStream = Signal(rs)


Nt, Q, dN = read_POPS(port,"/dev/null")
serial_read(port, "/dev/null"); println(RS232dataStream)
