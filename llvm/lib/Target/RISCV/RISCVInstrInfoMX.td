include "RISCVInstrFormatsMX.td"


def MTypeIAsmOperand : AsmOperandClass {
  let Name = "MTypeI";
  let ParserMethod = "parseMTypeI";
  let DiagnosticType = "InvalidMTypeI";
  let RenderMethod = "addVTypeIOperands";
}

def MTypeIOp : Operand<XLenVT> {
  let ParserMatchClass = MTypeIAsmOperand;
  let PrintMethod = "printVTypeI";
  let DecoderMethod = "decodeUImmOperand<11>";
}

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in {
// load td, (rs1), rs2
class MatrixTRLoad<bits<6> funct6, bits<3> width, string opcodestr>
    : RVInstML<funct6, width,
                (outs TRR:$td),
                (ins GPR:$rs1, GPR:$rs2), opcodestr,
                "$td, (${rs1}), $rs2">;

// load td, (rs1), rs2
class MatrixVLoad<bits<6> funct6, RISCVWidth width, string opcodestr>
    : RVInstML<funct6, width.Value{2-0},
                (outs VR:$td),
                (ins GPR:$rs1, GPR:$rs2), opcodestr,
                "$td, (${rs1}), $rs2">;

// load td, (rs1), rs2
class MatrixACCLoad<bits<6> funct6, bits<3> width, string opcodestr>
    : RVInstML<funct6, width,
                (outs ACCR:$accd),
                (ins GPR:$rs1, GPR:$rs2), opcodestr,
                "$accd, (${rs1}), $rs2">;
} // hasSideEffects = 0, mayLoad = 1, mayStore = 0



let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in {
// store vd, ts3, (rs1), rs2
class MatrixTRStore<bits<6> funct6, bits<3> width, string opcodestr>
    : RVInstMS<funct6, width, (outs),
                (ins TRR:$ts3, GPR:$rs1, GPR:$rs2),
                opcodestr, "$ts3, (${rs1}), $rs2">;

// store vd, ts3, (rs1), rs2
class MatrixVStore<bits<6> funct6, RISCVWidth width, string opcodestr>
    : RVInstMS<funct6, width.Value{2-0}, (outs),
                (ins VR:$ts3, GPR:$rs1, GPR:$rs2),
                opcodestr, "$ts3, (${rs1}), $rs2">;

// store vd, ts3, (rs1), rs2
class MatrixACCStore<bits<6> funct6, bits<3> width, string opcodestr>
    : RVInstMS<funct6, width, (outs),
                (ins ACCR:$acc3, GPR:$rs1, GPR:$rs2),
                opcodestr, "$acc3, (${rs1}), $rs2">;
} // hasSideEffects = 0, mayLoad = 0, mayStore = 1


let hasSideEffects = 1, mayLoad = 0, mayStore = 0 in {

def MSETMTI : RVInstSetMType<(outs GPR:$rd), (ins GPR:$rs1, MTypeIOp:$mtypei),
                         "OA_msetmti", "$rd, $rs1, $mtypei">;

def MSETMTM : RVInstSetTile<0b0011, (outs GPR:$rd), (ins GPR:$rs1),
                         "OA_msettilem", "$rd, $rs1">;
def MSETMTK : RVInstSetTile<0b0101, (outs GPR:$rd), (ins GPR:$rs1),
                         "OA_msettilek", "$rd, $rs1">;
def MSETMTN : RVInstSetTile<0b0111, (outs GPR:$rd), (ins GPR:$rs1),
                         "OA_msettilen", "$rd, $rs1">;
def MSETTSIDX : RVInstSetTile<0b1001, (outs GPR:$rd), (ins GPR:$rs1),
                         "OA_msettsidx", "$rd, $rs1">;
} // hasSideEffects = 1, mayLoad = 0, mayStore = 0

foreach eew = [8, 16, 32, 64] in {
  defvar w = !cast<RISCVWidth>("LSWidth" # eew);

  // Matrix Unit-Stride Instructions
  def MLE#eew#_A_M : MatrixVLoad<0x9, w, "OA_mle"#eew#".v.a">, VLESched<eew>;
  def MLE#eew#_B_M : MatrixVLoad<0xa, w, "OA_mle"#eew#".v.b">, VLESched<eew>;
  def MLE#eew#_C_M : MatrixVLoad<0x0, w, "OA_mle"#eew#".v.c">, VLESched<eew>;
  def MSE#eew#_A_M : MatrixVStore<0x9, w,  "OA_mse"#eew#".v.a">, VSESched<eew>;
  def MSE#eew#_B_M : MatrixVStore<0xa, w,  "OA_mse"#eew#".v.b">, VSESched<eew>;
  def MSE#eew#_C_M : MatrixVStore<0x0, w,  "OA_mse"#eew#".v.c">, VSESched<eew>;

}