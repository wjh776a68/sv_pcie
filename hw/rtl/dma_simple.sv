`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: wjh776a68
// 
// Create Date: 09/25/2023 04:42:47 PM
// Design Name: 
// Module Name: dma_simple
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


module dma_simple #(
    parameter DATA_WIDTH = 512,
    parameter KEEP_WIDTH = DATA_WIDTH / 32,
    
    parameter RQ_USER_WIDTH = 137,
    parameter RC_USER_WIDTH = 161
    
) (
    input clk,
    input rst,

    output reg      dma_trans_finish            ,
    input           dma_trans_valid             ,
    input           dma_trans_mode              ,
    input   [1:0]   dma_trans_function          ,
    input   [63:0]  dma_trans_cpu_region_addr   ,
    input   [63:0]  dma_trans_fpga_region_addr  ,
    input   [31:0]  dma_trans_transfer_len      ,

    output reg  [DATA_WIDTH - 1 : 0]        s_axis_rq_tdata,
    output reg  [KEEP_WIDTH - 1 : 0]        s_axis_rq_tkeep,
    output reg                              s_axis_rq_tlast,
    input       [3 : 0]                     s_axis_rq_tready,
    output reg  [RQ_USER_WIDTH - 1 : 0]     s_axis_rq_tuser,
    output reg                              s_axis_rq_tvalid,

    input       [DATA_WIDTH - 1 : 0]        m_axis_rc_tdata,
    input       [KEEP_WIDTH - 1 : 0]        m_axis_rc_tkeep,
    input                                   m_axis_rc_tlast,
    output reg                              m_axis_rc_tready,
    input       [RC_USER_WIDTH - 1 : 0]     m_axis_rc_tuser,
    input                                   m_axis_rc_tvalid,

    input  wire [127:0]  ram_mem_dout[3:0],
    output reg  [63:0]   ram_mem_addr[3:0],
    output reg  [127:0]  ram_mem_din[3:0],
    output reg  [15:0]   ram_mem_we[3:0]

);


    reg [2:0] rr_flag_r = 0;
    (* MARK_DEBUG="true" *) reg [4:0] cs = 0, ns;

    reg cpl_start = 0, cpl_done = 0;

    reg last_trans_flag_r;
    reg [31:0] dma_trans_high_addr;

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
            ns = 1;
        end
        1: begin
            ns = 2;
        end
        2: begin
            if (dma_trans_valid) begin
                ns = 7;
            end
            else begin
                ns = 2; 
            end
        end
        7: begin    
            if (s_axis_rq_tready[0]) begin
                ns = 8;
            end
            else begin
                ns = 7;
            end
        end
        8: begin    
            if (s_axis_rq_tready[0]) begin
                ns = 3;
            end
            else begin
                ns = 8;
            end
        end
        3: begin
            if (s_axis_rq_tvalid && s_axis_rq_tready[0]) begin
                if (dma_trans_mode) begin 
                    ns = 4;
                end
                else begin
                    ns = 5;
                end
            end
            else begin
                ns = 3;
            end
        end
        4: begin 
            if (s_axis_rq_tvalid && s_axis_rq_tready[0] & s_axis_rq_tlast) begin
                ns = 6;
            end
            else begin
                ns = 4;
            end
        end
        5: begin 
            if (~cpl_start & cpl_done & last_trans_flag_r) begin
                ns = 6;
            end
            else begin
                ns = 5;
            end
        end
        6: begin 
            ns = 0;
        end
        default: begin
            ns = 0;
        end
        endcase
    end

    always @(posedge clk) begin
        case (ns)
        6: dma_trans_finish <= 1; 
        default: dma_trans_finish <= 0;
        endcase
    end


    reg [3:0]   usr_first_be_r;
    reg [3:0]   usr_last_be_r;
    reg [2:0]   usr_addr_offset_r;
    reg [0:0]   usr_discontinue_r;
    reg [0:0]   usr_tph_present_r;
    reg [1:0]   usr_tph_type_r;
    reg [0:0]   usr_tph_indirect_tag_en_r;
    reg [7:0]   usr_tph_st_tag_r;
    reg [3:0]   usr_lo_seq_num_r;
    reg [31:0]  usr_parity_r;
    reg [1:0]   usr_hi_seq_num_r;

    always @(*) begin
        s_axis_rq_tuser = {
                            usr_hi_seq_num_r,
                            usr_parity_r,
                            usr_lo_seq_num_r,
                            usr_tph_st_tag_r,
                            usr_tph_indirect_tag_en_r,
                            usr_tph_type_r,
                            usr_tph_present_r,
                            usr_discontinue_r,
                            usr_addr_offset_r,
                            usr_last_be_r,
                            usr_first_be_r};

    end

    reg [1:0]  desc_mm_at_r;
    reg [61:0] desc_mm_address_r;
    reg [10:0] desc_mm_dword_count_r;
    reg [3:0]  desc_mm_req_type_r;
    reg [0:0]  desc_mm_poisoned_request_r;
    reg [7:0]  desc_mm_req_device_function_r;
    reg [7:0]  desc_mm_req_bus_r;
    reg [7:0]  desc_mm_tag_r;
    reg [7:0]  desc_mm_cpl_device_function_r;
    reg [7:0]  desc_mm_cpl_bus_r;
    reg [0:0]  desc_mm_req_id_enable_r;
    reg [2:0]  desc_mm_tc_r;
    reg [2:0]  desc_mm_attr_r;
    reg [0:0]  desc_mm_force_ecrc_r;

    always @(*) begin
        desc_mm_at_r <= 2'b00;
        desc_mm_address_r <= dma_trans_cpu_region_addr >> 2;
        desc_mm_dword_count_r <= dma_trans_transfer_len >> 2;
        desc_mm_req_type_r <= {3'b0, dma_trans_mode} ; 
        desc_mm_poisoned_request_r <= 1'b0;
        desc_mm_req_device_function_r <= {6'b00000, dma_trans_function}; 
        desc_mm_req_bus_r <= 8'b00000000;
        desc_mm_tag_r <= 'b0;
        desc_mm_cpl_device_function_r <= 8'b00000000; 
        desc_mm_cpl_bus_r <= 8'b00000000;
        desc_mm_req_id_enable_r <= 1'b0;
        desc_mm_tc_r <= 3'b000;
        desc_mm_attr_r <= 3'b000;
        desc_mm_force_ecrc_r <= 1'b0;
    end

    reg [1:0] mem_first_rd_flag_r = 0;
    reg [3:0] last_mem_size = 0;
    always @(posedge clk) begin
        if (m_axis_rc_tready & m_axis_rc_tvalid & m_axis_rc_tlast) begin
            case (m_axis_rc_tkeep)
            default: begin
                last_mem_size <= 0;
            end
            4'b0001: begin
                last_mem_size <= 4;
            end
            4'b0011: begin
                last_mem_size <= 8;
            end
            4'b0111: begin
                last_mem_size <= 12;
            end
            4'b1111: begin
                last_mem_size <= 16;
            end
            endcase
        end
    end

    always @(posedge clk) begin
        case (ns)
        5: begin
            if (m_axis_rc_tready & m_axis_rc_tvalid) begin
                case (mem_first_rd_flag_r)
                0: begin
                    mem_first_rd_flag_r <= 1;
                end
                1: begin
                    mem_first_rd_flag_r <= 2;
                end
                2: begin
                    if (m_axis_rc_tlast) begin
                        mem_first_rd_flag_r <= 3;
                    end
                    else begin
                        mem_first_rd_flag_r <= 2;
                    end
                end
                3: begin
                    mem_first_rd_flag_r <= 1;
                end
                endcase
            end
        end
        default: begin
            mem_first_rd_flag_r <= 0;
        end
        endcase
    end

    reg [63:0] ram_mem_addr_rr;

    always @(posedge clk) begin
        case (ns)
        default: begin
            last_trans_flag_r <= 0;
        end
        5: begin
            
            if (ram_mem_addr_rr + last_mem_size == dma_trans_high_addr) begin
                last_trans_flag_r <= 1;
            end
            else begin
                last_trans_flag_r <= 0;
            end
            
        end
        endcase
    end

    always @(posedge clk) begin
        case (ns)
        2: begin
            ram_mem_addr[dma_trans_function] <= dma_trans_fpga_region_addr; 
            
            dma_trans_high_addr <= dma_trans_fpga_region_addr + dma_trans_transfer_len;
        end
        7: begin
            if (s_axis_rq_tready[0]) begin
                ram_mem_addr[dma_trans_function] <= ram_mem_addr[dma_trans_function] + 16; 
            end
        end
        8: begin
            if (s_axis_rq_tready[0]) begin
                ram_mem_addr[dma_trans_function] <= ram_mem_addr[dma_trans_function] + 16; 
            end
        end
        3: begin
            if (s_axis_rq_tready[0]) begin
                ram_mem_addr[dma_trans_function] <= ram_mem_addr[dma_trans_function] + 16; 
            end
        end
        4: begin
            if (s_axis_rq_tready[0]) begin
                ram_mem_addr[dma_trans_function] <= ram_mem_addr[dma_trans_function] + 16; 
            end
        end
        5: begin
            if (m_axis_rc_tready & m_axis_rc_tvalid) begin
                case (mem_first_rd_flag_r) 
                default: begin 
                    ram_mem_addr_rr <= ram_mem_addr[dma_trans_function] + 16;
                end
                3: begin
                    ram_mem_addr_rr <= ram_mem_addr_rr;
                end
                endcase

                case (mem_first_rd_flag_r) 
                0: begin
                    ram_mem_addr[dma_trans_function] <= dma_trans_fpga_region_addr; 
                end
                1: begin
                    ram_mem_addr[dma_trans_function] <= ram_mem_addr[dma_trans_function] + 4; 
                end
                2: begin
                    ram_mem_addr[dma_trans_function] <= ram_mem_addr[dma_trans_function] + 16; 
                end
                3: begin
                    ram_mem_addr[dma_trans_function] <= ram_mem_addr_rr + last_mem_size;
                end
                endcase
            end
        end
        
        default: begin
            
        end
        endcase
    end

    reg [31:0] dma_remain_cnt_r;

    always @(posedge clk) begin
        case (ns)
        3: begin
            usr_first_be_r <= 4'b1111;
            usr_last_be_r <= 4'b1111;
            usr_addr_offset_r <= 3'b000;
            usr_discontinue_r <= 1'b0;
            usr_tph_present_r <= 1'b0;
            usr_tph_type_r <= 2'b00;
            usr_tph_indirect_tag_en_r <= 1'b0;
            usr_tph_st_tag_r <= 8'b00000000;
            usr_lo_seq_num_r <= 4'b0000;
            usr_parity_r <= 32'b0;
            usr_hi_seq_num_r <= 2'b00;

            if (dma_trans_mode) begin 
                s_axis_rq_tlast <= 0;
            end
            else begin
                s_axis_rq_tlast <= 1;
            end
            s_axis_rq_tdata <= {
                                desc_mm_force_ecrc_r,
                                desc_mm_attr_r,
                                desc_mm_tc_r,
                                desc_mm_req_id_enable_r,
                                desc_mm_cpl_bus_r,
                                desc_mm_cpl_device_function_r,
                                desc_mm_tag_r,
                                desc_mm_req_bus_r,
                                desc_mm_req_device_function_r,
                                desc_mm_poisoned_request_r,
                                desc_mm_req_type_r,
                                desc_mm_dword_count_r,
                                desc_mm_address_r,
                                desc_mm_at_r};
            s_axis_rq_tkeep <= 4'hf;
            s_axis_rq_tvalid <= 1;

            dma_remain_cnt_r <= dma_trans_transfer_len;
        end
        4: begin
            s_axis_rq_tkeep <= 4'hf;
            s_axis_rq_tvalid <= 1;
            if (s_axis_rq_tready[0] & s_axis_rq_tvalid) begin
                if (dma_remain_cnt_r <= 16) begin
                    s_axis_rq_tlast <= 1;
                    dma_remain_cnt_r <= 0;
                end
                else begin
                    s_axis_rq_tlast <= 0;
                    dma_remain_cnt_r <= dma_remain_cnt_r - 16;
                end
                
                s_axis_rq_tdata <= ram_mem_dout[dma_trans_function];
            end
        end
        5: begin
            s_axis_rq_tvalid <= 0;
        end
        default: begin
            s_axis_rq_tvalid <= 0;
        end
        endcase
    end


    always @(posedge clk) begin
        case (ns)
        5: begin
            if (cpl_done) begin
                cpl_start <= 1;
            end
            else begin
                cpl_start <= 0;
            end
        end
        default: begin
            cpl_start <= 0;
        end
        endcase
    end

    reg [5:0] cpl_cs = 0, cpl_ns;

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
        1: begin
            if (m_axis_rc_tready & m_axis_rc_tvalid) begin 
                cpl_ns = 2;
            end
            else begin
                cpl_ns = 1;
            end
        end
        2: begin 
            if (m_axis_rc_tready & m_axis_rc_tvalid) begin
                cpl_ns = 3;
            end
            else begin
                cpl_ns = 2;
            end
        end
        3: begin 
            if (m_axis_rc_tready & m_axis_rc_tvalid & m_axis_rc_tlast) begin
                cpl_ns = 4;
            end
            else begin
                cpl_ns = 3;
            end
        end
        4: begin 
            cpl_ns = 0;
        end
        default: begin
            cpl_ns = 0;
        end
        endcase
    end

    always @(posedge clk) begin
        case (cpl_ns)
        0: begin
            cpl_done <= 1;
            m_axis_rc_tready <= 0;
        end
        4: begin
            cpl_done <= 0;
            m_axis_rc_tready <= 0;
        end
        default: begin
            cpl_done <= 0;
            m_axis_rc_tready <= 1;
        end
        endcase
    end

    always @(posedge clk) begin
        case (cpl_ns)
        2: begin 
            
            if (m_axis_rc_tvalid & m_axis_rc_tready) begin
                ram_mem_we[dma_trans_function] <= {12'b0, 4'hf};
                ram_mem_din[dma_trans_function] <= m_axis_rc_tdata[127 -: 32];
            end
            else begin
                ram_mem_we[dma_trans_function] <= 'b0;
            end
        end
        3: begin
            if (m_axis_rc_tvalid & m_axis_rc_tready) begin
                ram_mem_we[dma_trans_function] <= {16'hffff};
                ram_mem_din[dma_trans_function] <= m_axis_rc_tdata;
            end
            else begin
                ram_mem_we[dma_trans_function] <= 'b0;
            end
        end
        4: begin
            if (m_axis_rc_tvalid & m_axis_rc_tready & m_axis_rc_tlast) begin
                ram_mem_we[dma_trans_function] <= {{4{m_axis_rc_tkeep[3]}}, {4{m_axis_rc_tkeep[2]}}, {4{m_axis_rc_tkeep[1]}}, {4{m_axis_rc_tkeep[0]}}}; 
                ram_mem_din[dma_trans_function] <= m_axis_rc_tdata;
            end
            else begin
                ram_mem_we[dma_trans_function] <= 'b0;
            end
        end
        default: begin
            
            ram_mem_we[0] <= 0;
            ram_mem_we[1] <= 0;
            ram_mem_we[2] <= 0;
            ram_mem_we[3] <= 0;
        end
        endcase
    end

endmodule
