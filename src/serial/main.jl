using Distributed

addprocs(1; exeflags="--project")

using Gtk
using InspectDR
using Reactive
using Colors
using DataFrames
using DataStructures
using Dates
using Distributions
using Interpolations
using Statistics
using Printf
using CSV
using LibSerialPort
using NumericIO

# DAQ Module
include("DataAcquisitionLoops.jl")
using .DataAcquisitionLoops

# Start DAQ Loops
Acquire = @spawnat 2 DataAcquisitionLoops.aquire(-1)

(@isdefined wnd) && destroy(wnd)                   # Destroy wind   ow if exists
gui = GtkBuilder(filename=pwd()*"/PopsUI.glade")  # Load the GUI template
wnd = gui["mainWindow"]                            # Set the main windowx

gSelect1= gui["xpxp1G1"]
signal_connect(gSelect1, "changed") do widget, others...
	update_graphs()
end

gSelect3= gui["xpxp2G1"]
signal_connect(gSelect3, "changed") do widget, others...
	update_graphs()
end

include("gtk_graphs.jl")              # Generic GTK graphing routines
include("constants.jl")               # Signals and global constants
include("setup_graphs.jl")            # Initialize graphs for GUI
include("gui_updates.jl")             # Update loops for GUI IO

Gtk.showall(wnd)                      # Show the window

oneHz = every(1.0)               # 1  Hz timer
graphLoop1  = map(_->(@async update_graphs()), oneHz)
oneHzFields = map(_->(@async update_oneHz()), oneHz)

Godot = @task _->false
id = signal_connect(x->schedule(Godot), gui["stopButton"], "clicked")
Godot = @task _->false

wait(Godot)