`timescale 1ns / 1ps

`define GND_BUS(width) {width{1'b0}}
module MAC #(
        parameter DATA_WIDTH = 32
    )
    (
        input  wire                                     clk, sclr, cen,                                   
        input  wire                                     load, res_err,
        input  wire                                     mac_init,
        input  wire signed [DATA_WIDTH - 1 : 0]      op1,
        input  wire signed [DATA_WIDTH - 1 : 0]      op2,

        output reg  signed [DATA_WIDTH - 1 : 0]     out_res,
        output wire                                     acc_ovr
    );

    localparam ACC_WIDTH = 2 * DATA_WIDTH;
    
    reg [ACC_WIDTH-1 : 0] acc;
    reg [DATA_WIDTH-1:0] qres, qerr;
    reg [ACC_WIDTH-1:0] ma_out, C;
    assign C = acc[ACC_WIDTH-1:0];
    assign acc_ovr = ^acc[ACC_WIDTH-1:ACC_WIDTH-2];
    wire ma_en = cen & !load & !mac_init;

    multadd #(
        .DATA_WIDTH(32),
        .ACC_WIDTH(64)
    ) ma_core (
        .CLK        (clk       ),       // input wire CLK
        .CE         (ma_en     ),       // input wire CE
        .SCLR       (sclr      ),       // input wire SCLR
        .A          (op1       ),       // input wire [31 : 0] A
        .B          (op2       ),       // input wire [31 : 0] B
        .C          (C        ),       // input wire [31 : 0] C
        .P          (ma_out   )        // output wire [64 : 0] P
    );

    
    always @(posedge clk)
    begin
        if (sclr) begin
            {acc, qres, qerr} <= `GND_BUS(ACC_WIDTH + DATA_WIDTH + DATA_WIDTH);
        end if (cen) begin
            if (mac_init)
            begin
                acc <= {{DATA_WIDTH{1'b0}},op2};
            end
            else if (load)
            begin
                qres <= ma_out[ACC_WIDTH - 1 -: DATA_WIDTH];
                qerr <= (ma_out[DATA_WIDTH-1:0] >> 1);
            end
            else
            begin
                acc <= ma_out;
            end
        end
    end

    assign out_res = (res_err)? qres : qerr;   
endmodule

module multadd #(
    parameter DATA_WIDTH = 31,
              ACC_WIDTH = 65
) (
    input  wire                          CLK,
    input  wire                          CE,
    input  wire                          SCLR,
    input  wire [DATA_WIDTH - 1 : 0]  A,
    input  wire [DATA_WIDTH - 1 : 0]  B,
    input  wire [ACC_WIDTH - 1 : 0] C,
    output wire [ACC_WIDTH - 1 : 0] P
);
    reg [DATA_WIDTH - 1 : 0] da, db;
    reg [ACC_WIDTH - 1 : 0] dmult, dsum, dc;

    always @(posedge CLK) begin
        if (SCLR) begin
            da    <= `GND_BUS(DATA_WIDTH);
            db    <= `GND_BUS(DATA_WIDTH);
            dmult <= `GND_BUS(ACC_WIDTH);
            dsum  <= `GND_BUS(ACC_WIDTH);
            dc    <= `GND_BUS(ACC_WIDTH);
        end if (CE) begin
            da    <= A;
            db    <= B;
            dmult <= da * db;
            dc    <= C;
            dsum  <= dmult + dc;
        end
    end

    assign P = dsum;
endmodule