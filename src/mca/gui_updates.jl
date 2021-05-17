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
	
	buf = @fetchfrom 2 DataAcquisitionLoops.RS232Buffers
	tPOPS = buf.value.t
	Nt = buf.value.POPS |> x -> x[:]
	pd = hcat(buf.value.POPSDistribution...)
	POPSDistribution = mean(pd, dims = 2) |> x -> x[:]
	POPSDistribution1 = pd[:,end]
	x = Dates.value.(tPOPS) 
	x = (x .- x[1])./1000.0/60.0
    xpxpA = get_gtk_property(gui["xpxp1G1"], "active-id", String)
    (xpxpA == "number") && (y = Nt)
    (xpxpA == "area") && (y = Nt)
    (xpxpA == "mass") && (y = Nt)
    addseries!(x,y,plotXPXP1, gplotPlotXPXP1, 1, false, true)  
    set_gtk_property!(gui["xpxp1FieldG1"], :text, @sprintf("%.1f", mean(y)))

    ii = POPSDistribution .> 0
    jj = POPSDistribution1 .> 0
    md = sum(DpPOPS.*POPSDistribution./sum(POPSDistribution))
    set_gtk_property!(gui["xpxp2FieldG1"], :text, @sprintf("%i", md))
    addseries!(DpPOPS[ii],POPSDistribution[ii], plotXPXP2, gplotPlotXPXP2, 2, false, false)
    addseries!(DpPOPS[jj],POPSDistribution1[jj], plotXPXP2, gplotPlotXPXP2, 1, false, false)

    n = get_gtk_property(aTime, "value", Int)
    my_spectra = @fetchfrom 3 MCA.spectra
    subsetSpectra = hcat(my_spectra.value[end-n+1:end]...)    
    y = mean(subsetSpectra, dims=2)
    meanC = sum(y)

    thegain = get_gtk_property(gainMode, "active-id", String) 
    V = (thegain == "1") ? Vlow : Vhi

    qstr = get_gtk_property(gui["POPSFlow"], :text, String) 
    nx = parse(Float64, qstr)

    meanV = sum(V.*y)./sum(y)
    set_gtk_property!(gui["meanV"], :text, @sprintf("%.1f", meanV))
	set_gtk_property!(gui["meanC"], :text, @sprintf("%.1f", meanC*10/nx))

    rx = map(i->mean(V[i:i+4]),1:8:length(y)-8)
    ry = map(i->mean(10.0.*y[i:i+4]),1:8:length(y)-8)
    ry[ry .< 0.01] .= 0.01
    plotInt.xext = InspectDR.PExtents1D() 
    if (thegain == "1") 
        plotInt.xext_full = InspectDR.PExtents1D(0.001, 0.1)
    else
        plotInt.xext_full = InspectDR.PExtents1D(0.01, 10)
    end

    addseries!(rx[2:end]./1000.0, ry[2:end], plotInt, gplotInt, 1, false, true)

    dp = OmronD6FPH.dp(handle, "0025AD1"; SDAP = 2, SCLP = 3)
	flow_rate = dp/2.5/100.0 * 16.6666666666

    (a,b) = poll_EL1050()
  
    set_gtk_property!(gui["temperature"], :text, @sprintf("%.1f", a)) 
    set_gtk_property!(gui["RH"], :text, @sprintf("%.1f", b)) 
    set_gtk_property!(gui["flow"], :text, @sprintf("%.2f", flow_rate)) 
    DataFrame(t = (frame.t)[1], T = a, RH = b, Q = flow_rate) |> CSV.write(outfile.value, append = true)
end
