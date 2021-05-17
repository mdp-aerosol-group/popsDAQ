@everywhere module MCA

using Distributed
using DataStructures
using Reactive
using AmptekMCA8000D
using DelimitedFiles
using Dates
using CSV

const path = mapreduce(a -> "/" * a, *, (pwd()|>x->split(x, "/"))[2:3]) * "/Data/MCA/"
const datestr = Signal(Dates.format(now(), "yyyymmdd"))
const HH = Signal(Dates.format(now(), "HH"))
const spectra = Signal(CircularBuffer{Array{Float64,1}}(100))
const MCAdataFilename =
    Signal(path * "MCAdataStream_" * datestr.value * "_" * HH.value * "00.txt")
map(_ -> push!(spectra.value, zeros(8191)), 1:100)

function acquire_mca()
    mca8000d = device()                    # Open the device
    mca8000d.disable_MCA_MCS()
    status = mca8000d.reqStatus()          # Read the configuration
    println("Here")
    printStatus(status)

    mca8000d.sendCmdConfig("THSL=0.05;")
    mca8000d.sendCmdConfig("GAIA=1;")
    mca8000d.sendCmdConfig("PRER=OFF;")
    mca8000d.enable_MCA_MCS()

    config = mca8000d.reqHWConfig()        # Read hardware config
    ctime = Dates.format(now(), "yyyymmddTHHMMSS")
    config |> CSV.write(path * ctime * ".cfg", append = true)

    tenHz = every(0.1)

    s1 = map(droprepeats(HH)) do _
        push!(
            MCAdataFilename,
            path * "MCAdataStream_" * datestr.value * "_" * HH.value * "00.txt",
        )
    end

    s2 = map(tenHz) do _
        push!(HH, Dates.format(now(), "HH"))
        push!(datestr, Dates.format(now(), "yyyymmdd"))

        s = mca8000d.spectrum(true, true)
        push!(spectra.value, s[1])
        open(MCAdataFilename.value, "a") do io
            writedlm(io, vcat(Dates.value(now()), s[1])', ',')
        end
    end

    return s1, s2
end

end
