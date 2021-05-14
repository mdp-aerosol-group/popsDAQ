const _Gtk = Gtk.ShortNames
const black = RGBA(0, 0, 0, 1)
const red = RGBA(0.55, 0.0, 0, 1)
const mblue = RGBA(0.31, 0.58, 0.8, 1)
const mgrey = RGBA(0.4, 0.4, 0.4, 1)
const lpm = 1.666666e-5


a= pwd() |> x->split(x,"/")
datestr = Dates.format(now(), "yyyymmdd")
const path = mapreduce(a->"/"*a,*,a[2:3])*"/Data/MCA/"*datestr*"/"
read(`mkdir -p $path`)
const outfile = Signal(path*"MCA"*datestr*".mca")

const ch = collect(range(1,stop=8191, length=8191))
const Vlow = @. -0.594422 + 0.121933.*ch
const Vhi = @. -6.09756 + 1.21951.*ch

# parse_box functions read a text box and returns the formatted result
function parse_box(s::String, default::Float64)
	x = get_gtk_property(gui[s], :text, String)
	y = try parse(Float64,x) catch; y = default end
end

# parse_box functions read a text box and returns the formatted result
function parse_box(s::String, default::Missing)
	x = get_gtk_property(gui[s], :text, String)
	y = try parse(Float64,x) catch; y = missing end
end

function parse_box(s::String)
	x = get_gtk_property(gui[s], :active_id, String)
	y = Symbol(x)
end

function parse_missing(N)
    str = try
        @sprintf("%.1f",N)
    catch
        "missing"
    end

    return str
end

function parse_missing1(N)
    str = try
        @sprintf("%.4f",N)
    catch
        "missing"
    end

    return str
end
