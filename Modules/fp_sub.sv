module fp_sum #(
    parameter int PRECISION = 16
)(
    input logic [PRECISION - 1 : 0] a, 
    input logic [PRECISION - 1 : 0] b, 
    
    output logic [PRECISION - 1 : 0] sum,
    output logic sSNaN,     
    output logic sQNaN,    
    output logic sInfinity,
    output logic sZero,
    output logic sSubnormal,
    output logic sNormal
    //output logic ////sException,
    //output logic //sRoundOff
    );
    assign b[PRECISION - 1] = ~b[PRECISION - 1];
    fp_add #(.PRECISION(PRECISION)) inst_sub(a, b, sum, sSNaN, sQNaN, sInfinity, sZero, sSubnormal, sNormal /*, sException, sRoundOff*/); 

endmodule
