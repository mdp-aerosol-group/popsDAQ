using LibSerialPort, Printf, Dates, Reactive, DataStructures

function configure_port(type, port)
    if type == :POPS
		baudRate = 9600
		dataBits = 8
		stopBits = 1
		parity = SP_PARITY_NONE
	end

	serialPort = port
	port = LibSerialPort.sp_get_port_by_name(serialPort)
	LibSerialPort.sp_open(port, SP_MODE_READ_WRITE)
	config = LibSerialPort.sp_get_config(port)
	LibSerialPort.sp_set_config_baudrate(config, baudRate)
	LibSerialPort.sp_set_config_parity(config, parity)
	LibSerialPort.sp_set_config_bits(config, dataBits)
	LibSerialPort.sp_set_config_stopbits(config, stopBits)
	LibSerialPort.sp_set_config_rts(config, SP_RTS_OFF)
	LibSerialPort.sp_set_config_cts(config, SP_CTS_IGNORE)
	LibSerialPort.sp_set_config_dtr(config, SP_DTR_OFF)
	LibSerialPort.sp_set_config_dsr(config, SP_DSR_IGNORE)

	LibSerialPort.sp_set_config(port, config)

	return port, type
end

function read_POPS(port,filePOPS)
	LibSerialPort.sp_drain(port)
	LibSerialPort.sp_flush(port, SP_BUF_OUTPUT)
	nbytes_read, bytes = LibSerialPort.sp_nonblocking_read(port, 1512)
	c = String(bytes)

	d = split(c,'\0')
	e = d[map(length, d) .> 0]
	if (length(e) == 0)
		return 0, 0, [0 for i = 1:16]
	end
	f = split(e[1], '\n')
	str = f[map(length, f) .> 0]

	open(filePOPS, "a") do io
		x = map(str) do s
			if length(s) <= 1
				condition = try
					s[1] == 'P'
				catch
					false
				end
			end
			if length(s) > 1
				condition = try
					s[1:2] == "PO"
				catch
					false
				end
			end

			if condition
				t = Dates.now()
				tint = @sprintf(",%i,", Dates.value(t))
				write(io, '\n'*Dates.format(t, Dates.ISODateTimeFormat)*tint*s)
				push!(POPSLine.value,s)
			else
				write(io, s)
				push!(POPSLine.value,s)
			end
		end
	end
	a = split(*(POPSLine.value...), '\r')
	i = map(a) do s
		x = split(s, ',')
		if length(x) == 27
			Np = try
				map(i->parse(Float64,x[i]),12:27)
			catch
				[0 for i = 1:16]
			end
			Q = try
				parse(Float64,x[8])
			catch
				1.0
			end
			Nt = try
				sum(Np[4:end]./Q)
			catch
				[0 for i = 1:16]
			end
			Nt, Q, Np./Q
		end
	end
	out = try
		i[i .!= nothing]
	catch
		nothing
	end
	if out === nothing
		return 0, 0, [0 for i = 1:16]
	else
		return out[end]
	end
end

function serial_read(portPOPS, filePOPS)
    t = now()
    N0 = [10,15.0,30,20,10,1.0, 0.1, 0.04, 0.005]
	Nt, Q, dN = read_POPS(portPOPS, filePOPS)
	push!(RS232dataStream, DataFrame(t=t,tint=Dates.value(t),POPS=Nt,Q=Q,POPSDistribution=[dN]))
end
