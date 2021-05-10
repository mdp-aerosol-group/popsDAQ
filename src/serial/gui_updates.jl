function update_oneHz()
    frame = @fetchfrom 2 DataAcquisitionLoops.RS232dataStream.value
    set_gtk_property!(gui["Time"], :text, Dates.format((frame.t)[1], "HH:MM:SS.s"))
    if isless((frame.POPS)[1], missing)
        set_gtk_property!(gui["POPSSerial"], :text, @sprintf("%.1f", (frame.POPS)[1]))
    else
        set_gtk_property!(gui["POPSSerial"], :text, @sprintf("missing"))
    end
    if isless((frame.Q)[1], missing)
        set_gtk_property!(gui["POPSFlow"], :text, @sprintf("%.2f", (frame.Q)[1]))
    else
        set_gtk_property!(gui["POPSFlow"], :text, @sprintf("missing"))
    end

    dstr = @fetchfrom 2 DataAcquisitionLoops.datestr
    HM = @fetchfrom 2 DataAcquisitionLoops.HHMM
    push!(datestr, dstr.value)
    push!(HHMM, HM.value)
end


function update_graphs()
    tPOPS, Nt, At, Mt, POPSDistribution, POPSDistribution1 = read_pops_file()
    t = convert(Array{DateTime},tPOPS)
    Δt=convert(Int,floor(δtPOPS.value*1000))
    x = Dates.value.(t).-Δt
    y = convert(Array{Float64},Nt)
    ii = isless.(y,NaN)
	itp = interpolate((x[ii],),y[ii],Gridded(Linear()))
    push!(extpPOPS,extrapolate(itp,0))

    x = (x .- x[1])./1000.0/60.0
    xpxpA = get_gtk_property(gui["xpxp1G1"], "active-id", String)
    (xpxpA == "number") && (y = Nt)
    (xpxpA == "area") && (y = At)
    (xpxpA == "mass") && (y = Mt)
    addseries!(x,y,plotXPXP1, gplotPlotXPXP1, 1, false, true)  
    set_gtk_property!(gui["xpxp1FieldG1"], :text, @sprintf("%.1f", mean(y)))

    ii = POPSDistribution .> 0
    jj = POPSDistribution1 .> 0
    md = sum(DpPOPS.*POPSDistribution./sum(POPSDistribution))
    set_gtk_property!(gui["xpxp2FieldG1"], :text, @sprintf("%i", md))
    addseries!(DpPOPS[ii],POPSDistribution[ii], plotXPXP2, gplotPlotXPXP2, 2, false, false)
    addseries!(DpPOPS[jj],POPSDistribution1[jj], plotXPXP2, gplotPlotXPXP2, 1, false, false)

end


function read_pops_file()
    file = @fetchfrom 2 DataAcquisitionLoops.POPSdataFilename.value

    s = open(file) do io
        read(io, String)
    end

    lines = (split(s, '\n'))[2:end-1]

    a = (length(lines) > 1800) ? length(lines) - 1800 : 1

    t = map(lines[a:end]) do s
        y = split(s, ',')
        t = Dates.DateTime(y[1])
    end

    Np = map(lines[a:end]) do s
        y = split(s, ',')
        Q = parse(Float64,y[10])
        Np = map(i->parse(Float64,y[i]),14:29)./Q
    end

    Np = (hcat(Np...)')[:,:]

    POPSDistribution = map(i->mean(Np[end-5:end,i]), 1:16)
    POPSDistribution1 = map(i->mean(Np[:,i]), 1:16)

    Nt = map(i->sum(Np[i,:]), 1:length(lines[a:end]))
    At = map(i->sum(π.*(DpPOPS.*1e-3).^2.0.*Np[i,:]), 1:length(lines[a:end]))
    Mt = map(i->sum(π./6.0.*(DpPOPS.*1e-3).^3.0.*Np[i,:]), 1:length(lines[a:end]))
    t, Nt,At,Mt, POPSDistribution, POPSDistribution1
end
