@everywhere module DataAcquisitionLoops

using Reactive, DataStructures, Dates, CSV, DataFrames, Printf

include("serial_io.jl")               # Serial Data Aquisition

# Raw data streams - single record saved in named tuples. The named tuple entry
#                    is appended to the data file upon receipt and values are then
#                    added to the circular buffers beliw
# RS232 Data
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

const rs = DataFrame(t=t,tint=Dates.value(t),POPS=0.0,POPSDistribution=[Dp])
const RS232dataFilename = Signal(path*"RS232dataStream_"*datestr.value*"_"*HHMM.value*".csv")
const RS232dataStream = Signal(rs)
RS232dataStream.value |> CSV.write(RS232dataFilename.value)

# LJ Data
# const lj = DataFrame(t=t,tint=Dates.value(t),u=0.0,v=0.0,w=0.0,vel=0.0,dir=0.0,T=0.0,c1=0,c2=0,
#                                              CPC1=0.0,CPC2=0.0,Tlj=0.0,Trot=0.0,RHrot=0.0)
# const LJdataFilename = Signal(path*"RS232dataStream_"*datestr.value*"_"*HHMM.value*".csv")
# const LJdataStream = Signal(lj)
# LJdataStream.value |> CSV.write(LJdataFilename.value)

const newDay = map(droprepeats(datestr)) do x
    push!(HHMM, Dates.format(now(), "HHMM"))
    push!(POPSdataFilename, path*"POPSdataStream_"*datestr.value*"_"*HHMM.value*".txt")
    push!(RS232dataFilename, path*"RS232dataStream_"*datestr.value*"_"*HHMM.value*".csv")
end

# Circular Buffers - these buffers hold a time history of the data
#                    these form the basis of the interpolation below
# function LJcircBuff(n)
#     t = CircularBuffer{DateTime}(n)
#     u = CircularBuffer{Float64}(n)
#     v = CircularBuffer{Float64}(n)
#     w = CircularBuffer{Float64}(n)
#     T = CircularBuffer{Float64}(n)
#     q = CircularBuffer{Float64}(n)
#     vel = CircularBuffer{Float64}(n)
#     dir = CircularBuffer{Float64}(n)
#     CPC1 = CircularBuffer{Float64}(n)
#     CPC2 = CircularBuffer{Float64}(n)
#
#     (t=t,u=u,v=v,w=w,vel=vel,dir=dir,T=T,q=q,CPC1=CPC1,CPC2=CPC2)
# end
#const LJBuffers    = Signal(LJcircBuff(18000))  # 30 min @ 10 Hz

function RScircBuff(n)
    t = CircularBuffer{DateTime}(n)
    POPS = CircularBuffer{Float64}(n)
    POPSDistribution = CircularBuffer{Array{Float64,1}}(n)

    (t=t,POPS=POPS,POPSDistribution=POPSDistribution)
end
const RS232Buffers = Signal(RScircBuff(1810))   # 30 min @  1 Hz

function oneHz_daq_loop()
    push!(datestr,Dates.format(now(), "yyyymmdd"))
    RS232dataStream.value |> CSV.write(RS232dataFilename.value, append=true)
    frame = RS232dataStream.value

    push!(RS232Buffers.value.t, (frame.t)[1])
    push!(RS232Buffers.value.POPS, (frame.POPS)[1])
    push!(RS232Buffers.value.POPSDistribution, (frame.POPSDistribution)[1])
end

# function tenHz_daq_loop()
#     LJdataStream.value |> CSV.write(LJdataFilename.value, append=true)
#     frame = LJdataStream.value
#
#     push!(LJBuffers.value.t, (frame.t)[1])
#     push!(LJBuffers.value.u, (frame.u)[1])
#     push!(LJBuffers.value.v, (frame.v)[1])
#     push!(LJBuffers.value.w, (frame.w)[1])
#     push!(LJBuffers.value.vel, (frame.vel)[1])
#     push!(LJBuffers.value.dir, (frame.dir)[1])
#     push!(LJBuffers.value.T, (frame.T)[1])
#     push!(LJBuffers.value.q, (frame.RHrot)[1])
#     push!(LJBuffers.value.CPC1, (frame.CPC1)[1])
#     push!(LJBuffers.value.CPC2, (frame.CPC2)[1])
# end

# Asynchronous DAQ loops
function aquire(LJID)
    # HANDLE = openUSBConnection(LJID)
    # caliInfo = getCalibrationInformation(HANDLE)

    portPOPS, typePOPS = configure_port(:POPS, "/dev/ttyUSB0")
    sp_drain(portPOPS)
    sp_flush(portPOPS, SP_BUF_OUTPUT)
    for i = 1:20
        nbytes_read, bytes = sp_nonblocking_read(portPOPS,  10000)
    end

    oneHz = every(1.0)      # 1  Hz timer for RS232

    # DAQ Loops
    #labjackDAQ  = map(_->synthetic_labjack(),tenHz)
    #labjackDAQ  = map(_->labjackReadWrite(HANDLE, caliInfo),tenHz)
    #tenHzDAQ    = map(_->(@async tenHz_daq_loop()), labjackDAQ)
    serialDAQ   = map(_->serial_read(portPOPS,POPSdataFilename.value), oneHz)
    oneHzDAQ    = map(_->(@async oneHz_daq_loop()), serialDAQ)

    # Empty all buffers for a clean start
    # empty!(LJBuffers.value.t)
    # empty!(LJBuffers.value.u)
    # empty!(LJBuffers.value.v)
    # empty!(LJBuffers.value.w)
    # empty!(LJBuffers.value.vel)
    # empty!(LJBuffers.value.dir)
    # empty!(LJBuffers.value.T)
    # empty!(LJBuffers.value.q)
    # empty!(LJBuffers.value.CPC1)
    # empty!(LJBuffers.value.CPC2)

    empty!(RS232Buffers.value.t)
    empty!(RS232Buffers.value.POPS)
    empty!(RS232Buffers.value.POPSDistribution)

    serialDAQ, oneHzDAQ
end

end
