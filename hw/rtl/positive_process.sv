`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: wjh776a68
// 
// Create Date: 09/12/2023 08:13:34 PM
// Design Name: 
// Module Name: positive_process
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


module positive_process #(
    parameter DATA_WIDTH = 512,
    parameter KEEP_WIDTH = DATA_WIDTH / 32,
    
    parameter RQ_USER_WIDTH = 137,
    parameter RC_USER_WIDTH = 161

) (
    input clk,
    input rst,

    (* MARK_DEBUG="true" *) output      [DATA_WIDTH - 1 : 0]        s_axis_rq_tdata,
    (* MARK_DEBUG="true" *) output      [KEEP_WIDTH - 1 : 0]        s_axis_rq_tkeep,
    (* MARK_DEBUG="true" *) output                                  s_axis_rq_tlast,
    (* MARK_DEBUG="true" *) input       [3 : 0]                     s_axis_rq_tready,
    (* MARK_DEBUG="true" *) output      [RQ_USER_WIDTH - 1 : 0]     s_axis_rq_tuser,
    (* MARK_DEBUG="true" *) output                                  s_axis_rq_tvalid,
                            
    (* MARK_DEBUG="true" *) input       [DATA_WIDTH - 1 : 0]        m_axis_rc_tdata,
    (* MARK_DEBUG="true" *) input       [KEEP_WIDTH - 1 : 0]        m_axis_rc_tkeep,
    (* MARK_DEBUG="true" *) input                                   m_axis_rc_tlast,
    (* MARK_DEBUG="true" *) output                                  m_axis_rc_tready,
    (* MARK_DEBUG="true" *) input       [RC_USER_WIDTH - 1 : 0]     m_axis_rc_tuser,
    (* MARK_DEBUG="true" *) input                                   m_axis_rc_tvalid,

    input  wire [127:0]  ram_ctl_dout[3:0],
    output reg  [63:0]   ram_ctl_addr[3:0],
    output reg  [127:0]  ram_ctl_din[3:0],
    output reg  [15:0]   ram_ctl_we[3:0],

    input  wire [127:0]  ram_mem_dout[3:0],
    output wire [63:0]   ram_mem_addr[3:0],
    output wire [127:0]  ram_mem_din[3:0],
    output wire [15:0]   ram_mem_we[3:0],

    input   logic [1:0] dma_watchdog[3:0],
    output  logic [1:0] dma_watchdog_ack[3:0],

    output  logic            irq_valid,
    output  logic [3 : 0]    irq_func,
    output  logic [63 : 0]   irq_addr,
    output  logic [31 : 0]   irq_data,
    input   logic            irq_ready,

    output reg             indicator

); 

    function logic [3:0] bin2onehot(input logic [1:0] func);
        case (func)
        2'b00: return 4'b0001;
        2'b01: return 4'b0010;
        2'b10: return 4'b0100;
        2'b11: return 4'b1000;
        endcase
    endfunction


    initial begin
        for (int i = 0; i < 4; i++) begin
            ram_ctl_addr[i] = 0;
            ram_ctl_din[i] = 0;
            ram_ctl_we[i] = 0;
        end
    end

    wire [127:0] ram_ctl_dout_s = ram_ctl_dout[0];
    wire [63:0]  ram_ctl_addr_s = ram_ctl_addr[0];
    wire [127:0] ram_ctl_din_s = ram_ctl_din[0];
    wire [15:0]  ram_ctl_we_s = ram_ctl_we[0];

    initial begin
        indicator = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            indicator <= 0;
        end
        else begin
            if (m_axis_rc_tvalid & m_axis_rc_tready) begin
                indicator <= 1;
            end
            else begin
                indicator <= indicator;
            end
        end
    end

    reg [2:0] func_counter_r, func_counter_s;
    reg [1:0] func_dev, func_dev_r, func_dev_rr;
    reg [63:0] ram_ctl_addr_r[3:0], ram_ctl_addr_rr[3:0], ram_ctl_addr_rrr[3:0];
    wire [63:0] ram_ctl_addr_rr_s = ram_ctl_addr_rr[0];

    reg [63:0] allure_addr_cnt = 0;

    wire       dma_trans_finish_s; 
    reg        dma_trans_valid_r;
    reg        dma_trans_mode_r; 
    reg [1:0]  dma_trans_function_r;
    reg [63:0] dma_trans_cpu_region_addr_r;
    reg [63:0] dma_trans_fpga_region_addr_r;
    reg [31:0] dma_trans_transfer_len_r;
    reg [31:0] dma_trans_tag_r;
    
    reg [31:0] dma_trans_tag_out_r;
    
    (* MARK_DEBUG="true" *) enum logic [3:0] {
        IDLE,
        REQDECODE,
        READDMAINFO,
        GENDMAREQ,
        DMABUSY,
        GENINTR,
        UPDATEDMASTATUS
    } snoop_r = IDLE, snoop_s;

    always @(posedge clk) begin
        if (rst) begin
            snoop_r <= IDLE;
        end else begin
            snoop_r <= snoop_s;
        end
    end

    logic [7:0] dma_watchdogs_s, dma_watchdog_ack_r;
    logic [2:0] readdma_cnt_r;
    
    assign dma_watchdogs_s[1:0] = dma_watchdog[0][1:0];
    assign dma_watchdogs_s[3:2] = dma_watchdog[1][1:0];
    assign dma_watchdogs_s[5:4] = dma_watchdog[2][1:0];
    assign dma_watchdogs_s[7:6] = dma_watchdog[3][1:0];

    assign dma_watchdog_ack[0][1:0] = dma_watchdog_ack_r[1:0];
    assign dma_watchdog_ack[1][1:0] = dma_watchdog_ack_r[3:2];
    assign dma_watchdog_ack[2][1:0] = dma_watchdog_ack_r[5:4];
    assign dma_watchdog_ack[3][1:0] = dma_watchdog_ack_r[7:6];


    always_comb begin
        case (snoop_r)
        IDLE: begin
            if (|{dma_watchdogs_s}) begin
                snoop_s = REQDECODE;
            end else begin
                snoop_s = IDLE;
            end
        end
        REQDECODE: begin
            snoop_s = READDMAINFO;
        end
        READDMAINFO: begin
            if (readdma_cnt_r == 'd5) begin
                snoop_s = GENDMAREQ;
            end else begin
                snoop_s = READDMAINFO;
            end
        end
        GENDMAREQ: begin
            if (dma_trans_valid_r) begin
                snoop_s = DMABUSY;
            end else begin
                snoop_s = UPDATEDMASTATUS;
            end
        end
        DMABUSY: begin
            if (dma_trans_finish_s) begin
                snoop_s = GENINTR; 
            end else begin
                snoop_s = DMABUSY;
            end
        end
        GENINTR: begin
            if (irq_valid & irq_ready) begin
                snoop_s = UPDATEDMASTATUS;
            end else begin
                snoop_s = GENINTR;
            end
        end
        UPDATEDMASTATUS: begin
            snoop_s = IDLE;
        end
        default: snoop_s = IDLE;
        endcase
    end


    always @(posedge clk) begin
        case (snoop_s)
        IDLE: begin
            readdma_cnt_r <= 'd0;
        end
        READDMAINFO: begin
            readdma_cnt_r <= readdma_cnt_r + 'd1;
        end
        endcase
    end

    logic mode_r;
    logic [1:0] function_r;
    
    always @(posedge clk) begin
        case (snoop_s)
        GENINTR: begin
            irq_valid <= 1;
            irq_func  <= bin2onehot(dma_trans_function_r);
            irq_addr  <= ram_ctl_dout[function_r][63 : 0];
            irq_data  <= ram_ctl_dout[function_r][95 : 64]; 
        end
        default: begin
            irq_valid <= 0;
        end
        endcase
    end

    always @(posedge clk) begin
        case (snoop_s)
        GENDMAREQ: begin
            dma_trans_mode_r <= mode_r;
            dma_trans_function_r <= function_r;
            if (dma_trans_tag_out_r == dma_trans_tag_r) begin
                dma_trans_valid_r <= 0;
            end else begin
                dma_trans_valid_r <= 1;
            end
        end
        DMABUSY: begin
        end
        default: begin
            dma_trans_valid_r <= 0;
        end
        endcase
    end

    always @(posedge clk) begin
        case (snoop_s)
        READDMAINFO: begin
            if (mode_r) begin 
                case (readdma_cnt_r)
                3: begin
                    dma_trans_cpu_region_addr_r <= ram_ctl_dout[function_r][63 -: 64];
                    dma_trans_fpga_region_addr_r <= ram_ctl_dout[function_r][127 -: 64];
                end
                4: begin
                    dma_trans_transfer_len_r <= ram_ctl_dout[function_r][31 -: 32];
                    dma_trans_tag_r <= ram_ctl_dout[function_r][63 -: 32];
                    dma_trans_tag_out_r <= ram_ctl_dout[function_r][95 -: 32];
                end
                endcase
            end else begin 
                case (readdma_cnt_r)
                3: begin
                    dma_trans_cpu_region_addr_r <= ram_ctl_dout[function_r][63 -: 64];
                    dma_trans_fpga_region_addr_r <= ram_ctl_dout[function_r][127 -: 64];
                end
                4: begin
                    dma_trans_transfer_len_r <= ram_ctl_dout[function_r][31 -: 32];
                    dma_trans_tag_r <= ram_ctl_dout[function_r][63 -: 32];
                    dma_trans_tag_out_r <= ram_ctl_dout[function_r][95 -: 32];
                end
                endcase
            end
        end
        endcase
    end

    always @(posedge clk) begin
        case (snoop_s)
        UPDATEDMASTATUS: begin
            dma_watchdog_ack_r[2 * function_r + mode_r] <= 1'b1;
        end
        default: begin
            dma_watchdog_ack_r[7:0] <= 8'h0;
        end
        endcase
    end

    always @(posedge clk) begin
        case (snoop_s)
        IDLE: begin
            ram_ctl_addr[0] <= 64'h000; 
            ram_ctl_addr[1] <= 64'h000;
            ram_ctl_addr[2] <= 64'h000;
            ram_ctl_addr[3] <= 64'h000;
            ram_ctl_we[0] <= 16'h0;
            ram_ctl_we[1] <= 16'h0;
            ram_ctl_we[2] <= 16'h0;
            ram_ctl_we[3] <= 16'h0;
        end
        REQDECODE: begin
            casex(dma_watchdogs_s)
            8'bxxxxxxx1: begin
                ram_ctl_addr[0] <= 64'h100; 
            end
            8'bxxxxxx10: begin
                ram_ctl_addr[0] <= 64'h200; 
            end
            8'bxxxxx100: begin
                ram_ctl_addr[1] <= 64'h100; 
            end
            8'bxxxx1000: begin
                ram_ctl_addr[1] <= 64'h200; 
            end
            8'bxxx10000: begin
                ram_ctl_addr[2] <= 64'h100; 
            end
            8'bxx100000: begin
                ram_ctl_addr[2] <= 64'h200; 
            end
            8'bx1000000: begin
                ram_ctl_addr[3] <= 64'h100; 
            end
            8'b10000000: begin
                ram_ctl_addr[3] <= 64'h200; 
            end
            endcase
        end
        READDMAINFO: begin
            ram_ctl_addr[function_r] <= ram_ctl_addr[function_r] + 64'h10;
        end
        GENDMAREQ: begin
            ram_ctl_addr[function_r] <= 'h40;
        end
        UPDATEDMASTATUS: begin
            if (mode_r) begin 
                ram_ctl_addr[function_r] <= 'h210;
                ram_ctl_we[function_r] <= {4'h0, 4'hf, 4'h0, 4'h0};
                ram_ctl_din[function_r] <= {32'h0, dma_trans_tag_r[31:0], 32'h0, 32'h0};
            end else begin 
                ram_ctl_addr[function_r] <= 'h110;
                ram_ctl_we[function_r] <= {4'h0, 4'hf, 4'h0, 4'h0};
                ram_ctl_din[function_r] <= {32'h0, dma_trans_tag_r[31:0], 32'h0, 32'h0};
            end
        end
        endcase
    end

    always @(posedge clk) begin
        case (snoop_s)
        REQDECODE: begin
            casex(dma_watchdogs_s)
            8'bxxxxxxx1: begin
                mode_r <= 0; 
                function_r <= 0; 
            end
            8'bxxxxxx10: begin
                mode_r <= 1; 
                function_r <= 0; 
            end
            8'bxxxxx100: begin
                mode_r <= 0; 
                function_r <= 1; 
            end
            8'bxxxx1000: begin
                mode_r <= 1; 
                function_r <= 1; 
            end
            8'bxxx10000: begin
                mode_r <= 0; 
                function_r <= 2; 
            end
            8'bxx100000: begin
                mode_r <= 1; 
                function_r <= 2; 
            end
            8'bx1000000: begin
                mode_r <= 0; 
                function_r <= 3; 
            end
            8'b10000000: begin
                mode_r <= 1; 
                function_r <= 3; 
            end
            default: begin

            end
            endcase
        end
        endcase
    end


    dma_simple #(
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH),
    
        .RQ_USER_WIDTH(RQ_USER_WIDTH),
        .RC_USER_WIDTH(RC_USER_WIDTH)
        
    ) dma_simple_inst (
        .clk(clk),
        .rst(rst),

        .dma_trans_finish               (dma_trans_finish_s), 
        .dma_trans_valid                (dma_trans_valid_r),
        .dma_trans_mode                 (dma_trans_mode_r), 
        .dma_trans_function             (dma_trans_function_r        ),
        .dma_trans_cpu_region_addr      (dma_trans_cpu_region_addr_r ),
        .dma_trans_fpga_region_addr     (dma_trans_fpga_region_addr_r),
        .dma_trans_transfer_len         (dma_trans_transfer_len_r    ),
        
        .s_axis_rq_tdata(s_axis_rq_tdata),
        .s_axis_rq_tkeep(s_axis_rq_tkeep),
        .s_axis_rq_tlast(s_axis_rq_tlast),
        .s_axis_rq_tready(s_axis_rq_tready),
        .s_axis_rq_tuser(s_axis_rq_tuser),
        .s_axis_rq_tvalid(s_axis_rq_tvalid),

        .m_axis_rc_tdata(m_axis_rc_tdata),
        .m_axis_rc_tkeep(m_axis_rc_tkeep),
        .m_axis_rc_tlast(m_axis_rc_tlast),
        .m_axis_rc_tready(m_axis_rc_tready),
        .m_axis_rc_tuser(m_axis_rc_tuser),
        .m_axis_rc_tvalid(m_axis_rc_tvalid),

        .ram_mem_dout(ram_mem_dout),
        .ram_mem_addr(ram_mem_addr),
        .ram_mem_din(ram_mem_din),
        .ram_mem_we(ram_mem_we)

    );


endmodule
