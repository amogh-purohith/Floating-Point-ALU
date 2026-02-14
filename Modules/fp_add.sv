module fp_add #(
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
   // output logic ////sException,
    //output logic //sRoundOff
    );


    localparam int SIN_LEN = 1;
    localparam int EXP_LEN = (PRECISION == 16) ? 5: (PRECISION == 32) ? 8: (PRECISION == 64) ? 11: 0;
    localparam int MAN_LEN = (PRECISION == 16) ? 10: (PRECISION == 32) ? 23: (PRECISION == 64) ? 52: 0;
    localparam int BUF_MAN_LEN = (1 << EXP_LEN) + MAN_LEN;
    localparam int BUF_EXP_LEN = EXP_LEN + 2;
    localparam int BIAS = (1 << (EXP_LEN - 1)) - 1;

    logic sSign;
    logic signed [BUF_EXP_LEN - 1 : 0] sExp;
    logic unsigned [BUF_MAN_LEN : 0] sMan;
    logic unsigned [BUF_MAN_LEN - 1 : 0] aTempMan = '0;
    logic unsigned [BUF_MAN_LEN - 1 : 0] bTempMan = '0;


    logic [EXP_LEN - 1 : 0] sTempExp;
    logic [MAN_LEN: 0] sTempMan;

    logic unsigned [BUF_MAN_LEN : 0] mask = '1;

    logic signed [BUF_EXP_LEN - 1 : 0] aExp, bExp;
    logic unsigned [MAN_LEN : 0] aMan, bMan;
    logic aSign, aSNaN, aQNaN, aInfinity, aZero, aSubnormal, aNormal;
    logic bSign, bSNaN, bQNaN, bInfinity, bZero, bSubnormal, bNormal;

    fp_class #(.PRECISION(PRECISION)) inst_a(a, aSign, aExp, aMan, aSNaN, aQNaN, aInfinity, aZero, aSubnormal, aNormal);
    fp_class #(.PRECISION(PRECISION)) inst_b(b, bSign, bExp, bMan, bSNaN, bQNaN, bInfinity, bZero, bSubnormal, bNormal);

    always @(*)
    begin

        //sException = 1'b0;
        //sRoundOff = 1'b0;

        {sSNaN, sQNaN, sInfinity, sZero, sSubnormal, sNormal} = 6'b000000;

        aTempMan [BUF_MAN_LEN - 1 : BUF_MAN_LEN - MAN_LEN - 1] = aMan;
        bTempMan [BUF_MAN_LEN - 1 : BUF_MAN_LEN - MAN_LEN - 1] = bMan;
        aTempMan [BUF_MAN_LEN - MAN_LEN - 1 - 1 : 0] = '0;
        bTempMan [BUF_MAN_LEN - MAN_LEN - 1 - 1 : 0] = '0;

        if (aSNaN || bSNaN) 
        begin               
            sum = aSNaN == 1'b1 ? a : b;
            sSNaN = 1;
            {sQNaN, sInfinity, sZero, sSubnormal, sNormal} = 5'b00000;
        end
        else if (aQNaN || bQNaN) 
        begin
            sum = aQNaN == 1'b1 ? a : b;
            sQNaN = 1;
            {sSNaN, sInfinity, sZero, sSubnormal, sNormal} = 5'b00000;
        end
        else if (aInfinity || bInfinity)
        begin 
            if((aInfinity && bInfinity) && (aSign ^ bSign))
            begin
                sQNaN = 1'b1;
                {sSNaN, sInfinity, sZero, sSubnormal, sNormal} = 5'b00000;
                sum = {1'b1, {EXP_LEN{1'b1}}, sQNaN, {(MAN_LEN - 1){1'b0}}};
                //sException = 1'b1;
            end
            else
            begin
                sInfinity = 1'b1;
                {sSNaN, sQNaN, sZero, sSubnormal, sNormal} = 5'b00000;
                sum = {aSign, {EXP_LEN{1'b1}}, {(MAN_LEN){1'b0}}};
            end
        end
        else if (aZero || bZero)
        begin 
            if (aZero && bZero)
            begin
                sZero = 1'b1;
                {sSNaN, sQNaN, sInfinity, sSubnormal, sNormal} = 5'b00000;
                sum = {aSign & bSign, {EXP_LEN{1'b0}}, {(MAN_LEN){1'b0}}};
            end
            else
            begin
                sum = (bZero == 1'b1) ? a : b;
                {sZero, sSubnormal, sNormal} = (bZero == 1'b1) ? {aZero, aSubnormal, aNormal} : {bZero, bSubnormal, bNormal};
            end
        end
        else if(aSign ^ bSign == 1 && aExp == bExp && aMan == bMan)
        begin
            sZero = 1'b1;
            sum = {aSign & bSign, {EXP_LEN{1'b0}}, {(MAN_LEN){1'b0}}};
        end
        else if ((aSubnormal || bSubnormal) || (aNormal || bNormal))
        begin 
            if(aExp > bExp || (aExp == bExp && aMan > bMan) || a == b) 
            begin
                bTempMan = bTempMan >> (aExp - bExp);
                sSign = aSign;
                sExp = aExp;
                sMan = '0;
                sMan [BUF_MAN_LEN - 1: BUF_MAN_LEN - MAN_LEN - 1] = aMan;

                if (aSign ^ bSign == 1)
                begin
                    bTempMan = (~ bTempMan) + 1; 
                    sMan = sMan + bTempMan;
                    sMan = sMan << 1;
                end
                else if(aSign ^ bSign == 0)
                begin
                    sMan = sMan + bTempMan;
                    sExp = sMan[BUF_MAN_LEN] ? sExp + 1 : sExp;
                    sMan = (sMan[BUF_MAN_LEN] == 1'b0) ? sMan << 1 : sMan;
                end
            end
            else if (aExp < bExp || (aExp == bExp && aMan < bMan))
            begin
                aTempMan = aTempMan >> (bExp - aExp);
                sSign = bSign;
                sExp = bExp;
                sMan = '0;
                sMan [BUF_MAN_LEN - 1: BUF_MAN_LEN - MAN_LEN - 1] = bMan;

                if (aSign ^ bSign == 1)
                begin
                    aTempMan = (~ aTempMan) + 1; 
                    sMan = aTempMan + bTempMan;
                    sMan = sMan << 1;
                end
                else if(aSign ^ bSign == 0)
                begin
                    sMan = aTempMan + bTempMan;
                    sExp = sMan[BUF_MAN_LEN] ? sExp + 1 : sExp;
                    sMan = (sMan[BUF_MAN_LEN] == 1'b0) ? sMan << 1 : sMan;
                end
            end

            if(sMan != 0)
            begin
                for (integer j = 1 << ($clog2(BUF_MAN_LEN) - 1); j > 0; j = j >> 1)
                begin               
                    if ((sMan & (mask << (BUF_MAN_LEN + 1 - j))) == 0)
                    begin
                        sMan = sMan << j;
                        sExp = sExp - j;
                        
                    end
                end
            end

            sTempExp = sExp + BIAS;

            if (sExp > BIAS) 
            begin
                sInfinity = 1'b1;
                {sSNaN, sQNaN, sZero, sSubnormal, sNormal} = 5'b00000;
                sum = {sSign, {EXP_LEN{1'b1}}, {MAN_LEN{1'b0}}};
                //sException = 1'b1;
            end

            else if (sExp < -(BIAS + MAN_LEN - 1)) 
            begin
                sZero = 1'b1;
                {sSNaN, sQNaN, sInfinity, sSubnormal, sNormal} = 5'b00000;
                sum = {sSign, {EXP_LEN{1'b0}}, {(MAN_LEN){1'b0}}};
                //sException = 1'b1;
            end 
            else if((sExp <= BIAS) && (sExp >= -(BIAS - 1))) 
            begin 
                sNormal = 1'b1;
                {sSNaN, sQNaN, sInfinity, sZero, sSubnormal} = 5'b00000;
                sum = {sSign, sTempExp, sMan[BUF_MAN_LEN - 1 : BUF_MAN_LEN - MAN_LEN]};
            end
            else if ((sExp < -(BIAS - 1)) && (sExp >= -(BIAS + MAN_LEN - 1))) 
            begin
                sSubnormal = 1'b1;
                {sSNaN, sQNaN, sInfinity, sZero, sNormal} = 5'b00000;
                sTempMan = sMan >> -(sExp + BIAS - 1);
                sum = {sSign, {EXP_LEN{1'b0}}, sTempMan[MAN_LEN - 1 : 0]}; 
            end
        end
    end
endmodule