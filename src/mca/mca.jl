spectra = Signal(CircularBuffer{Array{Float64,1}}(120))
map(_->push!(spectra.value, zeros(8191)), 1:120)

mca8000d = device()                  # Open the device
mca8000d.disable_MCA_MCS() 
status=mca8000d.reqStatus()          # Read the configuration
printStatus(status)   

function write_cfg()
    config=mca8000d.reqHWConfig()        # Read hardware config
    ctime = Dates.format(now(), "yyyymmddTHHMMSS")
    config |> CSV.write(path*ctime*".cfg", append=true)
    push!(outfile, path*ctime*".mca")
end

function set_noise(;write=true)
    nl = get_gtk_property(sNoise, "value", Float64)
    str = @sprintf("THSL=%0.1f;",nl)
    mca8000d.sendCmdConfig(str)
    if write==true
        write_cfg()
    end  
end
signal_connect(sNoise, "changed") do widget, others...
    set_noise()
end

function set_gain(;write=true)
    thegain = get_gtk_property(gainMode, "active-id", String) 
    str = (thegain == "1") ? "GAIA=1;" : "GAIA=2;"
    mca8000d.sendCmdConfig(str)  
    if write==true
        write_cfg()
    end  
end
signal_connect(gainMode, "changed") do widget, others...
    set_gain()
end

mca8000d.sendCmdConfig("PRER=OFF;")  
set_gain(write=false)
set_noise(write=true)
sleep(1)
mca8000d.enable_MCA_MCS()            
function acquire_mca()
    s = mca8000d.spectrum(true,true)  
    push!(spectra.value, s[1])
    open(outfile.value, "a") do io
        writedlm(io, vcat(Dates.value(now()), s[1])', ',')
    end
end
