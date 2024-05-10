`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: wjh776a68
// 
// Create Date: 09/13/2023 11:31:26 AM
// Design Name: 
// Module Name: ram
// Project Name: 
// Target Devices: XCVU37P
// Tool Versions:  Vivado 2023.2
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ram # (
    parameter RAM_DEPTH = 1024,
    parameter ADDR_WIDTH = $clog2(RAM_DEPTH / 4)
    
) (
    input  wire clk,

    output wire [127:0]             ram_douta,
    output wire [127:0]             ram_doutb,
    input  wire [ADDR_WIDTH - 1:0]  ram_addra,
    input  wire [ADDR_WIDTH - 1:0]  ram_addrb,
    input  wire [127:0]             ram_dina,
    input  wire [127:0]             ram_dinb,
    input  wire [15:0]              ram_wea,
    input  wire [15:0]              ram_web,
    input  wire                     ram_ena,
    input  wire                     ram_enb
);
    

`ifdef COCOTB_SIMULATOR
    
    reg [127:0] ram_room[255:0];
    reg [9:0]   ram_addra_r;
    reg [9:0]   ram_addra_rr;
    reg [127:0] ram_douta_r, ram_douta_rr;

    reg [9:0]   ram_addrb_r;
    reg [9:0]   ram_addrb_rr;
    reg [127:0] ram_doutb_r, ram_doutb_rr;
    
    initial begin
        for (int j = 0; j < 256; j++) begin
            ram_room[j] = 128'b0;
        end
    end

    generate
        
        for (genvar strb = 0; strb < 16; strb++) begin
            always @(posedge clk) begin
                if (ram_wea[strb]) begin
                    ram_room[ram_addra][strb * 8 + 7 : strb * 8] <= ram_dina[strb * 8 + 7 : strb * 8];
                end

                if (ram_web[strb]) begin
                    ram_room[ram_addrb][strb * 8 + 7 : strb * 8] <= ram_dinb[strb * 8 + 7 : strb * 8];
                end
            end 
        end

        always @(posedge clk) begin
            ram_addra_r <= ram_addra;
            ram_addra_rr <= ram_addra_r;

            ram_addrb_r <= ram_addrb;
            ram_addrb_rr <= ram_addrb_r;
        end

        assign ram_douta = ram_room[ram_addra_rr];
        assign ram_doutb = ram_room[ram_addrb_rr];

    endgenerate
`else 

    xpm_memory_tdpram #(
        
        .ADDR_WIDTH_A(ADDR_WIDTH),               
        .ADDR_WIDTH_B(ADDR_WIDTH),               
        .AUTO_SLEEP_TIME(0),            
        .BYTE_WRITE_WIDTH_A(8),        
        .BYTE_WRITE_WIDTH_B(8),        
        .CASCADE_HEIGHT(0),             
        .CLOCKING_MODE("common_clock"), 
        .ECC_MODE("no_ecc"),            
        .MEMORY_INIT_FILE("none"),      
        .MEMORY_INIT_PARAM("0"),        
        .MEMORY_OPTIMIZATION("true"),   
        .MEMORY_PRIMITIVE("auto"),      
        .MEMORY_SIZE(RAM_DEPTH * 32),             
        .MESSAGE_CONTROL(0),            
        .READ_DATA_WIDTH_A(128),         
        .READ_DATA_WIDTH_B(128),         
        .READ_LATENCY_A(2),             
        .READ_LATENCY_B(2),             
        .READ_RESET_VALUE_A("0"),       
        .READ_RESET_VALUE_B("0"),       
        .RST_MODE_A("SYNC"),            
        .RST_MODE_B("SYNC"),            
        .SIM_ASSERT_CHK(0),             
        .USE_EMBEDDED_CONSTRAINT(0),    
        .USE_MEM_INIT(1),               
        .USE_MEM_INIT_MMI(0),           
        .WAKEUP_TIME("disable_sleep"),  
        .WRITE_DATA_WIDTH_A(128),        
        .WRITE_DATA_WIDTH_B(128),        
        .WRITE_MODE_A("no_change"),     
        .WRITE_MODE_B("no_change"),     
        .WRITE_PROTECT(1)               
    )
    xpm_memory_tdpram_bar2_inst (
        .dbiterra(),             
        .dbiterrb(),             
        .douta(ram_douta),                   
        .doutb(ram_doutb),                   
        .sbiterra(),             
        .sbiterrb(),             
        .addra(ram_addra),                   
        .addrb(ram_addrb),                   
        .clka(clk),                     
        .clkb(clk),                     
        .dina(ram_dina),                     
        .dinb(ram_dinb),                     
        .ena(ram_ena),                       
        .enb(ram_enb),                       
        .injectdbiterra(), 
        .injectdbiterrb(), 
        .injectsbiterra(), 
        .injectsbiterrb(), 
        .regcea(1'b1),                 
        .regceb(1'b1),                 
        .rsta(rst),                     
        .rstb(rst),                     
        .sleep(1'b0),                   
        .wea(ram_wea),                       
        .web(ram_web)                        

    );
        

`endif

endmodule
