using Gtk
using InspectDR
using NumericIO
using Reactive
using Colors
using DataFrames    
using Printf
using Dates
using CSV
using DelimitedFiles
using FileIO    
using DataStructures
using Statistics
using MCA8000D


(@isdefined wnd) && destroy(wnd)
gui = GtkBuilder(filename=pwd()*"/mca.glade")  
wnd = gui["mainWindow"]
sNoise = gui["accumulationTime1"]
gainMode = gui["Gain"]
aTime = gui["accumulationTime"]

include("global_variables.jl")        # Reactive Signals and global variables
include("gtk_graphs.jl")              # push graphs to the UI#
include("setup_graphs.jl")            # Initialize graphs 
include("mca.jl")                     # MCA DAQ

Gtk.showall(wnd)                      

oneHz = every(1.0)            # 1  Hz time

function update_gui()
    t = now()

    n = get_gtk_property(aTime, "value", Int)
    subsetSpectra = hcat(spectra.value[end-n:end]...)   
    y = mean(subsetSpectra, dims=2)
    meanC = sum(y)

    thegain = get_gtk_property(gainMode, "active-id", String) 
    V = (thegain == "1") ? Vlow : Vhi

    qstr = get_gtk_property(gui["flow"], :text, String) 
    nx = parse(Float64, qstr)*lpm*1e6

    meanV = sum(V.*y)./sum(y)
    set_gtk_property!(gui["Timer"], :text, Dates.format(t,"HH:MM:SS"))
    set_gtk_property!(gui["meanC"], :text, @sprintf("%i", meanC))
    set_gtk_property!(gui["meanV"], :text, @sprintf("%i", meanV))
    set_gtk_property!(gui["concentration"], :text, @sprintf("%i", meanC/nx))

    rx = map(i->mean(V[i:i+4]),1:8:length(y)-8)
    ry = map(i->mean(y[i:i+4]),1:8:length(y)-8)

    plotInt.xext = InspectDR.PExtents1D() 
    if (thegain == "1") 
        plotInt.xext_full = InspectDR.PExtents1D(0, 1)
    else
        plotInt.xext_full = InspectDR.PExtents1D(0, 10)
    end

    addseries!(rx[2:end]./1000.0, ry[2:end], plotInt, gplotInt, 1, false, true)

    plotInt1.xext = InspectDR.PExtents1D() 
    if (thegain == "1") 
        plotInt1.xext_full = InspectDR.PExtents1D(0.01, 1)
    else
        plotInt1.xext_full = InspectDR.PExtents1D(0.01, 10)
    end

    addseries!(rx[2:end]./1000.0, ry[2:end], plotInt1, gplotInt1, 1, false, true)
end

acquire_mca()
update_gui()
sleep(3)
MAC = map(_->acquire_mca(), oneHz)
myGUI = map(_->update_gui(), oneHz)