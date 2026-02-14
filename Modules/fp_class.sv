module fp_class #(
    parameter int PRECISION = 16,
    parameter int SIN_LEN = 1,
    parameter int EXP_LEN = 
        (PRECISION == 16) ? 5:
        (PRECISION == 32) ? 8:
        (PRECISION == 64) ? 11: 0,
    parameter int MAN_LEN = 
        (PRECISION == 16) ? 10:
        (PRECISION == 32) ? 23:
        (PRECISION == 64) ? 52: 0,
    parameter int BUF_MAN_LEN = 1 + MAN_LEN,
    parameter int BUF_EXP_LEN = 2 + EXP_LEN, 
    parameter int BIAS = (1 << (EXP_LEN - 1)) - 1
    )(
    input logic signed [PRECISION - 1 : 0] f,    
    
    output logic fSign,
    output logic signed [BUF_EXP_LEN - 1 : 0] fExp,
    output logic unsigned [BUF_MAN_LEN - 1 : 0] fMan,
    output logic SNaN,    
    output logic QNaN,    
    output logic Infinity,
    output logic Zero,
    output logic Subnormal,
    output logic Normal
    );

    initial 
    begin
        if (!(PRECISION == 16 || PRECISION == 32 || PRECISION == 64))
        begin
            $fatal(1, "Invalid Precision: %0d. Supported 16, 32, 64", PRECISION);
        end
    end

    logic [BUF_MAN_LEN - 1 : 0] mask = '1;
    logic expZeros;  
    logic expOnes;   
    logic sigZeros; 

    assign expOnes  =  & f[PRECISION - 1 - SIN_LEN : MAN_LEN]; 
    assign expZeros = ~| f[PRECISION - 1 - SIN_LEN : MAN_LEN];
    assign sigZeros = ~| f[MAN_LEN - 1 : 0];

    assign fSign     = f[PRECISION - 1];

    assign SNaN      = expOnes  & ~sigZeros & ~f[MAN_LEN - 1];
    assign QNaN      = expOnes  &  f[MAN_LEN - 1];
    assign Infinity  = expOnes  &  sigZeros;
    assign Zero      = expZeros &  sigZeros;
    assign Subnormal = expZeros & ~sigZeros;
    assign Normal    = ~expOnes & ~expZeros;

    always @(*)
    begin
        fExp = f[PRECISION - 1 - SIN_LEN : MAN_LEN];
        fMan = f[MAN_LEN - 1 : 0];
        if (Normal)
        begin
            fExp = f[PRECISION - 1 - SIN_LEN : MAN_LEN] - BIAS;
            fMan[BUF_MAN_LEN - 1] = 1'b1;
        end
        else if (Subnormal)
        begin
            fExp = 1 - BIAS;
            fMan[BUF_MAN_LEN - 1] = 1'b0;
            for (integer i = 1 << ($clog2(BUF_MAN_LEN) - 1); i > 0; i = i >> 1)
            begin               
                if ((fMan & (mask << (BUF_MAN_LEN - i))) == 0)
                begin
                    fMan = fMan << i;
                    fExp = fExp - i;
                end
            end
        end
    end
endmodule