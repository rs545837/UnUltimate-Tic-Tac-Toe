`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/29/2023 03:48:33 PM
// Design Name:
// Module Name: counter
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module counter
    #(BITS = 20)
    (
    input clk,
    input rst,

    output [BITS - 1 : 0] q
    );
     
    // counter register
    reg [BITS - 1 : 0] rCounter;
     
    // increment or reset the counter
    always @(posedge clk, posedge rst)
        if (rst)
            rCounter <= 0;
        else
            rCounter <= rCounter + 1;
 
    // connect counter register to the output wires
    assign q = rCounter;

         
endmodule