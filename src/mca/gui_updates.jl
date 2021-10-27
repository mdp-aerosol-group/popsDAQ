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
    #addseries!(DpPOPS[ii],POPSDistribution[ii], plotXPXP2, gplotPlotXPXP2, 2, false, false)
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

    psd, mDp = mca_mv_to_nm_conversion(V, nx, y)
    jj = psd .> 0
    addseries!(mDp[jj],psd[jj], plotXPXP2, gplotPlotXPXP2, 2, false, false)

    meanV = sum(V.*y)./sum(y)
    set_gtk_property!(gui["meanV"], :text, @sprintf("%.1f", meanV))
	set_gtk_property!(gui["meanC"], :text, @sprintf("%.1f", meanC*10/nx))

    rx = map(i->mean(V[i:i+4]),1:8:length(y)-8)
    ry = map(i->mean(10.0.*y[i:i+4]),1:8:length(y)-8)
    ry[ry .< 0.01] .= 0.01
    plotInt.xext = InspectDR.PExtents1D() 
    if (thegain == "1") 
        plotInt.xext_full = InspectDR.PExtents1D(0.001, 1)
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

######## modification on 25 May, 2020 (Maksim)

function mca_mv_to_nm_conversion(V::Array{Float64}, Q::Float64, y::Array{Float64})

    # 8192 channels to 17 bins
    bin_index_190_250 = findall(V.< 7.30737182175807);
    bin_index_250_300 = findall((V.> 7.30737182175807) .& (V.< 9.95763690768158));
    bin_index_300_350 = findall((V.> 9.95763690768158) .& (V.< 13.0559326054451));
    bin_index_350_400 = findall((V.> 13.0559326054451) .& (V.< 16.1660984525868));
    bin_index_400_450 = findall((V.> 16.1660984525868) .& (V.< 18.1198673084871));
    bin_index_450_500 = findall((V.> 18.1198673084871) .& (V.< 23.3215526195748));
    bin_index_500_550 = findall((V.> 23.3215526195748) .& (V.< 28.5819104872049));
    bin_index_550_600 = findall((V.> 28.5819104872049) .& (V.< 36.0161658105645));
    bin_index_600_700 = findall((V.> 36.0161658105645) .& (V.< 54.1875157387813));
    bin_index_700_800 = findall((V.> 54.1875157387813) .& (V.< 69.6601828096707));
    bin_index_800_900 = findall((V.> 69.6601828096707) .& (V.< 84.929767386026));
    bin_index_900_1000 = findall((V.> 84.929767386026) .& (V.< 99.954335618029));
    bin_index_1000_1100 = findall((V.> 99.954335618029) .& (V.< 116.540783616229));
    bin_index_1100_1200 = findall((V.> 116.540783616229) .& (V.< 131.348520985419));
    bin_index_1200_1300 = findall((V.> 131.348520985419) .& (V.< 148.839150764144));
    bin_index_1300_1400 = findall((V.> 148.839150764144) .& (V.< 161.778298535257));
    bin_index_1400_1500 = findall((V.> 161.778298535257) .& (V.< 183.279613979509));

    # Total Concentration on each of the 17 bins 
    C_Dia_190_250 = sum(y[bin_index_190_250]) / Q /0.1
    C_Dia_250_300 = sum(y[bin_index_250_300]) / Q /0.1
    C_Dia_300_350 = sum(y[bin_index_300_350]) / Q /0.1
    C_Dia_350_400 = sum(y[bin_index_350_400]) / Q /0.1
    C_Dia_400_450 = sum(y[bin_index_400_450]) / Q /0.1
    C_Dia_450_500 = sum(y[bin_index_450_500]) / Q /0.1
    C_Dia_500_550 = sum(y[bin_index_500_550]) / Q /0.1
    C_Dia_550_600 = sum(y[bin_index_550_600]) / Q /0.1
    C_Dia_600_700 = sum(y[bin_index_600_700]) / Q /0.1
    C_Dia_700_800 = sum(y[bin_index_700_800]) / Q /0.1
    C_Dia_800_900 = sum(y[bin_index_800_900])/ Q /0.1
    C_Dia_900_1000 = sum(y[bin_index_900_1000])/ Q /0.1
    C_Dia_1000_1100 = sum(y[bin_index_1000_1100]) / Q /0.1
    C_Dia_1100_1200 = sum(y[bin_index_1100_1200]) / Q /0.1
    C_Dia_1200_1300 = sum(y[bin_index_1200_1300]) / Q /0.1
    C_Dia_1300_1400 = sum(y[bin_index_1300_1400])/ Q /0.1
    C_Dia_1400_1500 = sum(y[bin_index_1400_1500])/ Q /0.1

    # creating array for plotting
    C_mca_hist_bins = [C_Dia_190_250,C_Dia_250_300,C_Dia_300_350,C_Dia_350_400,C_Dia_400_450,C_Dia_450_500,C_Dia_500_550,C_Dia_550_600,C_Dia_600_700,C_Dia_700_800,C_Dia_800_900,C_Dia_900_1000,C_Dia_1000_1100,C_Dia_1100_1200,C_Dia_1200_1300,C_Dia_1300_1400,C_Dia_1400_1500]
    Dia_mca_hist_bins = [190, 250, 300, 350, 400, 450, 500, 550, 600, 700, 800, 900,1000,1100,1200,1300,1400.0]

    C_mca_hist_bins,Dia_mca_hist_bins  # function returns
end