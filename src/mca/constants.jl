
const Dmin = [115.0, 125, 135, 150, 165, 185, 210, 250, 350, 475, 575, 855, 1220, 1530, 1990, 2585]
const Dmax = [125, 135, 150, 165, 185, 210, 250, 350, 475, 575, 855, 1220, 1530, 1990, 2585, 3370.0]
const DpPOPS = Dmin .+ (Dmax .- Dmin)./2.0
const dlnDpPOPS = log.(Dmax./Dmin)

const _Gtk = Gtk.ShortNames
const black = RGBA(0, 0, 0, 1)
const red = RGBA(0.55, 0.0, 0, 1)
const mblue = RGBA(0.31, 0.58, 0.8, 1)
const mgrey = RGBA(0.4, 0.4, 0.4, 1)
const lpm = 1.666666e-5
const path = mapreduce(a->"/"*a,*,(pwd() |> x->split(x,"/"))[2:3])*"/Data/"

const extp      = extrapolate(interpolate(([0, 1],),[0.0, 1],Gridded(Linear())),0)
const extpPOPS  = Signal(extp)
const δtPOPS    = Signal(0.0)
const datestr = @fetchfrom 2 DataAcquisitionLoops.datestr
const HHMM = @fetchfrom 2 DataAcquisitionLoops.HHMM

let t = @fetchfrom 2 DataAcquisitionLoops.t
    global const t1HzInt   = Signal(Dates.value.(t:Dates.Second(1):(t + Dates.Minute(1))))
    global const t10HzInt  = Signal(Dates.value.(t:Dates.Millisecond(100):(t + Dates.Minute(1))))
end

const sNoise = gui["sNoise"]
const gainMode = gui["gainMode"]
const aTime = gui["accumulationTime"]

const outfile = let a= pwd() |> x->split(x,"/")
	datestr = Dates.format(now(), "yyyymmdd")
	path = mapreduce(a->"/"*a,*,a[2:3])*"/Data/MCA/"*datestr*"/"
	read(`mkdir -p $path`)
	Signal(path*"MCA"*datestr*".mca")
end

const ch = 1:8191 |> collect
const Vlow = @. -0.594422  + 0.121933 * ch
const Vhi = @. -6.096756 + 1.21951 * ch
