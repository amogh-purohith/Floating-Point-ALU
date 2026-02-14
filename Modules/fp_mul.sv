module fp_mul #(
    parameter int PRECISION = 16
)(
    input logic [PRECISION - 1 : 0] a,
    input logic [PRECISION - 1 : 0] b,

    output logic [PRECISION - 1 : 0]p,
    output logic pSNaN,    
    output logic pQNaN,   
    output logic pInfinity,
    output logic pZero,
    output logic pSubnormal,
    output logic pNormal 
);
    localparam int SIN_LEN = 1;
    localparam int EXP_LEN = 
        (PRECISION == 16) ? 5:
        (PRECISION == 32) ? 8:
        (PRECISION == 64) ? 11: 0;
    localparam int MAN_LEN = 
        (PRECISION == 16) ? 10:
        (PRECISION == 32) ? 23:
        (PRECISION == 64) ? 52: 0;
    localparam int BUF_MAN_LEN = (2 * (1 + MAN_LEN));
    localparam int BUF_EXP_LEN = EXP_LEN + 2;
    localparam int BIAS = (1 << (EXP_LEN - 1)) - 1;

    logic signed [BUF_EXP_LEN - 1 : 0]  pExp = '0;
    logic [BUF_MAN_LEN - 1 : 0]         pMan = '0; 
    logic [BUF_MAN_LEN - 1 : 0]         tempMan = '0; // temporary variable
    logic [EXP_LEN - 1 : 0]             tempExp = '0;
    logic [BUF_EXP_LEN - 1 : 0]         aExp, bExp;
    logic [MAN_LEN : 0]                 aMan, bMan;
    logic pSign;
    logic aSign, aSNaN, aQNaN, aInfinity, aZero, aSubnormal, aNormal;
    logic bSign, bSNaN, bQNaN, bInfinity, bZero, bSubnormal, bNormal;

    fp_class #(.PRECISION(PRECISION)) inst_a(a, aSign, aExp, aMan, aSNaN, aQNaN, aInfinity, aZero, aSubnormal, aNormal);
    fp_class #(.PRECISION(PRECISION)) inst_b(b, bSign, bExp, bMan, bSNaN, bQNaN, bInfinity, bZero, bSubnormal, bNormal);

always@(*) 
begin

    {pSNaN, pQNaN, pInfinity, pZero, pSubnormal, pNormal} = 6'b000000;

    pSign = aSign ^ bSign;
    p = {pSign, {EXP_LEN{1'b1}}, 1'b0, {(MAN_LEN - 1){1'b1}}}; 
    
    if (aSNaN || bSNaN) 
    begin                
        p = aSNaN == 1'b1 ? a : b;
        pSNaN = 1;
    end
    else if (aQNaN || bQNaN) 
    begin           
        p = aQNaN == 1'b1 ? a : b;
        pQNaN = 1;
    end
    else if (aInfinity || bInfinity)
    begin 
        pQNaN = aZero || bZero;
        pInfinity = ~pQNaN;
        p = {pSign, {EXP_LEN{1'b1}}, pQNaN, {(MAN_LEN - 1){1'b0}}};
    end
    else if (aZero || bZero) begin 
        pZero = 1'b1;
        p = {pSign, {EXP_LEN{1'b0}}, {(MAN_LEN){1'b0}}};
    end
    else if ((aNormal || bNormal) || (aSubnormal || bSubnormal))
    begin
        
        pExp = aExp + bExp; 
        pMan = aMan * bMan; 
        if (pMan[BUF_MAN_LEN - 1])
        begin
             pExp = pExp + 1;
        end
        else if (~pMan[BUF_MAN_LEN - 1] && pMan[BUF_MAN_LEN - 2])
        begin
            pMan = pMan << 1;
        end 
        if (pExp > BIAS) 
        begin
            pInfinity = 1'b1;
            {pSNaN, pQNaN, pZero, pSubnormal, pNormal} = 5'b00000;
            p = {pSign, {EXP_LEN{1'b1}}, {MAN_LEN{1'b0}}};
        end
        else if (pExp < -(BIAS + MAN_LEN - 1)) 
        begin
            pZero = 1'b1;
            {pSNaN, pQNaN, pInfinity, pSubnormal, pNormal} = 5'b00000;
            p = {pSign, {EXP_LEN{1'b0}}, {(MAN_LEN){1'b0}}};
        end 
        else if((pExp <= BIAS) && (pExp >= -(BIAS - 1))) 
        begin 
            pNormal = 1'b1;
            {pSNaN, pQNaN, pInfinity, pZero, pSubnormal} = 5'b00000;
            tempExp = pExp + BIAS;
            p = {pSign, tempExp, pMan[BUF_MAN_LEN - 2 : BUF_MAN_LEN - MAN_LEN - 1]};
        end
        else if ((pExp < -(BIAS - 1)) && (pExp >= -(BIAS + MAN_LEN - 1))) 
        begin
            pSubnormal = 1'b1;
            {pSNaN, pQNaN, pInfinity, pZero, pNormal} = 5'b00000;
            tempMan = pMan >> -(pExp + BIAS - 1);
            p = {pSign, {EXP_LEN{1'b0}}, tempMan[BUF_MAN_LEN - 1 : BUF_MAN_LEN - MAN_LEN]}; 
        end
    end
end
endmodule
