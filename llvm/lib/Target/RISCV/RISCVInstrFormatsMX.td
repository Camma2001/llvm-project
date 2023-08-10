class RISCVMFormat<bits<6> val> {
  bits<6> Value = val;
}

class RVInstSetMTypei<dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatI> {
  bits<5> rd;
  bits<13> mtypei;

  let Inst{31-28} = 0b0000;
  let Inst{27-15} = mtypei;
  let Inst{14-12} = 0b111;
  let Inst{11-7} = rd;
  let Opcode = OPC_OP_M.Value;

  let Defs = [MTYPE];
}

class RVInstSetMType<dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatI> {
  bits<5> rs1;
  bits<5> rd;

  let Inst{31-28} = 0b0001;
  let Inst{27-20} = 0;
  let Inst{19-15} = rs1;
  let Inst{14-12} = 0b111;
  let Inst{11-7} = rd;
  let Opcode = OPC_OP_M.Value;

  let Defs = [MTYPE];
}

class RVInstSetTilei<bits<4> mit, dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatI> {
  bits<5> rd;
  bits<13> mleni;

  let Inst{31-28} = mit;
  let Inst{27-15} = mleni;
  let Inst{14-12} = 0b111;
  let Inst{11-7} = rd;
  let Opcode = OPC_OP_M.Value;

  let Defs = [TILEM];
}

class RVInstSetTile<bits<4> mit, dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatI> {
  bits<5> rs1;
  bits<5> rd;

  let Inst{31-28} = mit;
  let Inst{27-20} = 0;
  let Inst{19-15} = rs1;
  let Inst{14-12} = 0b111;
  let Inst{11-7} = rd;
  let Opcode = OPC_OP_M.Value;

  let Defs = [TILEM];
}

class RVInstSetConvi<bits<2> mit, dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatI> {
  bits<5> rd;
  bits<5> rs1;
  bits<8> mconvi;

  let Inst{31} = 1;
  let Inst{30-29} = mit;
  let Inst{28} = 0;
  let Inst{27-20} = mconvi;
  let Inst{19-15} = rs1;
  let Inst{14-12} = 0b111;
  let Inst{11-7} = rd;
  let Opcode = OPC_OP_M.Value;

  let Defs = [TILEM];
}

class RVInstSetConv<bits<2> mit, dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatI> {
  bits<5> rd;
  bits<5> rs1;
  bits<5> rs2;

  let Inst{31} = 1;
  let Inst{30-29} = mit;
  let Inst{28} = 1;
  let Inst{27-25} = 0b000;
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = 0b111;
  let Inst{11-7} = rd;
  let Opcode = OPC_OP_M.Value;

  let Defs = [TILEM];
}

class RVInstML<bits<6> funct6, bits<3> width,
                dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> rs2;
  bits<5> rs1;
  bits<5> td;

  let Inst{31-26} = funct6;
  let Inst{25} = 0;
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = width;
  let Inst{11-7} = td;
  let Opcode = OPC_OP_M.Value;

  let Uses = [MTYPE, TILEM, TILEK, TILEN];
}

class RVInstMS<bits<6> funct6, bits<3> width,
                dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> rs2;
  bits<5> rs1;
  bits<5> ts3;

  let Inst{31-26} = funct6;
  let Inst{25} = 1; // store
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = width;
  let Inst{11-7} = ts3;
  let Opcode = OPC_OP_M.Value;

  let Uses = [MTYPE, TILEM, TILEK, TILEN];
}

class RVInstMM<bits<6> funct6, bit fp, dag outs, dag ins,
               string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> ts2;
  bits<5> ts1;
  bits<5> accd;

  let Inst{31-26} = funct6;
  let Inst{25} = fp;
  let Inst{24-20} = ts2;
  let Inst{19-15} = ts1;
  let Inst{14-12} = 0b110;
  let Inst{11-7} = accd;
  let Opcode = OPC_OP_M.Value;

  let Uses = [MTYPE, TILEM, TILEK, TILEN];
}

class RVInstADDSUB<bits<6> funct6, bit fp, dag outs, dag ins,
               string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> acc1;
  bits<5> accd;

  let Inst{31-26} = funct6;
  let Inst{25} = fp;
  let Inst{24-20} = 0;
  let Inst{19-15} = acc1;
  let Inst{14-12} = 0b110;
  let Inst{11-7} = accd;
  let Opcode = OPC_OP_M.Value;

  let Uses = [MTYPE, TILEM, TILEK, TILEN];
}


class RVInstMEMULMX<bits<6> funct6, bit fp, dag outs, dag ins,
               string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> acc1;
  bits<5> accd;
  bits<5> rs2;

  let Inst{31-26} = funct6;
  let Inst{25} = fp;
  let Inst{24-20} = rs2;
  let Inst{19-15} = acc1;
  let Inst{14-12} = 0b110;
  let Inst{11-7} = accd;
  let Opcode = OPC_OP_M.Value;

  let Uses = [MTYPE, TILEM, TILEK, TILEN];
}

class RVInstMEMULMI<bits<6> funct6, dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatI> {
  bits<5> accd;
  bits<5> acc1;
  bits<5> mimm5;

  let Inst{31-26} = funct6;
  let Inst{25} = 0;
  let Inst{24-20} = mimm5;
  let Inst{19-15} = acc1;
  let Inst{14-12} = 0b110;
  let Inst{11-7} = accd;
  let Opcode = OPC_OP_M.Value;

  let Uses = [MTYPE, TILEM, TILEK, TILEN];
}

class RVInstMCVT<bits<6> funct6, bit fp, dag outs, dag ins,
               string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> acc1;
  bits<5> accd;

  let Inst{31-26} = funct6;
  let Inst{25} = fp;
  let Inst{24-20} = 0;
  let Inst{19-15} = acc1;
  let Inst{14-12} = 0b110;
  let Inst{11-7} = accd;
  let Opcode = OPC_OP_M.Value;

  let Uses = [MTYPE, TILEM, TILEK, TILEN];
}

class RVInstMCLR<bits<6> funct6, bit fp, dag outs, dag ins,
               string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> accd;

  let Inst{31-26} = funct6;
  let Inst{25} = fp;
  let Inst{24-20} = 0;
  let Inst{19-15} = 0;
  let Inst{14-12} = 0b110;
  let Inst{11-7} = accd;
  let Opcode = OPC_OP_M.Value;

  let Uses = [MTYPE, TILEM, TILEK, TILEN];
}


class RVInstMV_TR_IN<bits<2> widen, bits<2> tt, bits<2> dim, bits<1>fp,
                dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> rs2;
  bits<5> vs1;
  bits<5> td;

  let Inst{31-30} = widen; // 0-1widen, 1-2widen, 2-4widen
  let Inst{29-28} = tt;
  let Inst{27-26} = dim;
  let Inst{25} = fp; // fp
  let Inst{24-20} = rs2;
  let Inst{19-15} = vs1;
  let Inst{14-12} = 0b100; // mvin
  let Inst{11-7} = td;
  let Opcode = OPC_OP_M.Value;

  let Uses = [MTYPE, TILEM, TILEK, TILEN];
}

class RVInstMV_ACC_IN<bits<2> widen, bits<2> tt, bits<2> dim, bits<1>fp,
                dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> rs2;
  bits<5> vs1;
  bits<5> acc;

  let Inst{31-30} = widen;
  let Inst{29-28} = tt;
  let Inst{27-26} = dim;
  let Inst{25} = fp;
  let Inst{24-20} = rs2;
  let Inst{19-15} = vs1;
  let Inst{14-12} = 0b100;
  let Inst{11-7} = acc;
  let Opcode = OPC_OP_M.Value;

  let Uses = [MTYPE, TILEM, TILEK, TILEN];
}

class RVInstMV_TR_OUT<bits<2> widen, bits<2> tt, bits<2> dim, bits<1>fp,
                dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> rs2;
  bits<5> ts1;
  bits<5> vd;

  let Inst{31-30} = widen;
  let Inst{29-28} = tt;
  let Inst{27-26} = dim;
  let Inst{25} = fp;
  let Inst{24-20} = rs2;
  let Inst{19-15} = ts1;
  let Inst{14-12} = 0b101;
  let Inst{11-7} = vd;
  let Opcode = OPC_OP_M.Value;

  let Uses = [MTYPE, TILEM, TILEK, TILEN];
}

class RVInstMV_ACC_OUT<bits<2> widen, bits<2> tt, bits<2> dim, bits<1>fp,
                dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> rs2;
  bits<5> acc1;
  bits<5> vd;

  let Inst{31-30} = widen;
  let Inst{29-28} = tt;
  let Inst{27-26} = dim;
  let Inst{25} = fp;
  let Inst{24-20} = rs2;
  let Inst{19-15} = acc1;
  let Inst{14-12} = 0b101;
  let Inst{11-7} = vd;
  let Opcode = OPC_OP_M.Value;

  let Uses = [MTYPE, TILEM, TILEK, TILEN];
}
