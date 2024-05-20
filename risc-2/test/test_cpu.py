import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

@cocotb.test()
async def test_cpu(cpu):
    cpu.reset.value = 1
    await Timer(10, units='ns')
    cpu.reset.value = 0
    
    cocotb.start_soon(Clock(cpu.clk, 10, units='ns').start())
    
    for i in range(10):
        await RisingEdge(cpu.clk)

        # assert cpu.out_istr.value == i, f"Counter value mismatch: expected {i}, got {cpu.out_istr.value}"
    
    await Timer(10, units='ns')