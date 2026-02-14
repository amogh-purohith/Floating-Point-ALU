module fp_roundoff #(
    parameter PRECISION
    parameter MAN_LEN
    parameter BUF_MAN_LEN
)(
    logic unsigned input [BUF_MAN_LEN : 0] fMan,
    logic signed input [BUF_EXP_LEN - 1 : 0] fExp,
    logic unsigned output [MAN_LEN - 1 : 0] tempMan,
    logic unsigned output [EXP_LEN - 1 : 0] tempExp
)

localparam int MSBIndex = BUF_MAN_LEN - MAN_LEN - 1;
localparam int EVEN_MAN_LEN = ~(MAN_LEN % 2);

logic [MAN_LEN + 1 : 0] rMan = '0;
logic roundMSB = [MSBIndex] fMan;
logic roundLSB = | fMan[MSBIndex - 1: 0];

always @(*)
begin
    tempExp = fExp + BIAS; // REMOVE IF NOT REQUIRED
    if (roundMSB && (~EVEN_MAN_LEN || (EVEN_MAN_LEN && roundLSB)))
    begin ////// rounding is done whether there will be shift or not should be done
        rMan = fMan[BUF_MAN_LEN : BUF_MAN_LEN - MAN_LEN] + 1; ////////////////// round off done here
        ///// check msb and shoft right if it is one and increment the temp exp
        if (rMan[MAN_LEN + 1] == 1'b1)
        begin
            tempExp = tempExp + 1;
            rMan = rMAn >> 1;
            fExp = fExp + 1;
            tempMan = [MAN_LEN : 1]rMan;
            ///////////////// start checking cases
            if (fExp > BIAS)
            begin
                sInfinity = 1'b1;
                {sZero, sSubnormal, sNormal} = 3'b000;
                tempExp = '1;
                tempMan = '0;
                sException = 1'b1;
            end
            else if (fExp <= 0 && fExp >= (BIAS + MAN_LEN - 1))
            begin

            end
        end
        else if (~rMan[MAN_LEN + 2] && rMan[MAN_LEN + 1])
        begin
            tempMan = [MAN_LEN - 1 : 0] rMan
        end
    end
    else
    begin
        tempMan = fMan[BUF_MAN_LEN : BUF_MAN_LEN - MAN_LEN + 1];
    end
end
endmodule