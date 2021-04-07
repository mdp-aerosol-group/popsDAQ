
# Connect dropdown menus with callback functions...
gSelect1= gui["xpxp1G1"]
signal_connect(gSelect1, "changed") do widget, others...
	update_graphs()
end

# gSelect2= gui["xpxp1G2"]
# signal_connect(gSelect2, "changed") do widget, others...
# 	update_graphs()
# end

gSelect3= gui["xpxp2G1"]
signal_connect(gSelect3, "changed") do widget, others...
	update_graphs()
end

# gSelect4= gui["xpxp2G2"]
# signal_connect(gSelect4, "changed") do widget, others...
# 	update_graphs()
# end