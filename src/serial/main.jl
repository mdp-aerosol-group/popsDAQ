using Distributed
addprocs(1)

using Gtk, InspectDR, Reactive, Colors, DataFrames, DataStructures, Dates, Distributions
using Interpolations, Statistics, Printf, CSV, LibSerialPort, NumericIO

# Custom Packages
include("DataAcquisitionLoops.jl")
using .DataAcquisitionLoops,  LabjackU6Library
#  https://github.com/mdpetters/LabjackU6Library.jl.git

# Start DAQ Loops
Godot = @spawnat 2 DataAcquisitionLoops.aquire(-1)

(@isdefined wnd) && destroy(wnd)                   # Destroy wind   ow if exists
gui = GtkBuilder(filename=pwd()*"/PopsUI.glade")  # Load the GUI template
wnd = gui["mainWindow"]                            # Set the main windowx

include("gtk_graphs.jl")              # Generic GTK graphing routines
include("global_variables.jl")        # Signals and global constants
include("gtk_callbacks.jl")           # Link GTK GUI fields with code
include("gui_updates.jl")             # Update loops for GUI IO
#include("labjack_io.jl")              # Labjack Data Aquisition
include("setup_graphs.jl")            # Initialize graphs for GUI

Gtk.showall(wnd)                      # Show the window


oneHz = every(1.0)               # 1  Hz timer

#griddedData = map(_->(@async update_gridded_data()), griddedHz)
graphLoop1  = map(_->(@async update_graphs()), oneHz)
#graphLoop2  = map(_->(@async update_turbulence()), graphHz)
oneHzFields = map(_->(@async update_oneHz()), oneHz)
