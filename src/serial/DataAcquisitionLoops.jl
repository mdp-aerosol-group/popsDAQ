@everywhere module DataAcquisitionLoops

using Reactive, DataStructures, Dates, CSV, DataFrames, Printf

include("serial_io.jl")              

t = now()

const datestr = Signal(Dates.format(now(), "yyyymmdd"))
const HHMM = Signal(Dates.format(now(), "HHMM"))
const path = mapreduce(a->"/"*a,*,(pwd() |> x->split(x,"/"))[2:3])*"/Data/"

# Calibration values from POPS manual
Dmin = [115.0, 125, 135, 150, 165, 185, 210, 250, 350, 475, 575, 855, 1220, 1530, 1990, 2585]
Dmax = [125, 135, 150, 165, 185, 210, 250, 350, 475, 575, 855, 1220, 1530, 1990, 2585, 3370.0]
const Dp = Dmin .+ (Dmax .- Dmin)./2.0
const POPSdataFilename = Signal(path*"POPSdataStream_"*datestr.value*"_"*HHMM.value*".txt")
const POPSLine = Signal(CircularBuffer{String}(10))

const rs = DataFrame(t=t,tint=Dates.value(t),POPS=0.0,Q=0.0,POPSDistribution=[Dp])
const RS232dataFilename = Signal(path*"RS232dataStream_"*datestr.value*"_"*HHMM.value*".csv")
const RS232dataStream = Signal(rs)
RS232dataStream.value |> CSV.write(RS232dataFilename.value)

const newDay = map(droprepeats(datestr)) do x
    push!(HHMM, Dates.format(now(), "HHMM"))
    push!(POPSdataFilename, path*"POPSdataStream_"*datestr.value*"_"*HHMM.value*".txt")
    push!(RS232dataFilename, path*"RS232dataStream_"*datestr.value*"_"*HHMM.value*".csv")
end

function RScircBuff(n)
    t = CircularBuffer{DateTime}(n)
    POPS = CircularBuffer{Float64}(n)
    Q = CircularBuffer{Float64}(n)
    POPSDistribution = CircularBuffer{Array{Float64,1}}(n)

    (t=t,POPS=POPS,Q=Q,POPSDistribution=POPSDistribution)
end

const RS232Buffers = Signal(RScircBuff(1810))  

function oneHz_daq_loop()
    push!(datestr,Dates.format(now(), "yyyymmdd"))
    RS232dataStream.value |> CSV.write(RS232dataFilename.value, append=true)
    frame = RS232dataStream.value

    push!(RS232Buffers.value.t, (frame.t)[1])
    push!(RS232Buffers.value.POPS, (frame.POPS)[1])
    push!(RS232Buffers.value.Q, (frame.Q)[1])
    push!(RS232Buffers.value.POPSDistribution, (frame.POPSDistribution)[1])
end

# Asynchronous DAQ loops
function aquire(LJID)
    portPOPS, typePOPS = configure_port(:POPS, "/dev/ttyUSB0")
    LibSerialPort.sp_drain(portPOPS)
    LibSerialPort.sp_flush(portPOPS, SP_BUF_OUTPUT)
    for i = 1:20
        nbytes_read, bytes = LibSerialPort.sp_nonblocking_read(portPOPS,  10000)
    end

    oneHz = every(1.0)      
    serialDAQ   = map(_->serial_read(portPOPS,POPSdataFilename.value), oneHz)
    oneHzDAQ    = map(_->(@async oneHz_daq_loop()), serialDAQ)

    empty!(RS232Buffers.value.t)
    empty!(RS232Buffers.value.POPS)
    empty!(RS232Buffers.value.Q)
    empty!(RS232Buffers.value.POPSDistribution)

    serialDAQ, oneHzDAQ
end

end
