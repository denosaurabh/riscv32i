import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

import cv2 
import numpy

# Define grid and cell size
grid_size = (50, 50)  # 10x10 grid
cell_size = 40  # Each cell is 50x50 pixels

# Calculate image size based on grid and cell size
image_height = grid_size[0] * cell_size
image_width = grid_size[1] * cell_size



@cocotb.test()
async def test_cpu(cpu):
    cpu.reset.value = 1
    await Timer(10, units='ns')
    cpu.reset.value = 0
    
    cocotb.start_soon(Clock(cpu.clk, 10, units='ns').start())
    
    # for i in range(50):
    #     await RisingEdge(cpu.clk)
    
    while(True): 
        await RisingEdge(cpu.clk)

        do_continue = await listen_to_display_ram(cpu)

        if do_continue == 0:
            break


    await Timer(10, units='ns')


    # Destroy all the windows 
    cv2.destroyAllWindows() 
  


# Function to place a letter in a specific grid cell
def place_letter(image, letter, x, y, cell_size, font_scale=1, thickness=2):
    font = cv2.FONT_HERSHEY_SIMPLEX
    color = (255, 255, 255)  # White color in BGR
    # Calculate the bottom-left corner of the text in the cell
    text_size = cv2.getTextSize(letter, font, font_scale, thickness)[0]
    text_x = x * cell_size + (cell_size - text_size[0]) // 2
    text_y = y * cell_size + (cell_size + text_size[1]) // 2
    cv2.putText(image, letter, (text_x, text_y), font, font_scale, color, thickness)



async def listen_to_display_ram(cpu):
        # Capture the video frame 
        frame = numpy.ones((image_width, image_height, 3), dtype = numpy.uint8)
        
        # draw_grid(frame, grid_size, cell_size)

        # loop over grid
        # for 

        # Place a specific letter at a specific grid cell
        place_letter(frame, '0', 0, 0, cell_size)  # Place 'A' at (2, 3)
        place_letter(frame, '1', 1, 0, cell_size)  # Place 'A' at (2, 3)
        place_letter(frame, '2', 0, 1, cell_size)  # Place 'A' at (2, 3)
        place_letter(frame, '3', 1, 1, cell_size)  # Place 'A' at (2, 3)
        place_letter(frame, 'A', 2, 3, cell_size)  # Place 'A' at (2, 3)
        place_letter(frame, 'B', 5, 5, cell_size)  # Place 'B' at (5, 5)

        # Display the resulting frame 
        cv2.imshow('RISCV 31I', frame) 
        
        # the 'q' button is set as the 
        # quitting button you may use any 
        # desired button of your choice 
        key = cv2.waitKey(1)

        await write_keyboard_events_on_ram(cpu, key)

        if key == ord('q'): 
            return 0 # break the loop
        else:
            return 1


async def write_keyboard_events_on_ram(cpu, key):
    if key == -1:
        return

    char = chr(key)
    bits = format(key, '08b')

    print(key, char, bits)

    pressed = 1
    # await cpu.write_keyboard_presses(key, pressed)






# Function to draw the grid
# def draw_grid(image, grid_size, cell_size):
#     for i in range(grid_size[0] + 1):
#         cv2.line(image, (0, i * cell_size), (image_width, i * cell_size), (255, 255, 255), 1)
#     for j in range(grid_size[1] + 1):
#         cv2.line(image, (j * cell_size, 0), (j * cell_size, image_height), (255, 255, 255), 1)
