`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: wjh776a68
// 
// Create Date: 09/27/2023 04:45:35 PM
// Design Name: 
// Module Name: irq_proc
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


module irq_proc #(
    parameter LEGACY_INTERRUPT_KEEP_CYCLE = 32 - 1
)(
    input clk,
    input rst,

    
    (* MARK_DEBUG="true" *) input                   irq_valid,
    (* MARK_DEBUG="true" *) input      [3 : 0]      irq_func,
    (* MARK_DEBUG="true" *) input      [63 : 0]     irq_addr, 
    (* MARK_DEBUG="true" *) input      [31 : 0]     irq_data,
    (* MARK_DEBUG="true" *) output reg              irq_ready,

    (* MARK_DEBUG="true" *) output reg  [3 : 0]     cfg_interrupt_int,
    (* MARK_DEBUG="true" *) output reg  [3 : 0]     cfg_interrupt_pending,
    (* MARK_DEBUG="true" *) input  wire             cfg_interrupt_sent,

    input wire [3 : 0]      cfg_interrupt_msi_enable,
    input wire [11 : 0]     cfg_interrupt_msi_mmenable,                     
    input wire              cfg_interrupt_msi_mask_update,
    input wire [31 : 0]     cfg_interrupt_msi_data,
    output reg [1 : 0]      cfg_interrupt_msi_select,
    (* MARK_DEBUG="true" *) output reg [31 : 0]     cfg_interrupt_msi_int,
    output reg [31 : 0]     cfg_interrupt_msi_pending_status,
    output reg              cfg_interrupt_msi_pending_status_data_enable,
    output reg [1 : 0]      cfg_interrupt_msi_pending_status_function_num,
    input wire              cfg_interrupt_msi_sent,
    input wire              cfg_interrupt_msi_fail,
    output reg [2 : 0]      cfg_interrupt_msi_attr,
    output reg              cfg_interrupt_msi_tph_present,
    output reg [1 : 0]      cfg_interrupt_msi_tph_type,
    output reg [7 : 0]      cfg_interrupt_msi_tph_st_tag,
    output reg [7 : 0]      cfg_interrupt_msi_function_number,

    (* MARK_DEBUG="true" *) input wire [3 : 0]      cfg_interrupt_msix_enable,
    (* MARK_DEBUG="true" *) input wire [3 : 0]      cfg_interrupt_msix_mask,
    (* MARK_DEBUG="true" *) input wire [251 : 0]    cfg_interrupt_msix_vf_enable,
    (* MARK_DEBUG="true" *) input wire [251 : 0]    cfg_interrupt_msix_vf_mask,
    (* MARK_DEBUG="true" *) output reg [31 : 0]     cfg_interrupt_msix_data,
    (* MARK_DEBUG="true" *) output reg [63 : 0]     cfg_interrupt_msix_address,
    (* MARK_DEBUG="true" *) output reg              cfg_interrupt_msix_int,
    (* MARK_DEBUG="true" *) output reg [1 : 0]      cfg_interrupt_msix_vec_pending,
    (* MARK_DEBUG="true" *) input wire [0 : 0]      cfg_interrupt_msix_vec_pending_status
);

    function logic [1:0] onehot2bin(input logic [3:0] func);
        case (func[3:0])
        4'b0001: return 2'b00;
        4'b0010: return 2'b01;
        4'b0100: return 2'b10;
        4'b1000: return 2'b11;
        endcase
    endfunction

    initial begin
        irq_ready = 'd0;

        cfg_interrupt_int = 'd0;
        cfg_interrupt_pending = 'd0;

        cfg_interrupt_msi_select = 'd0;
        cfg_interrupt_msi_int = 'd0;
        cfg_interrupt_msi_pending_status = 'd0;
        cfg_interrupt_msi_pending_status_data_enable = 'd0;
        cfg_interrupt_msi_pending_status_function_num = 'd0;
        cfg_interrupt_msi_attr = 'd0;
        cfg_interrupt_msi_tph_present = 'd0;
        cfg_interrupt_msi_tph_type = 'd0;
        cfg_interrupt_msi_tph_st_tag = 'd0;
        cfg_interrupt_msi_function_number = 'd0;

        cfg_interrupt_msix_data = 'd0;
        cfg_interrupt_msix_address = 'd0;
        cfg_interrupt_msix_int = 'd0;
        cfg_interrupt_msix_vec_pending = 'd0;
    end

    (* MARK_DEBUG="true" *) enum logic [4:0] {
        RESET,
        IDLE,
        SEND_LEGACY_INTR,
        WAIT_LEGACY_INTR,
        SEND_MSI_INTR,
        WAIT_MSI_INTR,
        SEND_MSIX_INTR,
        WAIT_MSIX_INTR
    } fsm_r, fsm_s;

    always @(posedge clk) begin
        if (rst) begin
            fsm_r <= RESET;
        end else begin
            fsm_r <= fsm_s;
        end
    end

    always @(*) begin
        case (fsm_r)
        RESET: begin
            if (rst) begin
                fsm_s = RESET;
            end else begin
                fsm_s = IDLE;
            end
        end
        IDLE: begin
            if (irq_valid & irq_ready) begin
                if (|(irq_func & cfg_interrupt_msi_enable)) begin
                    fsm_s = SEND_MSI_INTR;
                end else if (|(irq_func & cfg_interrupt_msix_enable)) begin
                    fsm_s = SEND_MSIX_INTR;
                end else if (|(irq_func)) begin

                    fsm_s = SEND_LEGACY_INTR;
                end else begin
                    fsm_s = IDLE;
                end
            end else begin
                fsm_s = IDLE;
            end
        end
        SEND_LEGACY_INTR: begin
            if (cfg_interrupt_sent) begin 
                fsm_s = WAIT_LEGACY_INTR;
            end else begin
                fsm_s=  SEND_LEGACY_INTR;
            end
        end
        WAIT_LEGACY_INTR: begin
            if (cfg_interrupt_sent) begin 
                fsm_s = IDLE;
            end else begin
                fsm_s = WAIT_LEGACY_INTR;
            end
        end
        SEND_MSI_INTR: begin
            fsm_s = WAIT_MSI_INTR;
        end
        WAIT_MSI_INTR: begin
            if (cfg_interrupt_msi_sent | cfg_interrupt_msi_fail) begin 
                fsm_s = IDLE;
            end else begin
                fsm_s = WAIT_MSI_INTR;
            end
        end
        SEND_MSIX_INTR: begin
            fsm_s= WAIT_MSIX_INTR;
        end
        WAIT_MSIX_INTR: begin
            if (cfg_interrupt_msi_sent | cfg_interrupt_msi_fail) begin 
                fsm_s = IDLE;
            end else begin
                fsm_s = WAIT_MSIX_INTR;
            end
        end
        endcase
    end

    logic [5:0] legacy_intr_hold_cnt_r;

    always @(posedge clk) begin
        case (fsm_s)
        WAIT_LEGACY_INTR: begin
            if (legacy_intr_hold_cnt_r != LEGACY_INTERRUPT_KEEP_CYCLE) begin
                legacy_intr_hold_cnt_r <= legacy_intr_hold_cnt_r + 'd1;
            end
        end
        default: begin
            legacy_intr_hold_cnt_r <= 'd0;
        end
        endcase
    end

    always @(posedge clk) begin
        case (fsm_s)
        SEND_LEGACY_INTR: begin
            if (irq_valid & irq_ready) begin 
                cfg_interrupt_int <= (irq_func);
                cfg_interrupt_pending <= (irq_func);
            end
        end
        WAIT_LEGACY_INTR: begin
            if (legacy_intr_hold_cnt_r == LEGACY_INTERRUPT_KEEP_CYCLE) begin 
                cfg_interrupt_int <= 4'b0;
                cfg_interrupt_pending <= 4'b0;
            end
        end
        default: begin
            cfg_interrupt_int <= 4'b0;
            cfg_interrupt_pending <= 4'b0;
        end
        endcase
    end

    always @(posedge clk) begin
        case (fsm_s)
        SEND_MSI_INTR: begin
            cfg_interrupt_msi_int  <= 32'h00000001; 
            cfg_interrupt_msi_function_number <= {6'h0, onehot2bin(irq_func[3:0])}; 
            cfg_interrupt_msi_select <= onehot2bin(irq_func[3:0]); 
            cfg_interrupt_msi_pending_status_data_enable <= 1'b1;
            cfg_interrupt_msi_pending_status <= 32'h00000001;
            cfg_interrupt_msi_pending_status_function_num <= onehot2bin(irq_func[3:0]);
        end
        WAIT_MSI_INTR: begin
            cfg_interrupt_msi_int  <= 32'h00000000;
        end
        SEND_MSIX_INTR: begin
            cfg_interrupt_msix_int  <= 1'b1; 
            cfg_interrupt_msi_function_number <= {6'h0, onehot2bin(irq_func[3:0])}; 
            cfg_interrupt_msix_address <= irq_addr;
            cfg_interrupt_msix_data <= irq_data; 
        end
        WAIT_MSIX_INTR: begin

        end
        default: begin
            cfg_interrupt_msi_attr <= 3'b000;
            cfg_interrupt_msi_tph_st_tag <= 8'h00;
            cfg_interrupt_msi_tph_type <= 2'b00;
            cfg_interrupt_msi_tph_present <= 1'b0;
            cfg_interrupt_msi_int  <= 32'h00000000; 
            cfg_interrupt_msi_function_number <= 8'h00; 
            cfg_interrupt_msi_select <= 2'b00; 
            cfg_interrupt_msi_pending_status_data_enable <= 1'b0;
            cfg_interrupt_msi_pending_status <= 32'h00000000;
            cfg_interrupt_msi_pending_status_function_num <= 8'h00;

            cfg_interrupt_msix_int  <= 1'b0;
            
            cfg_interrupt_msix_address <= 64'h0000000000000000;
            cfg_interrupt_msix_data <= 32'h00000000;
            cfg_interrupt_msix_vec_pending <= 2'b00;
        end
        endcase
    end

    always @(*) begin
        case (fsm_r)
        IDLE: irq_ready = 1;
        default: irq_ready = 0;
        endcase
    end


endmodule
