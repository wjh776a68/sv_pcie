`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: wjh776a68
// 
// Create Date: 09/12/2023 08:13:34 PM
// Design Name: 
// Module Name: user_core
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

module user_core # (
    parameter LANE_NUM = 4,
    parameter DATA_WIDTH = 128,
    parameter KEEP_WIDTH = DATA_WIDTH / 32,
    
    parameter RQ_USER_WIDTH = 62,
    parameter RC_USER_WIDTH = 75,
    parameter CQ_USER_WIDTH = 88,
    parameter CC_USER_WIDTH = 33
) (
    input clk,
    input rst,

    output wire [DATA_WIDTH - 1 : 0]  s_axis_rq_tdata,
    output wire [KEEP_WIDTH - 1 : 0]    s_axis_rq_tkeep,
    output wire            s_axis_rq_tlast,
    input wire [3 : 0]    s_axis_rq_tready,
    output wire [RQ_USER_WIDTH - 1 : 0]   s_axis_rq_tuser,
    output wire            s_axis_rq_tvalid,

    input wire [DATA_WIDTH - 1 : 0]  m_axis_rc_tdata,
    input wire [KEEP_WIDTH - 1 : 0]    m_axis_rc_tkeep,
    input wire            m_axis_rc_tlast,
    output wire            m_axis_rc_tready,
    input wire [RC_USER_WIDTH - 1 : 0]   m_axis_rc_tuser,
    input wire            m_axis_rc_tvalid,

    
    input wire [DATA_WIDTH - 1 : 0]  m_axis_cq_tdata,
    input wire [KEEP_WIDTH - 1 : 0]    m_axis_cq_tkeep,
    input wire            m_axis_cq_tlast,
    output wire            m_axis_cq_tready,
    input wire [CQ_USER_WIDTH - 1 : 0]   m_axis_cq_tuser,
    input wire            m_axis_cq_tvalid,

    output wire [DATA_WIDTH - 1 : 0]  s_axis_cc_tdata,
    output wire [KEEP_WIDTH - 1 : 0]    s_axis_cc_tkeep,
    output wire            s_axis_cc_tlast,
    input wire [3 : 0]    s_axis_cc_tready,
    output wire [CC_USER_WIDTH - 1 : 0]   s_axis_cc_tuser,
    output wire            s_axis_cc_tvalid,

    output wire [3 : 0] cfg_interrupt_int,
    output wire [3 : 0] cfg_interrupt_pending,
    input  wire         cfg_interrupt_sent,

    input wire [3 : 0]      cfg_interrupt_msi_enable,
    input wire [11 : 0]     cfg_interrupt_msi_mmenable,
    input wire              cfg_interrupt_msi_mask_update,
    input wire [31 : 0]     cfg_interrupt_msi_data,
    output wire [1 : 0]      cfg_interrupt_msi_select,
    output wire [31 : 0]     cfg_interrupt_msi_int,
    output wire [31 : 0]     cfg_interrupt_msi_pending_status,
    output wire              cfg_interrupt_msi_pending_status_data_enable,
    output wire [1 : 0]      cfg_interrupt_msi_pending_status_function_num,
    input wire              cfg_interrupt_msi_sent,
    input wire              cfg_interrupt_msi_fail,
    output wire [2 : 0]      cfg_interrupt_msi_attr,
    output wire              cfg_interrupt_msi_tph_present,
    output wire [1 : 0]      cfg_interrupt_msi_tph_type,
    output wire [7 : 0]      cfg_interrupt_msi_tph_st_tag,
    output wire [7 : 0]      cfg_interrupt_msi_function_number,

    input wire [3 : 0]      cfg_interrupt_msix_enable,
    input wire [3 : 0]      cfg_interrupt_msix_mask,
    input wire [251 : 0]    cfg_interrupt_msix_vf_enable,
    input wire [251 : 0]    cfg_interrupt_msix_vf_mask,
    output reg [31 : 0]     cfg_interrupt_msix_data,
    output reg [63 : 0]     cfg_interrupt_msix_address,
    output reg              cfg_interrupt_msix_int,
    output reg [1 : 0]      cfg_interrupt_msix_vec_pending,
    input wire [0 : 0]      cfg_interrupt_msix_vec_pending_status,


    output positive_process_indicator,
    output negative_process_indicator
    
);


    wire [1:0] dma_watchdog[3:0];
    wire [1:0] dma_watchdog_ack[3:0];

    wire [127:0] ram_ctl_dout[3:0];
    wire [63:0]  ram_ctl_addr[3:0];
    wire [127:0] ram_ctl_din[3:0];
    wire [15:0]  ram_ctl_we[3:0];

    wire [127:0] ram_mem_dout[3:0];
    wire [63:0]  ram_mem_addr[3:0];
    wire [127:0] ram_mem_din[3:0];
    wire [15:0]  ram_mem_we[3:0];

    wire              irq_valid;
    wire [3 : 0]      irq_func;
    wire [63 : 0]     irq_addr;
    wire [31 : 0]     irq_data;
    wire              irq_ready;

    positive_process # (
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH),
        .RQ_USER_WIDTH(RQ_USER_WIDTH),
        .RC_USER_WIDTH(RC_USER_WIDTH)
    ) positive_process_inst (
        .clk(clk),
        .rst(rst),

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

        .ram_ctl_dout(ram_ctl_dout),
        .ram_ctl_addr(ram_ctl_addr),
        .ram_ctl_din(ram_ctl_din),
        .ram_ctl_we(ram_ctl_we),

        .ram_mem_dout(ram_mem_dout),
        .ram_mem_addr(ram_mem_addr),
        .ram_mem_din(ram_mem_din),
        .ram_mem_we(ram_mem_we),

        .dma_watchdog(dma_watchdog),
        .dma_watchdog_ack(dma_watchdog_ack),

        .irq_valid(irq_valid),
        .irq_func(irq_func),
        .irq_addr(irq_addr),
        .irq_data(irq_data),
        .irq_ready(irq_ready),

        .indicator(positive_process_indicator)

    );
    
    negative_process # (
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH),
        .CQ_USER_WIDTH(CQ_USER_WIDTH),
        .CC_USER_WIDTH(CC_USER_WIDTH)
    ) negative_process_inst (
        .clk(clk),
        .rst(rst),

        .m_axis_cq_tdata(m_axis_cq_tdata),
        .m_axis_cq_tkeep(m_axis_cq_tkeep),
        .m_axis_cq_tlast(m_axis_cq_tlast),
        .m_axis_cq_tready(m_axis_cq_tready),
        .m_axis_cq_tuser(m_axis_cq_tuser),
        .m_axis_cq_tvalid(m_axis_cq_tvalid),

        .s_axis_cc_tdata(s_axis_cc_tdata),
        .s_axis_cc_tkeep(s_axis_cc_tkeep),
        .s_axis_cc_tlast(s_axis_cc_tlast),
        .s_axis_cc_tready(s_axis_cc_tready),
        .s_axis_cc_tuser(s_axis_cc_tuser),
        .s_axis_cc_tvalid(s_axis_cc_tvalid),

        .ram_ctl_dout(ram_ctl_dout),
        .ram_ctl_addr(ram_ctl_addr),
        .ram_ctl_din(ram_ctl_din),
        .ram_ctl_we(ram_ctl_we),

        .ram_mem_dout(ram_mem_dout),
        .ram_mem_addr(ram_mem_addr),
        .ram_mem_din(ram_mem_din),
        .ram_mem_we(ram_mem_we),

        .dma_watchdog(dma_watchdog),
        .dma_watchdog_ack(dma_watchdog_ack),

        .indicator(negative_process_indicator)

    );


    irq_proc irq_proc_inst(
        .clk(clk),
        .rst(rst),

        .irq_valid(irq_valid),
        .irq_func(irq_func),
        .irq_addr(irq_addr),
        .irq_data(irq_data),
        .irq_ready(irq_ready),

        .cfg_interrupt_int(cfg_interrupt_int),
        .cfg_interrupt_pending(cfg_interrupt_pending),
        .cfg_interrupt_sent(cfg_interrupt_sent),

        .cfg_interrupt_msi_enable(cfg_interrupt_msi_enable),
        .cfg_interrupt_msi_mmenable(cfg_interrupt_msi_mmenable),
        .cfg_interrupt_msi_mask_update(cfg_interrupt_msi_mask_update),
        .cfg_interrupt_msi_data(cfg_interrupt_msi_data),
        .cfg_interrupt_msi_select(cfg_interrupt_msi_select),
        .cfg_interrupt_msi_int(cfg_interrupt_msi_int),
        .cfg_interrupt_msi_pending_status(cfg_interrupt_msi_pending_status),
        .cfg_interrupt_msi_pending_status_data_enable(cfg_interrupt_msi_pending_status_data_enable),
        .cfg_interrupt_msi_pending_status_function_num(cfg_interrupt_msi_pending_status_function_num),
        .cfg_interrupt_msi_sent(cfg_interrupt_msi_sent),
        .cfg_interrupt_msi_fail(cfg_interrupt_msi_fail),
        .cfg_interrupt_msi_attr(cfg_interrupt_msi_attr),
        .cfg_interrupt_msi_tph_present(cfg_interrupt_msi_tph_present),
        .cfg_interrupt_msi_tph_type(cfg_interrupt_msi_tph_type),
        .cfg_interrupt_msi_tph_st_tag(cfg_interrupt_msi_tph_st_tag),
        .cfg_interrupt_msi_function_number(cfg_interrupt_msi_function_number),

        .cfg_interrupt_msix_enable(cfg_interrupt_msix_enable),
        .cfg_interrupt_msix_mask(cfg_interrupt_msix_mask),
        .cfg_interrupt_msix_vf_enable(cfg_interrupt_msix_vf_enable),
        .cfg_interrupt_msix_vf_mask(cfg_interrupt_msix_vf_mask),
        .cfg_interrupt_msix_data(cfg_interrupt_msix_data),
        .cfg_interrupt_msix_address(cfg_interrupt_msix_address),
        .cfg_interrupt_msix_int(cfg_interrupt_msix_int),
        .cfg_interrupt_msix_vec_pending(cfg_interrupt_msix_vec_pending),
        .cfg_interrupt_msix_vec_pending_status(cfg_interrupt_msix_vec_pending_status)
    );

endmodule
