# Automatically generated by parse_opcodes (noah95/riscv-opcodes)
# RUN: llvm-mc %s -triple=riscv64 -mattr=xfvecsingle,+d -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM %s

# CHECK-ASM: encoding: [0xb3,0x0a,0x76,0x83]
vfadd.s f21, f12, f23
# CHECK-ASM: encoding: [0x33,0x42,0x57,0x83]
vfadd.r.s f4, f14, f21
# CHECK-ASM: encoding: [0x33,0x8c,0x88,0x84]
vfsub.s f24, f17, f8
# CHECK-ASM: encoding: [0x33,0xce,0x08,0x85]
vfsub.r.s f28, f17, f16
# CHECK-ASM: encoding: [0xb3,0x0a,0x6d,0x86]
vfmul.s f21, f26, f6
# CHECK-ASM: encoding: [0xb3,0xc3,0xbf,0x86]
vfmul.r.s f7, f31, f11
# CHECK-ASM: encoding: [0xb3,0x8b,0x14,0x89]
vfdiv.s f23, f9, f17
# CHECK-ASM: encoding: [0x33,0xcc,0x3a,0x89]
vfdiv.r.s f24, f21, f19
# CHECK-ASM: encoding: [0xb3,0x0b,0x5b,0x8b]
vfmin.s f23, f22, f21
# CHECK-ASM: encoding: [0xb3,0x4e,0xb2,0x8a]
vfmin.r.s f29, f4, f11
# CHECK-ASM: encoding: [0xb3,0x8c,0x46,0x8d]
vfmax.s f25, f13, f20
# CHECK-ASM: encoding: [0xb3,0x4b,0x9b,0x8c]
vfmax.r.s f23, f22, f9
# CHECK-ASM: encoding: [0x33,0x89,0x0a,0x8e]
vfsqrt.s f18, f21
# CHECK-ASM: encoding: [0xb3,0x8a,0x2c,0x90]
vfmac.s f21, f25, f2
# CHECK-ASM: encoding: [0xb3,0x4a,0x62,0x90]
vfmac.r.s f21, f4, f6
# CHECK-ASM: encoding: [0x33,0x08,0xf5,0x93]
vfmre.s f16, f10, f31
# CHECK-ASM: encoding: [0xb3,0xc2,0xa9,0x92]
vfmre.r.s f5, f19, f10
# CHECK-ASM: encoding: [0x33,0x0e,0x17,0x98]
vfclass.s x28, f14
# CHECK-ASM: encoding: [0x33,0x09,0xe2,0x9a]
vfsgnj.s f18, f4, f14
# CHECK-ASM: encoding: [0x33,0x46,0x16,0x9b]
vfsgnj.r.s f12, f12, f17
# CHECK-ASM: encoding: [0xb3,0x83,0xb6,0x9c]
vfsgnjn.s f7, f13, f11
# CHECK-ASM: encoding: [0x33,0xcf,0xd9,0x9d]
vfsgnjn.r.s f30, f19, f29
# CHECK-ASM: encoding: [0x33,0x04,0x9f,0x9f]
vfsgnjx.s f8, f30, f25
# CHECK-ASM: encoding: [0x33,0xce,0x8e,0x9f]
vfsgnjx.r.s f28, f29, f24
# CHECK-ASM: encoding: [0xb3,0x8b,0xc8,0xa0]
vfeq.s x23, f17, f12
# CHECK-ASM: encoding: [0xb3,0xc7,0x5f,0xa1]
vfeq.r.s x15, f31, f21
# CHECK-ASM: encoding: [0x33,0x8b,0x3c,0xa3]
vfne.s x22, f25, f19
# CHECK-ASM: encoding: [0x33,0xc4,0x40,0xa2]
vfne.r.s x8, f1, f4
# CHECK-ASM: encoding: [0x33,0x09,0x2c,0xa5]
vflt.s x18, f24, f18
# CHECK-ASM: encoding: [0x33,0xcf,0xa4,0xa5]
vflt.r.s x30, f9, f26
# CHECK-ASM: encoding: [0x33,0x8a,0x05,0xa7]
vfge.s x20, f11, f16
# CHECK-ASM: encoding: [0xb3,0x4d,0x3d,0xa6]
vfge.r.s x27, f26, f3
# CHECK-ASM: encoding: [0xb3,0x84,0xc1,0xa9]
vfle.s x9, f3, f28
# CHECK-ASM: encoding: [0xb3,0xc3,0xf9,0xa8]
vfle.r.s x7, f19, f15
# CHECK-ASM: encoding: [0x33,0x85,0x76,0xaa]
vfgt.s x10, f13, f7
# CHECK-ASM: encoding: [0x33,0xcc,0x3f,0xab]
vfgt.r.s x24, f31, f19
# CHECK-ASM: encoding: [0xb3,0x02,0x06,0x98]
vfmv.x.s x5, f12
# CHECK-ASM: encoding: [0xb3,0x44,0x07,0x98]
vfmv.s.x f9, x14
# CHECK-ASM: encoding: [0x33,0x0c,0x28,0x98]
vfcvt.x.s x24, f16
# CHECK-ASM: encoding: [0xb3,0x4b,0x26,0x98]
vfcvt.xu.s x23, f12
# CHECK-ASM: encoding: [0x33,0x84,0x36,0x98]
vfcvt.s.x f8, x13
# CHECK-ASM: encoding: [0x33,0xc3,0x37,0x98]
vfcvt.s.xu f6, x15
# CHECK-ASM: encoding: [0x33,0x08,0xc1,0xb1]
vfcpka.s.s f16, f2, f28
# CHECK-ASM: encoding: [0x33,0xc3,0xbf,0xb0]
vfcpkb.s.s f6, f31, f11
# CHECK-ASM: encoding: [0xb3,0x81,0x3d,0xb3]
vfcpkc.s.s f3, f27, f19
# CHECK-ASM: encoding: [0xb3,0xc0,0x8f,0xb3]
vfcpkd.s.s f1, f31, f24
# CHECK-ASM: encoding: [0x33,0x8b,0x5c,0xb4]
vfcpka.s.d f22, f25, f5
# CHECK-ASM: encoding: [0x33,0xc2,0x9e,0xb5]
vfcpkb.s.d f4, f29, f25
# CHECK-ASM: encoding: [0x33,0x80,0xab,0xb7]
vfcpkc.s.d f0, f23, f26
# CHECK-ASM: encoding: [0xb3,0xc4,0x50,0xb7]
vfcpkd.s.d f9, f1, f21
# CHECK-ASM: encoding: [0x33,0xa2,0x58,0x98]
vfcvt.h.h f4, f17
# CHECK-ASM: encoding: [0xb3,0x29,0x57,0x98]
vfcvt.h.ah f19, f14
# CHECK-ASM: encoding: [0xb3,0x29,0x5d,0x98]
vfcvt.ah.h f19, f26
# CHECK-ASM: encoding: [0xb3,0xe8,0x5c,0x98]
vfcvtu.h.h f17, x25
# CHECK-ASM: encoding: [0xb3,0x62,0x51,0x98]
vfcvtu.h.ah f5, x2
# CHECK-ASM: encoding: [0x33,0xe9,0x5b,0x98]
vfcvtu.ah.h f18, x23
