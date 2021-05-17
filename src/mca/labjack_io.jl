using PyCall
using OmronD6FPH

const EI1050_FIO_PIN_STATE = 0 
const SDAP = 2
const SCLP = 3
const DATA_PIN_NUM = 4
const CLOCK_PIN_NUM = 5
const POWER_PIN_NUM = 6

# Load and initialize labjack
u3 = pyimport("u3")                           
(@isdefined handle) || (handle = u3.U3())    
handle.configIO(EnableCounter0 = false, EnableCounter1 = false, NumberOfTimersEnabled = 0, FIOAnalog=EI1050_FIO_PIN_STATE)

# Initialize Omron probe
isInitialized = OmronD6FPH.initialize(handle; SDAP = SDAP,SCLP = SCLP)

# Setup EL-1050 probe
handle.getFeedback(u3.BitDirWrite(POWER_PIN_NUM, 1))
handle.getFeedback(u3.BitStateWrite(POWER_PIN_NUM, 1))

function poll_EL1050()
    ret = handle.sht1x(DATA_PIN_NUM, CLOCK_PIN_NUM, 0xc0)
    return (ret["Temperature"], ret["Humidity"])
end