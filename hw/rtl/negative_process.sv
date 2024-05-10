`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: wjh776a68
// 
// Create Date: 09/12/2023 08:13:34 PM
// Design Name: 
// Module Name: negative_process
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


module negative_process #(
    parameter DATA_WIDTH = 512,
    parameter KEEP_WIDTH = DATA_WIDTH / 32,
    
    parameter CQ_USER_WIDTH = 137,
    parameter CC_USER_WIDTH = 161

) (
    input clk,
    input rst,

    (* MARK_DEBUG="true" *) input   [DATA_WIDTH - 1 : 0]  m_axis_cq_tdata,
    (* MARK_DEBUG="true" *) input   [KEEP_WIDTH - 1 : 0]    m_axis_cq_tkeep,
    (* MARK_DEBUG="true" *) input              m_axis_cq_tlast,
    (* MARK_DEBUG="true" *) output reg            m_axis_cq_tready,
    (* MARK_DEBUG="true" *) input   [CQ_USER_WIDTH - 1 : 0]   m_axis_cq_tuser,
    (* MARK_DEBUG="true" *) input              m_axis_cq_tvalid,
    
    (* MARK_DEBUG="true" *) output reg [DATA_WIDTH - 1 : 0]  s_axis_cc_tdata,
    (* MARK_DEBUG="true" *) output reg [KEEP_WIDTH - 1 : 0]    s_axis_cc_tkeep,
    (* MARK_DEBUG="true" *) output reg            s_axis_cc_tlast,
    (* MARK_DEBUG="true" *) input   [3 : 0]    s_axis_cc_tready,
    (* MARK_DEBUG="true" *) output reg [CC_USER_WIDTH - 1 : 0]   s_axis_cc_tuser,
    (* MARK_DEBUG="true" *) output reg            s_axis_cc_tvalid,

    output wire [127:0] ram_ctl_dout[3:0],
    input  wire [63:0]  ram_ctl_addr[3:0],
    input  wire [127:0] ram_ctl_din[3:0],
    input  wire [15:0]  ram_ctl_we[3:0],

    output wire [127:0] ram_mem_dout[3:0],
    input  wire [63:0]  ram_mem_addr[3:0],
    input  wire [127:0] ram_mem_din[3:0],
    input  wire [15:0]  ram_mem_we[3:0],

    output reg  [1:0] dma_watchdog[3:0],
    input  wire [1:0] dma_watchdog_ack[3:0],

    output reg indicator

);
    initial begin
        m_axis_cq_tready = 1;
        s_axis_cc_tdata = 0;
        s_axis_cc_tkeep = 0;
        s_axis_cc_tlast = 0;
        s_axis_cc_tuser = 0;
        s_axis_cc_tvalid = 0;
    end

    initial begin
        indicator = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            indicator <= 0;
        end
        else begin
            if (m_axis_cq_tvalid & m_axis_cq_tready) begin
                indicator <= 1;
            end
            else begin
                indicator <= indicator;
            end
        end

    end
    
    reg [3:0] usr_first_be_s;
    reg [3:0] usr_last_be_s;
    reg [3:0]  usr_first_be_r = 4'b0;//    = m_axis_cq_tuser[3:0];
    reg [3:0]  usr_last_be_r = 4'b0;//     = m_axis_cq_tuser[7:4];
    wire [31:0] usr_byte_en_s     = m_axis_cq_tuser[39:8];
    // reg [31:0] usr_byte_en_r;
    wire        usr_sop_s         = m_axis_cq_tuser[40];
    wire        usr_discontinue_s = m_axis_cq_tuser[41];
    wire        usr_tph_present_s = m_axis_cq_tuser[42];
    wire [1:0]  usr_tph_type_s    = m_axis_cq_tuser[44:43];
    wire [7:0]  usr_tph_st_tag_s  = m_axis_cq_tuser[52:45];
    wire [31:0] usr_parity_s      = m_axis_cq_tuser[84:53];

    reg [7:0] usr_tph_st_tag_r;
    reg [1:0] usr_tph_type_r;
    reg usr_tph_present_r;



    always @(*) begin
        usr_first_be_s = m_axis_cq_tuser[3:0];
        usr_last_be_s = m_axis_cq_tuser[7:4];
    
    end


    always @(posedge clk) begin
        if (rst) begin
            usr_first_be_r <= 0;
            usr_last_be_r <= 0;
            usr_tph_st_tag_r <= 0;
            usr_tph_type_r <= 0;
            usr_tph_present_r <= 0;
        end
        else begin
            if (usr_sop_s & m_axis_cq_tvalid) begin
                usr_first_be_r <= m_axis_cq_tuser[3:0];
                usr_last_be_r <= m_axis_cq_tuser[7:4];
                usr_tph_st_tag_r <= m_axis_cq_tuser[52:45];
                usr_tph_type_r <= m_axis_cq_tuser[44:43];
                usr_tph_present_r <= m_axis_cq_tuser[42];
            end
        end
    end

    (* MARK_DEBUG="true" *) reg [5:0] cs = 0, ns;

    (* MARK_DEBUG="true" *) reg cpl_start = 0, cpl_ready = 0;
    reg usr_first_be_used_rr;
    
    always @(posedge clk) begin
        if (rst) begin
            cs <= 0;
        end
        else begin
            cs <= ns;
        end
    end

    always @(*) begin
        case (cs)
        0: begin
            if (m_axis_cq_tvalid & m_axis_cq_tready) begin
                if (m_axis_cq_tlast) begin
                    ns = 4;
                end
                else begin
                    ns = 1;
                end
            end
            else begin
                ns = 0;
            end
        end
        1: begin // must have header
            if (m_axis_cq_tvalid & m_axis_cq_tready) begin
                if (m_axis_cq_tlast) begin
                    ns = 3;
                end
                else begin
                    ns = 2;
                end
            end        
            else begin
                ns = 1;
            end    
        end
        2: begin
            if (m_axis_cq_tvalid & m_axis_cq_tlast & m_axis_cq_tready) begin
                ns = 3;
            end        
            else begin
                ns = 2;
            end   
        end
        3: begin // last_packet's frame
            if (m_axis_cq_tvalid & m_axis_cq_tready) begin
                if (m_axis_cq_tlast) begin
                    ns = 4;
                end
                else begin
                    ns = 1;
                end
            end
            else begin
                ns = 0;
            end
            // ns = 0;
        end
        4: begin // require cpl finish
            ns = 5;
        end
        5: begin
            if (usr_first_be_used_rr & cpl_ready) begin
                ns = 0;
            end
            else begin
                ns = 5;
            end
        end
        default: begin
            ns = 0;
        end
        endcase
    end


    reg [9:0]   desc_mm_dword_count_s;
    reg [3:0]   desc_mm_req_type_s;
    reg [7:0]   desc_mm_device_function_s;
    reg [7:0]   desc_mm_bus_s;
    reg [7:0]   desc_mm_tag_s;
    reg [7:0]   desc_mm_target_function_s;
    reg [2:0]   desc_mm_bar_id_s;
    reg [5:0]   desc_mm_bar_aperture_s;
    reg [2:0]   desc_mm_tc_s;
    reg [2:0]   desc_mm_attr_s;
    reg [1:0]   desc_mm_at_s;
    reg [63:0]  desc_mm_address_s;

    reg [9:0]   desc_mm_dword_count_r;
    reg [3:0]   desc_mm_req_type_r;
    reg [7:0]   desc_mm_device_function_r;
    reg [7:0]   desc_mm_bus_r;
    reg [7:0]   desc_mm_tag_r;
    reg [7:0]   desc_mm_target_function_r;
    reg [2:0]   desc_mm_bar_id_r;
    reg [5:0]   desc_mm_bar_aperture_r;
    reg [2:0]   desc_mm_tc_r;
    reg [2:0]   desc_mm_attr_r;
    reg [1:0]   desc_mm_at_r;
    reg [63:0]  desc_mm_address_r;

    always @(*) begin
        desc_mm_dword_count_s = m_axis_cq_tdata[64 + 8 + 3 - 1 : 64];
        desc_mm_req_type_s = m_axis_cq_tdata[64 + 8 + 3 - 1 + 4 - 1 : 64 + 8 + 3];
        desc_mm_device_function_s = m_axis_cq_tdata[64 + 16 + 7 : 64 + 16];
        desc_mm_bus_s = m_axis_cq_tdata[64 + 24 + 7 : 64 + 24];
        desc_mm_tag_s = m_axis_cq_tdata[64 + 32 + 7 : 64 + 32];
        desc_mm_target_function_s = m_axis_cq_tdata[64 + 40 + 7 : 64 + 40];
        desc_mm_bar_id_s = m_axis_cq_tdata[64 + 48 + 2 : 64 + 48];
        desc_mm_bar_aperture_s = m_axis_cq_tdata[64 + 48 + 8 : 64 + 48 + 3];
        desc_mm_tc_s = m_axis_cq_tdata[64 + 48 + 9 + 2 : 64 + 48 + 9];
        desc_mm_attr_s = m_axis_cq_tdata[64 + 48 + 9 + 5 : 64 + 48 + 9 + 3];
        desc_mm_at_s = m_axis_cq_tdata[1 : 0];
        desc_mm_address_s = {m_axis_cq_tdata[63 : 2], 2'b0};
    end



    reg c_hasprefix_s;
    reg c_mrd_32bit_s;
    reg c_mrd_64bit_s;
    reg c_mwr_32bit_s;
    reg c_mwr_64bit_s;
    reg c_unsupport_s;

    reg c_hasprefix_r = 0;
    reg c_mrd_32bit_r = 0;
    reg c_mrd_64bit_r = 0;
    reg c_mwr_32bit_r = 0;
    reg c_mwr_64bit_r = 0;
    reg c_unsupport_r = 0;

    always @(*) begin
        case (desc_mm_req_type_s)
        'b0000: begin // mrd
            c_mrd_64bit_s = 1;
            c_mwr_64bit_s = 0;
            c_unsupport_s = 0;
        end
        'b0001: begin // mwr
            c_mrd_64bit_s = 0;
            c_mwr_64bit_s = 1;
            c_unsupport_s = 0;
        end
        /* 'b1000: begin // ep cfgrd

        end
        'b1010: begin // ep cfgwr

        end */
        default: begin // uc
            c_mrd_64bit_s = 0;
            c_mwr_64bit_s = 0;
            c_unsupport_s = 1;
        end
        endcase
            
    end

    reg [127:0] request_tlp_desc_r;

    wire [127:0] ram_bar0_douta[3:0];
    wire [127:0] ram_bar0_doutb[3:0];
    (* MARK_DEBUG = "true" *) reg  [63:0]  ram_bar0_addra[3:0];
    wire  [63:0]  ram_bar0_addrb[3:0];
    (* MARK_DEBUG = "true" *) reg  [127:0] ram_bar0_dina[3:0];
    wire  [127:0] ram_bar0_dinb[3:0];
    (* MARK_DEBUG = "true" *) reg  [15:0] ram_bar0_wea[3:0];
    wire  [15:0] ram_bar0_web[3:0];

    wire [127:0] ram_bar2_douta[3:0];
    wire [127:0] ram_bar2_doutb[3:0];
    reg  [63:0]  ram_bar2_addra[3:0];
    wire  [63:0]  ram_bar2_addrb[3:0];
    reg  [127:0] ram_bar2_dina[3:0];
    wire  [127:0] ram_bar2_dinb[3:0];
    reg  [15:0] ram_bar2_wea[3:0];
    wire  [15:0] ram_bar2_web[3:0];
    
    generate
        for (genvar i = 0; i < 4; i++) begin
            assign ram_ctl_dout[i] = ram_bar0_doutb[i];
            assign ram_bar0_dinb[i] = ram_ctl_din[i];
            assign ram_bar0_addrb[i] = ram_ctl_addr[i];
            assign ram_bar0_web[i] = ram_ctl_we[i];
        end

        for (genvar i = 0; i < 4; i++) begin
            assign ram_mem_dout[i] = ram_bar2_doutb[i];
            assign ram_bar2_dinb[i] = ram_mem_din[i];
            assign ram_bar2_addrb[i] = ram_mem_addr[i];
            assign ram_bar2_web[i] = ram_mem_we[i];
        end
    endgenerate

    wire [127:0] ram_bar0_dina_1 = ram_bar0_dina[0];
    wire [63:0] ram_bar0_addra_1 = ram_bar0_addra[0];
    wire [15:0] ram_bar0_wea_1 = ram_bar0_wea[0];

    wire [127:0] ram_bar2_dina_1 = ram_bar2_dina[0];
    wire [63:0] ram_bar2_addra_1 = ram_bar2_addra[0];
    wire [15:0] ram_bar2_wea_1 = ram_bar2_wea[0];

    initial begin
        for (integer i = 0; i < 4; i++) begin
            ram_bar0_addra[i] = 0;
            // ram_bar0_addrb[i] = 0;
            ram_bar0_dina[i] = 0;
            // ram_bar0_dinb[i] = 0;
            ram_bar0_wea[i] = 0;
            // ram_bar0_web[i] = 0;

            ram_bar2_addra[i] = 0;
            // ram_bar2_addrb[i] = 0;
            ram_bar2_dina[i] = 0;
            // ram_bar2_dinb[i] = 0;
            ram_bar2_wea[i] = 0;
            // ram_bar2_web[i] = 0;
        end
    end

    (* MARK_DEBUG="true" *) reg usr_first_be_used_r = 0;


    reg [1:0] usr_first_be_s_decode;
    always @(*) begin
        casex (usr_first_be_s)
        4'bxxx1: begin
            usr_first_be_s_decode = 2'b00;
        end
        4'bxx10: begin
            usr_first_be_s_decode = 2'b01;
        end
        4'bx100: begin
            usr_first_be_s_decode = 2'b10;
        end
        4'b1000: begin
            usr_first_be_s_decode = 2'b11;
        end
        endcase
    end

    always @(posedge clk) begin
        case (ns) // ram write related
        0: begin
            for (integer i = 0; i < 4; i++) begin
                ram_bar0_wea[i] <= 0;
                ram_bar2_wea[i] <= 0;
            end
        end
        1, 4: begin
            if (m_axis_cq_tvalid & m_axis_cq_tready) begin
                if (usr_sop_s) begin
                    for (integer i = 0; i < 4; i++) begin
                        case (desc_mm_req_type_s) // only write request show be appeared here
                        'b0000: begin // mrd
                            ram_bar0_addra[i] <= {desc_mm_address_s};   // , 2'b00};    // usr_first_be_s_decode};
                            ram_bar2_addra[i] <= {desc_mm_address_s};   // , 2'b00};    // usr_first_be_s_decode};
                        end
                        'b0001: begin // mwr
                            ram_bar0_addra[i] <= {desc_mm_address_s};   // , 2'b00};
                            ram_bar2_addra[i] <= {desc_mm_address_s};   // , 2'b00};
                        end
                        endcase
                    end
                    
                end
                else begin
                    
                end
            end
            for (integer i = 0; i < 4; i++) begin
                ram_bar0_wea[i] <= 0;
                ram_bar2_wea[i] <= 0;
            end
        end
        2, 3: begin
            if (m_axis_cq_tvalid & m_axis_cq_tready) begin
                // usr_first_be_used_r <= 1;
                if (c_mwr_64bit_r) begin
                    case (desc_mm_bar_id_r)
                    3'b000: begin   // bar 0
                        case ({m_axis_cq_tlast, usr_first_be_used_r})
                        2'b01: begin
                            ram_bar0_wea[desc_mm_target_function_r[2:0]] <= {16{1'b1}};
                        end
                        2'b00: begin
                            ram_bar0_wea[desc_mm_target_function_r[2:0]] <= {{12{1'b1}}, usr_first_be_r};
                        end
                        2'b11: begin
                            case (m_axis_cq_tkeep)
                            4'b0001: begin
                                ram_bar0_wea[desc_mm_target_function_r[2:0]] <= {12'b0, 4'b1111};
                            end
                            4'b0011: begin
                                ram_bar0_wea[desc_mm_target_function_r[2:0]] <= {8'b0, usr_last_be_r, 4'b1111};
                            end
                            4'b0111: begin
                                ram_bar0_wea[desc_mm_target_function_r[2:0]] <= {4'b0, usr_last_be_r, 4'b1111, 4'b1111};
                            end
                            4'b1111: begin
                                ram_bar0_wea[desc_mm_target_function_r[2:0]] <= {usr_last_be_r, {8{1'b1}}, 4'b1111};
                            end
                            default: begin
                                ram_bar0_wea[desc_mm_target_function_r[2:0]] <= 16'b0;
                            end
                            endcase
                        end
                        2'b10: begin
                            case (m_axis_cq_tkeep)
                            4'b0001: begin
                                ram_bar0_wea[desc_mm_target_function_r[2:0]] <= {12'b0, usr_first_be_r};
                            end
                            4'b0011: begin
                                ram_bar0_wea[desc_mm_target_function_r[2:0]] <= {8'b0, usr_last_be_r, usr_first_be_r};
                            end
                            4'b0111: begin
                                ram_bar0_wea[desc_mm_target_function_r[2:0]] <= {4'b0, usr_last_be_r, 4'b1111, usr_first_be_r};
                            end
                            4'b1111: begin
                                ram_bar0_wea[desc_mm_target_function_r[2:0]] <= {usr_last_be_r, {8{1'b1}}, usr_first_be_r};
                            end
                            default: begin
                                ram_bar0_wea[desc_mm_target_function_r[2:0]] <= 16'b0;
                            end
                            endcase
                        end
                        endcase

                        ram_bar0_dina[desc_mm_target_function_r[2:0]] <= m_axis_cq_tdata;
                        if (usr_first_be_used_r) begin
                            ram_bar0_addra[desc_mm_target_function_r[2:0]] <= {desc_mm_address_r} + 16; //, 2'b00} + 16;
                        end
                        else begin
                            ram_bar0_addra[desc_mm_target_function_r[2:0]] <= {desc_mm_address_r}; //, 2'b00};
                        end
                    end
                    3'b010: begin   // bar 2
                        case ({m_axis_cq_tlast, usr_first_be_used_r})
                        2'b01: begin
                            ram_bar2_wea[desc_mm_target_function_r[2:0]] <= {16{1'b1}};
                        end
                        2'b00: begin
                            ram_bar2_wea[desc_mm_target_function_r[2:0]] <= {{12{1'b1}}, usr_first_be_r};
                        end
                        2'b11: begin
                            case (m_axis_cq_tkeep)
                            4'b0001: begin
                                ram_bar2_wea[desc_mm_target_function_r[2:0]] <= {12'b0, 4'b1111};
                            end
                            4'b0011: begin
                                ram_bar2_wea[desc_mm_target_function_r[2:0]] <= {8'b0, usr_last_be_r, 4'b1111};
                            end
                            4'b0111: begin
                                ram_bar2_wea[desc_mm_target_function_r[2:0]] <= {4'b0, usr_last_be_r, 4'b1111, 4'b1111};
                            end
                            4'b1111: begin
                                ram_bar2_wea[desc_mm_target_function_r[2:0]] <= {usr_last_be_r, {8{1'b1}}, 4'b1111};
                            end
                            default: begin
                                ram_bar2_wea[desc_mm_target_function_r[2:0]] <= 16'b0;
                            end
                            endcase
                        end
                        2'b10: begin
                            case (m_axis_cq_tkeep)
                            4'b0001: begin
                                ram_bar2_wea[desc_mm_target_function_r[2:0]] <= {12'b0, usr_first_be_r};
                            end
                            4'b0011: begin
                                ram_bar2_wea[desc_mm_target_function_r[2:0]] <= {8'b0, usr_last_be_r, usr_first_be_r};
                            end
                            4'b0111: begin
                                ram_bar2_wea[desc_mm_target_function_r[2:0]] <= {4'b0, usr_last_be_r, 4'b1111, usr_first_be_r};
                            end
                            4'b1111: begin
                                ram_bar2_wea[desc_mm_target_function_r[2:0]] <= {usr_last_be_r, {8{1'b1}}, usr_first_be_r};
                            end
                            default: begin
                                ram_bar2_wea[desc_mm_target_function_r[2:0]] <= 16'b0;
                            end
                            endcase
                        end
                        endcase

                        ram_bar2_dina[desc_mm_target_function_r[2:0]] <= m_axis_cq_tdata;
                        if (usr_first_be_used_r) begin
                            ram_bar2_addra[desc_mm_target_function_r[2:0]] <= {desc_mm_address_r} + 16; //, 2'b00} + 16;
                        end
                        else begin
                            ram_bar2_addra[desc_mm_target_function_r[2:0]] <= {desc_mm_address_r};   //, 2'b00};
                        end
                       
                    end
                    endcase
                end
                else begin
                end
            end
        end
        5: begin
            if (s_axis_cc_tready[0]) begin
                for (integer i = 0; i < 4; i++) begin
                    if (usr_first_be_used_r) begin
                        ram_bar0_wea[i] <= 0;
                        ram_bar0_addra[i] <= ram_bar0_addra[i] + 'h10;
                        ram_bar2_wea[i] <= 0;
                        ram_bar2_addra[i] <= ram_bar2_addra[i] + 'h10;
                    end
                    else begin
                        ram_bar0_wea[i] <= 0;
                        ram_bar0_addra[i] <= ram_bar0_addra[i] + 'h04;
                        ram_bar2_wea[i] <= 0;
                        ram_bar2_addra[i] <= ram_bar2_addra[i] + 'h04;
                    end
                end
            end
        end
        endcase
    end


    always @(posedge clk) begin
        case (ns)
        0: begin
            c_hasprefix_r <= 0;
            c_mrd_32bit_r <= 0;
            c_mrd_64bit_r <= 0;
            c_mwr_32bit_r <= 0;
            c_mwr_64bit_r <= 0;
            c_unsupport_r <= 0;
            usr_first_be_used_r <= 0;
        end
        1: begin 
            if (m_axis_cq_tvalid & m_axis_cq_tready) begin
                usr_first_be_used_r <= 0;
                if (usr_sop_s) begin

                    // 0-256 dwords, zero length dword 1 first_be 0
                    desc_mm_dword_count_r <= m_axis_cq_tdata[64 + 8 + 3 - 1 : 64];
                    desc_mm_req_type_r <= m_axis_cq_tdata[64 + 8 + 3 - 1 + 4 - 1 : 64 + 8 + 3];
                    desc_mm_device_function_r <= m_axis_cq_tdata[64 + 16 + 7 : 64 + 16];
                    desc_mm_bus_r <= m_axis_cq_tdata[64 + 24 + 7 : 64 + 24];
                    desc_mm_tag_r <= m_axis_cq_tdata[64 + 32 + 7 : 64 + 32];
                    desc_mm_target_function_r <= m_axis_cq_tdata[64 + 40 + 7 : 64 + 40];
                    desc_mm_bar_id_r <= m_axis_cq_tdata[64 + 48 + 2 : 64 + 48];
                    desc_mm_bar_aperture_r <= m_axis_cq_tdata[64 + 48 + 8 : 64 + 48 + 3];
                    desc_mm_tc_r <= m_axis_cq_tdata[64 + 48 + 9 + 2 : 64 + 48 + 9];
                    desc_mm_attr_r <= m_axis_cq_tdata[64 + 48 + 9 + 5 : 64 + 48 + 9 + 3];
                    desc_mm_at_r <= m_axis_cq_tdata[1 : 0];
                    desc_mm_address_r <= {m_axis_cq_tdata[63 : 2], 2'b0};

                    request_tlp_desc_r <= m_axis_cq_tdata;
                    case (desc_mm_req_type_s) // only write request show be appeared here
                    'b0001: begin // mwr
                        c_mwr_64bit_r <= 1;
                        case (desc_mm_device_function_s)
                        'h0, 'h1, 'h2, 'h3: begin
                            c_unsupport_r <= c_unsupport_r;
                        end
                        default: begin
                            c_unsupport_r <= 1;
                        end
                        endcase
                    end
                    /* 'b1000: begin // ep cfgrd

                    end
                    'b1010: begin // ep cfgwr

                    end */
                    default: begin // uc
                        c_unsupport_r <= 1;
                    end
                    endcase
                    
                end
                else begin
                    
                end
            end
        end
        2: begin
            if (m_axis_cq_tvalid & m_axis_cq_tready) begin
                usr_first_be_used_r <= 1;
                if (c_mwr_64bit_r) begin

                    case (desc_mm_target_function_r)
                    'h0, 'h1, 'h2, 'h3: begin
                        c_unsupport_r <= c_unsupport_r;
                    end
                    default: begin
                        c_unsupport_r <= 1;
                    end
                    endcase

                end
                else begin
                    c_unsupport_r <= 1;
                end
            end
        end
        3: begin
            if (m_axis_cq_tvalid & m_axis_cq_tready) begin
                // usr_first_be_used_r <= 1;
                if (c_mwr_64bit_r) begin

                    case (desc_mm_target_function_r)
                    'h0, 'h1, 'h2, 'h3: begin
                        c_unsupport_r <= c_unsupport_r;
                    end
                    default: begin
                        c_unsupport_r <= 1;
                    end
                    endcase

                end
                else begin
                    c_unsupport_r <= 1;
                end
            end
            c_hasprefix_r <= 0;
            c_mrd_32bit_r <= 0;
            c_mrd_64bit_r <= 0;
            c_mwr_32bit_r <= 0;
            c_mwr_64bit_r <= 0;
            c_unsupport_r <= 0;
            // usr_first_be_used_r <= 0;
        end
        4: begin
            if (m_axis_cq_tvalid & m_axis_cq_tready) begin
                if (usr_sop_s) begin

                    // 0-256 dwords, zero length dword 1 first_be 0
                    desc_mm_dword_count_r <= m_axis_cq_tdata[64 + 8 + 3 - 1 : 64];
                    desc_mm_req_type_r <= m_axis_cq_tdata[64 + 8 + 3 - 1 + 4 - 1 : 64 + 8 + 3];
                    desc_mm_device_function_r <= m_axis_cq_tdata[64 + 16 + 7 : 64 + 16];
                    desc_mm_bus_r <= m_axis_cq_tdata[64 + 24 + 7 : 64 + 24];
                    desc_mm_tag_r <= m_axis_cq_tdata[64 + 32 + 7 : 64 + 32];
                    desc_mm_target_function_r <= m_axis_cq_tdata[64 + 40 + 7 : 64 + 40];
                    desc_mm_bar_id_r <= m_axis_cq_tdata[64 + 48 + 2 : 64 + 48];
                    desc_mm_bar_aperture_r <= m_axis_cq_tdata[64 + 48 + 8 : 64 + 48 + 3];
                    desc_mm_tc_r <= m_axis_cq_tdata[64 + 48 + 9 + 2 : 64 + 48 + 9];
                    desc_mm_attr_r <= m_axis_cq_tdata[64 + 48 + 9 + 5 : 64 + 48 + 9 + 3];
                    desc_mm_at_r <= m_axis_cq_tdata[1 : 0];
                    desc_mm_address_r <= {m_axis_cq_tdata[63 : 2], 2'b0};


                    case (desc_mm_req_type_s) // only read request show be appeared here
                    'b0000: begin // mrd
                        c_mrd_64bit_r <= 1;
                        case (desc_mm_device_function_s)
                        'h0, 'h1, 'h2, 'h3: begin
                            c_unsupport_r <= c_unsupport_r;
                        end
                        default: begin
                            c_unsupport_r <= 1;
                        end
                        endcase
                    end
                    default: begin // uc
                        c_unsupport_r <= 1;
                    end
                    endcase
                    
                end
                else begin
                    
                end
            end
            usr_first_be_used_r <= 0;
        end
        5: begin
            if (s_axis_cc_tready[0]) begin
                usr_first_be_used_r <= 1;
            end
            // c_unsupport_r
        end
        endcase
    end

    initial begin
        
    end

    always @(posedge clk) begin
        usr_first_be_used_rr <= usr_first_be_used_r;
    end

    always @(posedge clk) begin
        case (ns)
            default: begin
                cpl_start <= 0;
                m_axis_cq_tready <= 1;
            end
            4: begin
                cpl_start <= 0;
                m_axis_cq_tready <= 0;
            end
            5: begin
                if (s_axis_cc_tready[0] & ~usr_first_be_used_r) begin
                    cpl_start <= 1;
                end
                else begin
                    cpl_start <= 0;
                end
                m_axis_cq_tready <= 0;
            end
        endcase
    end

    (* MARK_DEBUG="true" *) reg [5:0] cpl_cs = 0, cpl_ns;
    
    reg cpl_done = 0;

    always @(posedge clk) begin
        if (rst) begin
            cpl_cs <= 0;
        end
        else begin
            cpl_cs <= cpl_ns;
        end
    end

    always @(*) begin
        case (cpl_cs)
        0: begin
            if (cpl_start) begin
                cpl_ns = 1;
            end
            else begin
                cpl_ns = 0;
            end
        end
        1: begin // must have header
            // if (cpl_done) begin
            //     cpl_ns = 0;
            // end
            // else begin
                cpl_ns = 2;
            // end
        end
        2: begin
            cpl_ns = 3;
        end
        3: begin // pure data
            if (s_axis_cc_tready[0] & s_axis_cc_tvalid) begin
                if (cpl_done) begin
                    cpl_ns = 0;
                end
                else begin
                    cpl_ns = 4;
                end
            end
            else begin
                cpl_ns = 3;
            end
        end
        4: begin
            if (s_axis_cc_tready[0] & s_axis_cc_tvalid) begin
                if (cpl_done) begin
                    cpl_ns = 0;
                end
                else begin
                    cpl_ns = 4;
                end
            end
            else begin
                cpl_ns = 4;
            end
        end
        default: begin
            cpl_ns = 0;
        end
        endcase
    end


    reg     [7:0]   cpl_desc_requester_bus;// = 0;
    reg     [7:0]   cpl_desc_requester_device_function;// = 0;
    reg             cpl_desc_poisoned_completion;// = 0;
    reg     [2:0]   cpl_desc_completion_status;// = 0;
    reg     [10:0]  cpl_desc_dword_count;// = 0;
    reg             cpl_desc_locked_read_completion;// = 0;
    reg     [12:0]  cpl_desc_byte_count;// = 0;
    reg     [1:0]   cpl_desc_at;// = 0;
    reg     [6:0]   cpl_desc_address;// = 0;
    reg             cpl_desc_force_ecrc;// = 0;
    reg     [2:0]   cpl_desc_attr;// = 0;
    reg     [2:0]   cpl_desc_tc;// = 0;
    reg             cpl_desc_completer_id_enable;// = 0;
    reg     [7:0]   cpl_desc_completer_bus;// = 0;
    reg     [7:0]   cpl_desc_completer_device_function;// = 0;
    reg     [7:0]   cpl_desc_tag;// = 0;

    reg [10:0] rest_dword_count, rest_dword_count_next;
    reg [12:0] rest_byte_count, rest_byte_count_next;

    reg [31:0] cpl_desc_total_byte_count_r, cpl_desc_cur_byte_count_r;
    reg [31:0] cpl_desc_cur_dword_count_r, cpl_desc_cur_byte_index_r;

    /* wire [32 * 3 : 0] cpl_desc = {cpl_desc_force_ecrc, cpl_desc_attr, cpl_desc_tc,
                                cpl_desc_completer_id_enable, cpl_desc_completer_bus,
                                cpl_desc_completer_device_function, cpl_desc_tag,
                                cpl_desc_requester_bus, cpl_desc_requester_device_function,
                                1'b0, cpl_desc_poisoned_completion, cpl_desc_completion_status,
                                cpl_desc_dword_count, 2'b0, cpl_desc_locked_read_completion,
                                cpl_desc_byte_count, 6'b0, cpl_desc_at, 1'b0, 
                                cpl_desc_address}; */
    always @(*) begin
        case (cpl_cs)
        default: begin
            // s_axis_cc_tdata = 0;
            cpl_desc_requester_bus = 0;
            cpl_desc_requester_device_function = 0;
            cpl_desc_poisoned_completion = 0;
            cpl_desc_completion_status = 0;
            cpl_desc_locked_read_completion = 0;
            cpl_desc_at = 0;
            cpl_desc_force_ecrc = 0;
            cpl_desc_attr = 0;
            cpl_desc_tc = 0;
            cpl_desc_completer_id_enable = 0;
            cpl_desc_completer_bus = 0;
            cpl_desc_completer_device_function = 0;
            cpl_desc_tag = 0;
            cpl_desc_dword_count = 0;
            cpl_desc_byte_count = 0;
            cpl_desc_address = 0;
        end
        2: begin
            if (c_mrd_64bit_r) begin //  && desc_mm_dword_count_r == 1 && usr_first_be_r[3:0] == 4'b1111
                // if (~s_axis_cc_tvalid) begin
                    
                    cpl_desc_requester_bus = desc_mm_bus_r;
                    cpl_desc_requester_device_function = desc_mm_device_function_r;
                    cpl_desc_poisoned_completion = 0;
                    cpl_desc_completion_status = 0;
                    cpl_desc_locked_read_completion = 0;
                    cpl_desc_at = desc_mm_at_r;
                    cpl_desc_force_ecrc = 0;
                    cpl_desc_attr = desc_mm_attr_r;     // 'b000;
                    cpl_desc_tc = desc_mm_tc_r;
                    cpl_desc_completer_id_enable = 0;
                    cpl_desc_completer_bus = 0;
                    cpl_desc_completer_device_function = desc_mm_target_function_r;
                    cpl_desc_tag = desc_mm_tag_r;

                    // cpl_desc_dword_count = 1;
                    // cpl_desc_byte_count = 4;
                    cpl_desc_dword_count = cpl_desc_cur_dword_count_r;
                    cpl_desc_byte_count = cpl_desc_cur_byte_count_r;

                    cpl_desc_address[2 + 4 : 2] = desc_mm_address_r[2 + 4 : 2];
                    casex (usr_first_be_r[3:0])
                    4'b0000: begin
                        cpl_desc_address[1:0] = 2'b00;
                    end
                    4'bxxx1: begin
                        cpl_desc_address[1:0] = 2'b00;
                    end
                    4'bxx10: begin
                        cpl_desc_address[1:0] = 2'b01;
                    end
                    4'bx100: begin
                        cpl_desc_address[1:0] = 2'b10;
                    end
                    4'b1000: begin
                        cpl_desc_address[1:0] = 2'b11;
                    end
                    endcase
                // end
                // else if (s_axis_cc_tvalid & s_axis_cc_tready[0]) begin

                // end
            end
            else begin

                cpl_desc_requester_bus = desc_mm_bus_r;
                cpl_desc_requester_device_function = desc_mm_device_function_r;
                cpl_desc_poisoned_completion = 0;
                cpl_desc_completion_status = 1;
                cpl_desc_dword_count = 0;
                cpl_desc_locked_read_completion = 0;
                cpl_desc_byte_count = 1;
                cpl_desc_at = 0;
                cpl_desc_address = 0;
                cpl_desc_force_ecrc = 0;
                cpl_desc_attr = desc_mm_attr_r;     // 'b000;
                cpl_desc_tc = desc_mm_tc_r;
                cpl_desc_completer_id_enable = 0;
                cpl_desc_completer_bus = 0;
                cpl_desc_completer_device_function = desc_mm_target_function_r;
                cpl_desc_tag = desc_mm_tag_r;

                // cpl_desc_dword_count <= cpl_desc_dword_count_next;
                // rest_dword_count <= rest_dword_count_next;
                // rest_byte_count <= rest_byte_count_next;
            end

        end
       
        endcase
    end

    

    always @(posedge clk) begin
        case (cpl_ns)
        1: begin
            casex ({usr_first_be_r[3:0], usr_last_be_r[3:0]})
            8'b1xx10000: cpl_desc_total_byte_count_r <= 4;
            8'b01x10000: cpl_desc_total_byte_count_r <= 3;
            8'b1x100000: cpl_desc_total_byte_count_r <= 3;
            8'b00110000: cpl_desc_total_byte_count_r <= 2;
            8'b01100000: cpl_desc_total_byte_count_r <= 2;
            8'b11000000: cpl_desc_total_byte_count_r <= 2;
            8'b00010000: cpl_desc_total_byte_count_r <= 1;
            8'b00100000: cpl_desc_total_byte_count_r <= 1;
            8'b01000000: cpl_desc_total_byte_count_r <= 1;
            8'b10000000: cpl_desc_total_byte_count_r <= 1;
            8'b00000000: cpl_desc_total_byte_count_r <= 1;
            8'bxxx11xxx: cpl_desc_total_byte_count_r <= desc_mm_dword_count_r * 4;
            8'bxxx101xx: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 1;
            8'bxxx1001x: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 2;
            8'bxxx10001: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 3;
            8'bxx101xxx: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 1;
            8'bxx1001xx: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 2;
            8'bxx10001x: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 3;
            8'bxx100001: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 4;
            8'bx1001xxx: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 2;
            8'bx10001xx: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 3;
            8'bx100001x: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 4;
            8'bx1000001: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 5;
            8'b10001xxx: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 3;
            8'b100001xx: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 4;
            8'b1000001x: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 5;
            8'b10000001: cpl_desc_total_byte_count_r <= (desc_mm_dword_count_r * 4) - 6;
            endcase
            /* case ({usr_last_be_r, usr_first_be_r})
            8'b11111111: begin
                cpl_desc_total_byte_count_r <= 4 * desc_mm_dword_count_r;
            end
            8'b11111110, 8'b01111111: begin
                cpl_desc_total_byte_count_r <= 4 * desc_mm_dword_count_r - 1;
            end
            8'b11111100, 8'b00111111, 8'b01111110: begin
                cpl_desc_total_byte_count_r <= 4 * desc_mm_dword_count_r - 2;
            end
            8'b11111000, 8'b00011111: begin
                cpl_desc_total_byte_count_r <= 4 * desc_mm_dword_count_r - 3;
            end
            8'b00011110, 8'b00111100, 8'b01111000: begin
                cpl_desc_total_byte_count_r <= 4 * desc_mm_dword_count_r - 4;
            end
            8'b00001111: begin // , 8'b00001111 illegal
                // if (desc_mm_dword_count_r == 1) begin
                cpl_desc_total_byte_count_r <= 4;
                // end
                // else begin
                //     cpl_desc_total_byte_count_r <= 0;  // illegal 4 * desc_mm_dword_count_r - 4;
                // end
            end
            8'b00000111, 8'b00001110: begin
                cpl_desc_total_byte_count_r <= 3;   // 4 * desc_mm_dword_count_r - 5;
            end
            8'b00001100, 8'b00000011, 8'b00000110: begin
                cpl_desc_total_byte_count_r <= 2;   // 4 * desc_mm_dword_count_r - 6;
            end
            8'b00001000, 8'b00000001, 8'b00000100, 8'b00000010: begin
                cpl_desc_total_byte_count_r <= 1;   // 4 * desc_mm_dword_count_r - 1;
            end
            8'b00000000: begin // zero length
                cpl_desc_total_byte_count_r <= 0;
            end
            default: begin
                cpl_desc_total_byte_count_r <= 0;
            end
            endcase */
            cpl_desc_cur_byte_count_r <= 0;
        end
        2: begin
            if (cpl_desc_total_byte_count_r >= 4096) begin
                cpl_desc_cur_byte_count_r <= 4096;
                cpl_desc_total_byte_count_r <= cpl_desc_total_byte_count_r - 4096;
                cpl_desc_cur_dword_count_r <= 1024;
            end
            else begin
                cpl_desc_cur_byte_count_r <= cpl_desc_total_byte_count_r;
                cpl_desc_total_byte_count_r <= 0;
                casex (usr_first_be_r[3:0])
                4'b0000: begin
                    cpl_desc_cur_dword_count_r <= (cpl_desc_total_byte_count_r + 3) >> 2;
                end
                4'bxxx1: begin
                    cpl_desc_cur_dword_count_r <= (cpl_desc_total_byte_count_r + 3) >> 2;
                end
                4'bxx10: begin
                    cpl_desc_cur_dword_count_r <= (cpl_desc_total_byte_count_r + 3 + 1) >> 2;
                end
                4'bx100: begin
                    cpl_desc_cur_dword_count_r <= (cpl_desc_total_byte_count_r + 3 + 2) >> 2;
                end
                4'b1000: begin
                    cpl_desc_cur_dword_count_r <= (cpl_desc_total_byte_count_r + 3 + 3) >> 2;
                end
                endcase
                // cpl_desc_cur_dword_count_r <= (cpl_desc_total_byte_count_r + 3) >> 2;
            end
        end
        default: begin
            cpl_desc_cur_byte_count_r <= 0;
            cpl_desc_total_byte_count_r <= 0;
            cpl_desc_cur_dword_count_r <= 0;
        end
        endcase
    end

    always @(posedge clk) begin
        case (cpl_ns)
        2: begin
            if (cpl_desc_total_byte_count_r >= 4096) begin
                cpl_desc_cur_byte_index_r <= 4096;
            end
            else begin
                cpl_desc_cur_byte_index_r <= cpl_desc_total_byte_count_r;
            end
        end
        3: begin
            if (s_axis_cc_tvalid & s_axis_cc_tready[0]) begin
                cpl_desc_cur_byte_index_r <= cpl_desc_cur_byte_index_r - 4;
            end
        end
        4: begin
            if (s_axis_cc_tvalid & s_axis_cc_tready[0]) begin
                cpl_desc_cur_byte_index_r <= cpl_desc_cur_byte_index_r - 16;
            end
        end
        endcase
    end

    always @(posedge clk) begin
        case (cpl_ns)
        0: begin
            cpl_done <= 0;
            cpl_ready <= 1;

            s_axis_cc_tvalid <= 0;
            s_axis_cc_tuser <= 2'b0;
            s_axis_cc_tkeep <= {16{1'b1}};
            s_axis_cc_tlast <= 0;
            s_axis_cc_tdata <= 0;
            rest_dword_count <= 0;
            rest_byte_count <= 0;
        end
        1, 2: begin
            cpl_ready <= 0;
            cpl_done <= 0;
        end
        3: begin
            cpl_ready <= 0;

            

            s_axis_cc_tdata[96 - 1 : 0] <= 
            {cpl_desc_force_ecrc, cpl_desc_attr, cpl_desc_tc,
            cpl_desc_completer_id_enable, cpl_desc_completer_bus,
            cpl_desc_completer_device_function, cpl_desc_tag,
            cpl_desc_requester_bus, cpl_desc_requester_device_function,
            1'b0, cpl_desc_poisoned_completion, cpl_desc_completion_status,
            cpl_desc_dword_count, 2'b0, cpl_desc_locked_read_completion,
            cpl_desc_byte_count, 6'b0, cpl_desc_at, 1'b0, 
            cpl_desc_address};

            

            if (c_mrd_64bit_r) begin    //   && desc_mm_dword_count_r == 1
                if (cpl_desc_cur_dword_count_r <= 1) begin  // cpl_desc_cur_byte_count_r <= 4) begin
                    cpl_done <= 1;
                    s_axis_cc_tlast <= 1;
                end
                else begin
                    cpl_done <= 0;
                    s_axis_cc_tlast <= 0;
                end
                s_axis_cc_tvalid <= 1;
                case (desc_mm_bar_id_r)
                3'b000: begin
                    case (desc_mm_device_function_r)
                    0: begin
                        s_axis_cc_tdata[127 : 96] <= ram_bar0_douta[0];
                    end
                    1: begin
                        s_axis_cc_tdata[127 : 96] <= ram_bar0_douta[1];
                    end
                    2: begin
                        s_axis_cc_tdata[127 : 96] <= ram_bar0_douta[2];
                    end
                    3: begin
                        s_axis_cc_tdata[127 : 96] <= ram_bar0_douta[3];
                    end
                    default: begin
                        s_axis_cc_tdata[127 : 96] <= 0;
                    end
                    endcase
                end
                3'b010: begin
                    case (desc_mm_device_function_r)
                    0: begin
                        s_axis_cc_tdata[127 : 96] <= ram_bar2_douta[0];
                    end
                    1: begin
                        s_axis_cc_tdata[127 : 96] <= ram_bar2_douta[1];
                    end
                    2: begin
                        s_axis_cc_tdata[127 : 96] <= ram_bar2_douta[2];
                    end
                    3: begin
                        s_axis_cc_tdata[127 : 96] <= ram_bar2_douta[3];
                    end
                    default: begin
                        s_axis_cc_tdata[127 : 96] <= 0;
                    end
                    endcase
                end
                endcase
                
                
            end
            else begin
                cpl_done <= 0;
                s_axis_cc_tlast <= 0;
                s_axis_cc_tvalid <= 1;

                s_axis_cc_tdata[127 : 96] <= 
                    {8'b0, usr_tph_st_tag_r, 5'd0, usr_tph_type_r, 
                    usr_tph_present_r, usr_last_be_r, usr_first_be_r};
            end

        end
        4: begin
            cpl_ready <= 0;
            
            if (s_axis_cc_tvalid & s_axis_cc_tready[0]) begin
                if (c_mrd_64bit_r) begin
                    

                    if (cpl_desc_cur_byte_index_r <= 4 * 4) begin
                        casex (cpl_desc_cur_byte_index_r[3:0])
                        4'b00xx, 4'b0100: s_axis_cc_tkeep <= 4'b0001;
                        4'b01xx, 4'b1000: s_axis_cc_tkeep <= 4'b0011;
                        4'b10xx, 4'b1100: s_axis_cc_tkeep <= 4'b0111;
                        4'b11xx, 4'b0000: s_axis_cc_tkeep <= 4'b1111;
                        // default: s_axis_cc_tkeep <= 4'b0000;
                        endcase
                        cpl_done <= 1;
                        s_axis_cc_tlast <= 1;
                    end
                    else begin
                        s_axis_cc_tkeep <= 4'b1111;
                        cpl_done <= 0;
                        s_axis_cc_tlast <= 0;
                    end

                    case (desc_mm_bar_id_r)
                    3'b000: begin
                        case (desc_mm_device_function_r)
                        0: begin
                            s_axis_cc_tdata <= ram_bar0_douta[0];
                        end
                        1: begin
                            s_axis_cc_tdata <= ram_bar0_douta[1];
                        end
                        2: begin
                            s_axis_cc_tdata <= ram_bar0_douta[2];
                        end
                        3: begin
                            s_axis_cc_tdata <= ram_bar0_douta[3];
                        end
                        default: begin
                            s_axis_cc_tdata <= 0;
                        end
                        endcase
                    end
                    3'b010: begin
                        case (desc_mm_device_function_r)
                        0: begin
                            s_axis_cc_tdata <= ram_bar2_douta[0];
                        end
                        1: begin
                            s_axis_cc_tdata <= ram_bar2_douta[1];
                        end
                        2: begin
                            s_axis_cc_tdata <= ram_bar2_douta[2];
                        end
                        3: begin
                            s_axis_cc_tdata <= ram_bar2_douta[3];
                        end
                        default: begin
                            s_axis_cc_tdata <= 0;
                        end
                        endcase
                    end
                    endcase

                end
                else begin
                    s_axis_cc_tdata <= request_tlp_desc_r;
                    cpl_done <= 1;
                    s_axis_cc_tlast <= 1;
                    s_axis_cc_tvalid <= 1;
                end
            end
        end
        endcase
    end

    enum logic [0:0] {
        IDLE,
        BUSY
    } watchdog_r[3:0] = '{IDLE, IDLE, IDLE, IDLE}, watchdog_s[3:0];

    wire watchdog_r_0 = watchdog_r[0];
    wire dma_watchdog_0 = dma_watchdog[0];

    generate for (genvar i = 0; i < 4; i++) begin
        always_ff @(posedge clk) begin
            watchdog_r[i] <= watchdog_s[i];
        end

        always_comb begin
            case (watchdog_r[i])
            IDLE: begin
                if (ram_bar0_wea[i] != 4'b0000) begin
                    if ((ram_bar0_addra[i][11:0] == 12'h114) || (ram_bar0_addra[i][11:0] == 12'h214)) begin
                        watchdog_s[i] = BUSY;
                    end else begin
                        watchdog_s[i] = IDLE;
                    end
                end else begin
                    watchdog_s[i] = IDLE;
                end
            end
            BUSY: begin
                if (dma_watchdog_ack[i]) begin
                    watchdog_s[i] = IDLE;
                end else begin
                    watchdog_s[i] = BUSY;
                end
            end
            default: watchdog_s[i] = IDLE;
            endcase
        end

        always_ff @(posedge clk) begin
            case (watchdog_s[i])
            BUSY: begin
                if (ram_bar0_wea[i] != 4'b0000) begin
                    if (ram_bar0_addra[i][11:0] == 12'h114) begin
                        dma_watchdog[i][0] <= 1;
                    end else if (ram_bar0_addra[i][11:0] == 12'h214) begin
                        dma_watchdog[i][1] <= 1;
                    end
                end
            end
            IDLE: begin
                dma_watchdog[i] <= 0;
            end
            endcase
        end

    end
    endgenerate


    /* always @(posedge clk) begin
        for (int i = 0; i < 4; i++) begin
            case (ram_bar0_addra[i] == 
        end
    end */
    generate
        for (genvar i = 0; i < 4; i++) begin
            ram_ctrl #(
                .RAM_DEPTH(1024)
            ) dwram_ctrl_bar0_inst (
                .clk(clk),
        
                .ram_douta(ram_bar0_douta[i]),
                .ram_doutb(ram_bar0_doutb[i]),
                .ram_byteaddra(ram_bar0_addra[i]),
                .ram_byteaddrb(ram_bar0_addrb[i]),
                .ram_dina(ram_bar0_dina[i]),
                .ram_dinb(ram_bar0_dinb[i]),
                .ram_wea(ram_bar0_wea[i]),
                .ram_web(ram_bar0_web[i]),
                .ram_ena(1'b1),
                .ram_enb(1'b1)
            );

            ram_ctrl #(
                .RAM_DEPTH(1024)
            ) dwram_ctrl_bar2_inst (
                .clk(clk),
        
                .ram_douta(ram_bar2_douta[i]),
                .ram_doutb(ram_bar2_doutb[i]),
                .ram_byteaddra(ram_bar2_addra[i]),
                .ram_byteaddrb(ram_bar2_addrb[i]),
                .ram_dina(ram_bar2_dina[i]),
                .ram_dinb(ram_bar2_dinb[i]),
                .ram_wea(ram_bar2_wea[i]),
                .ram_web(ram_bar2_web[i]),
                .ram_ena(1'b1),
                .ram_enb(1'b1)
            );
        end    
    endgenerate

endmodule
