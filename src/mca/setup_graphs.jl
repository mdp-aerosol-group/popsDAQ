using NumericIO
using InspectDR
using Colors

function time_series(yaxis)
	plot = InspectDR.transientplot(yaxis, title="")
	InspectDR.overwritefont!(plot.layout, fontscale=1.0)
	plot.layout[:enable_legend] = false
	plot.layout[:halloc_legend] = 130
	plot.layout[:halloc_left] = 50
	plot.layout[:enable_timestamp] = false
	plot.layout[:length_tickmajor] = 10
	plot.layout[:length_tickminor] = 6
	plot.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
	plot.layout[:frame_data] =  InspectDR.AreaAttributes(
         line=InspectDR.line(style=:solid, color=RGBA(0,0,0,1), width=0.5))
	plot.layout[:line_gridmajor] = InspectDR.LineStyle(:solid, Float64(0.75), 
													   RGBA(0, 0, 0, 1))

	plot.xext = InspectDR.PExtents1D()
	plot.xext_full = InspectDR.PExtents1D(0, 30)

	a = plot.annotation
	a.xlabel = "Time (min)"
	a.ylabels = ["Aerosol concentration"]

	return plot
end

function size_distribution()
	plotPOPSSize = InspectDR.Plot2D(:log,:log, title="")
	InspectDR.overwritefont!(plotPOPSSize.layout, fontscale=1.0)
	plotPOPSSize.layout[:enable_legend] = false
	plotPOPSSize.layout[:enable_timestamp] = false
	plotPOPSSize.layout[:length_tickmajor] = 10
	plotPOPSSize.layout[:length_tickminor] = 6
	plotPOPSSize.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
	plotPOPSSize.layout[:frame_data] =  InspectDR.AreaAttributes(
       	line=InspectDR.line(style=:solid, color=black, width=0.5))
	plotPOPSSize.layout[:line_gridmajor] = InspectDR.LineStyle(:solid, 
											Float64(0.75), RGBA(0, 0, 0, 1))

	plotPOPSSize.xext = InspectDR.PExtents1D()
	plotPOPSSize.xext_full = InspectDR.PExtents1D(100, 3000)

	graph = plotPOPSSize.strips[1]
	graph.yext = InspectDR.PExtents1D() 
	graph.yext_full = InspectDR.PExtents1D(0.001, 1000)

	graph = plotPOPSSize.strips[1]
	graph.grid = InspectDR.GridRect(vmajor=true, vminor=true, 
									hmajor=true, hminor=true)

	a = plotPOPSSize.annotation
	a.xlabel = "Diameter (nm)"
	a.ylabels = ["Concentration (cm-3)"]
	
	return plotPOPSSize
end

plotXPXP1 = time_series(:lin)
mpPlotXPXP1,gplotPlotXPXP1 = push_plot_to_gui!(plotXPXP1, gui["xpxp1"], wnd)
wfrm = add(plotXPXP1, [0.0], [22.0], id="A")
wfrm.line = line(color=black, width=1, style=:solid)
wfrm = add(plotXPXP1, [0.0], [22.0], id="B")
wfrm.line = line(color=red, width=1, style=:solid)

plotXPXP2 = size_distribution()
mpPlotXPXP2,gplotPlotXPXP2 = push_plot_to_gui!(plotXPXP2, gui["xpxp2"], wnd)
wfrm = add(plotXPXP2, DpPOPS, rand(length(DpPOPS)), id="A")
wfrm.line = line(color=black, width=1, style=:solid)
wfrm.glyph = glyph(shape=:circle, size=10, color=black, fillcolor=black)
wfrm = add(plotXPXP2, DpPOPS, rand(length(DpPOPS)), id="A")
wfrm.line = line(color=mblue, width=1, style=:solid)
wfrm.glyph = glyph(shape=:circle, size=10, color=black, fillcolor=mblue)

function graph(xaxis)
	plot = InspectDR.Plot2D(xaxis,:log, title="")
	InspectDR.overwritefont!(plot.layout, fontname="Arial", fontscale=1.0)
	plot.layout[:enable_legend] = true
	plot.layout[:halloc_left] = 50
	plot.layout[:halloc_legend] = 10
	plot.layout[:enable_timestamp] = false
	plot.layout[:length_tickmajor] = 10
	plot.layout[:length_tickminor] = 6
	plot.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
	plot.layout[:frame_data] =  InspectDR.AreaAttributes(
         line=InspectDR.line(style=:solid, color=black, width=0.5))
	plot.layout[:line_gridmajor] = InspectDR.LineStyle(:solid, Float64(0.75), 
													   RGBA(0, 0, 0, 1))

	plot.xext = InspectDR.PExtents1D()
	plot.xext_full = InspectDR.PExtents1D(0, 205)

	a = plot.annotation
	a.xlabel = "Voltage (V)"
	a.ylabels = ["Count"]

	style = :solid 
	wfrm = add(plot, [0.001], [0.0001], id="")
	wfrm.line = line(color=black, width=2, style=style)

	return plot
end

plotInt = graph(:log)
mpInt,gplotInt = push_plot_to_gui!(plotInt, gui["xpxp3"], wnd)
