function graph(xaxis)
	plot = InspectDR.Plot2D(xaxis,:lin, title="")
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
	wfrm = add(plot, [0.0], [0.0], id="")
	wfrm.line = line(color=black, width=2, style=style)
	

	return plot
end

plotInt = graph(:lin)
mpInt,gplotInt = push_plot_to_gui!(plotInt, gui["StreamGraph"], wnd)

plotInt1 = graph(:log)
mpInt1,gplotInt1 = push_plot_to_gui!(plotInt1, gui["StreamGraph1"], wnd)
