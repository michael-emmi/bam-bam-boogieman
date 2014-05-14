// BEGIN SMACK-GENERATED CODE

// Memory region declarations: 7
var $M.0: [int] int;
var $M.1: [int] int;
var $M.2: [int] int;
var $M.3: [int] int;
var $M.4: [int] int;
var $M.5: [int] int;
var $M.6: [int] int;

// Undefined values
const $u.0, $u.1, $u.2, $u.3: int;

axiom $GLOBALS_BOTTOM == -4824;
const unique .str: int;
const unique .str1: int;
const unique .str10: int;
const unique .str100: int;
const unique .str101: int;
const unique .str102: int;
const unique .str103: int;
const unique .str104: int;
const unique .str105: int;
const unique .str106: int;
const unique .str107: int;
const unique .str108: int;
const unique .str109: int;
const unique .str11: int;
const unique .str12: int;
const unique .str13: int;
const unique .str14: int;
const unique .str15: int;
const unique .str16: int;
const unique .str17: int;
const unique .str18: int;
const unique .str19: int;
const unique .str2: int;
const unique .str20: int;
const unique .str21: int;
const unique .str22: int;
const unique .str23: int;
const unique .str24: int;
const unique .str25: int;
const unique .str26: int;
const unique .str27: int;
const unique .str28: int;
const unique .str29: int;
const unique .str3: int;
const unique .str30: int;
const unique .str31: int;
const unique .str32: int;
const unique .str33: int;
const unique .str34: int;
const unique .str35: int;
const unique .str36: int;
const unique .str37: int;
const unique .str38: int;
const unique .str39: int;
const unique .str4: int;
const unique .str40: int;
const unique .str41: int;
const unique .str42: int;
const unique .str43: int;
const unique .str44: int;
const unique .str45: int;
const unique .str46: int;
const unique .str47: int;
const unique .str48: int;
const unique .str49: int;
const unique .str5: int;
const unique .str50: int;
const unique .str51: int;
const unique .str52: int;
const unique .str53: int;
const unique .str54: int;
const unique .str55: int;
const unique .str56: int;
const unique .str57: int;
const unique .str58: int;
const unique .str59: int;
const unique .str6: int;
const unique .str60: int;
const unique .str61: int;
const unique .str62: int;
const unique .str63: int;
const unique .str64: int;
const unique .str65: int;
const unique .str66: int;
const unique .str67: int;
const unique .str68: int;
const unique .str69: int;
const unique .str7: int;
const unique .str70: int;
const unique .str71: int;
const unique .str72: int;
const unique .str73: int;
const unique .str74: int;
const unique .str75: int;
const unique .str76: int;
const unique .str77: int;
const unique .str78: int;
const unique .str79: int;
const unique .str8: int;
const unique .str80: int;
const unique .str81: int;
const unique .str82: int;
const unique .str83: int;
const unique .str84: int;
const unique .str85: int;
const unique .str86: int;
const unique .str87: int;
const unique .str88: int;
const unique .str89: int;
const unique .str9: int;
const unique .str90: int;
const unique .str91: int;
const unique .str92: int;
const unique .str93: int;
const unique .str94: int;
const unique .str95: int;
const unique .str96: int;
const unique .str97: int;
const unique .str98: int;
const unique .str99: int;
const unique EMPTY: int;
const unique FinishCollision: int;
const unique GetPosition: int;
const unique Init: int;
const unique LesOP: int;
const unique Pop: int;
const unique Push: int;
const unique S: int;
const unique StackOp: int;
const unique TryCollision: int;
const unique TryPerformStackOp: int;
const unique __SMACK_assert: int;
const unique __SMACK_assume: int;
const unique __SMACK_decls: int;
const unique __SMACK_nondet: int;
const unique __SMACK_nondet.XXX: int;
const unique c_cas: int;
const {:count 4} unique collision: int;
const unique delay: int;
const unique int_cas: int;
const {:count 14} unique location: int;
const unique main: int;
const unique malloc: int;
const unique ti_cas: int;
const unique unique_id: int;
procedure $static_init()
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  $M.1[__SMACK_nondet.XXX] := 0;
  $M.2[$pa(EMPTY, 0, 1)] := 0;
  $M.2[$pa(EMPTY, 8, 1)] := -1;
  $M.2[$pa($pa(EMPTY, 12, 1), 0, 1)] := $u.0;
  $M.2[$pa($pa(EMPTY, 12, 1), 1, 1)] := $u.1;
  $M.2[$pa($pa(EMPTY, 12, 1), 2, 1)] := $u.2;
  $M.2[$pa($pa(EMPTY, 12, 1), 3, 1)] := $u.3;
  $M.3[$pa(S, 0, 1)] := 0;
  $M.4[unique_id] := 0;
  $M.5[$pa(location, 0, 8)] := 0;
  $M.5[$pa(location, 1, 8)] := 0;
  $M.5[$pa(location, 2, 8)] := 0;
  $M.5[$pa(location, 3, 8)] := 0;
  $M.5[$pa(location, 4, 8)] := 0;
  $M.5[$pa(location, 5, 8)] := 0;
  $M.5[$pa(location, 6, 8)] := 0;
  $M.5[$pa(location, 7, 8)] := 0;
  $M.5[$pa(location, 8, 8)] := 0;
  $M.5[$pa(location, 9, 8)] := 0;
  $M.5[$pa(location, 10, 8)] := 0;
  $M.5[$pa(location, 11, 8)] := 0;
  $M.5[$pa(location, 12, 8)] := 0;
  $M.5[$pa(location, 13, 8)] := 0;
  $M.6[$pa(collision, 0, 4)] := 0;
  $M.6[$pa(collision, 1, 4)] := 0;
  $M.6[$pa(collision, 2, 4)] := 0;
  $M.6[$pa(collision, 3, 4)] := 0;
  return;
}
procedure FinishCollision(p: int)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var $b: bool;
  var $p: int;
  var $p1: int;
  var $p10: int;
  var $p11: int;
  var $p12: int;
  var $p13: int;
  var $p14: int;
  var $p2: int;
  var $p3: int;
  var $p4: int;
  var $p5: int;
  var $p6: int;
  var $p7: int;
  var $p8: int;
  var $p9: int;
$bb0:
  $p := $pa($pa(p, 0, 32), 0, 1);
  $p1 := $M.0[$p];
  $p2 := $pa($pa(p, 0, 32), 4, 1);
  $p3 := $M.0[$p2];
  $p4 := $p3;
  $b := ($p4 == 0);
  goto $bb3, $bb4;
$bb1:
  $p5 := $p1;
  $p6 := $pa($pa(location, 0, 112), $p5, 8);
  $p7 := $M.5[$p6];
  $p8 := $pa($pa($p7, 0, 32), 8, 1);
  $p9 := $pa($pa($p8, 0, 16), 8, 1);
  $p10 := $M.0[$p9];
  $p11 := $pa($pa(p, 0, 32), 8, 1);
  $p12 := $pa($pa($p11, 0, 16), 8, 1);
  $M.0[$p12] := $p10;
  $p13 := $p1;
  $p14 := $pa($pa(location, 0, 112), $p13, 8);
  $M.5[$p14] := 0;
  goto $bb2;
$bb2:
  return;
$bb3:
  assume $b;
  goto $bb1;
$bb4:
  assume !($b);
  goto $bb2;
}
procedure GetPosition(p: int)
  returns ($r: int)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var $b: bool;
  var $b1: bool;
  var $b2: bool;
  var $p: int;
$bb0:
  call $p := __SMACK_nondet();
  $b := $sle(0, $p);
  $b1 := false;
  goto $bb3, $bb4;
$bb1:
  $b2 := $slt($p, 4);
  $b1 := $b2;
  goto $bb2;
$bb2:
  call __SMACK_assume($b1);
  $r := $p;
  return;
$bb3:
  assume $b;
  goto $bb1;
$bb4:
  assume !($b);
  goto $bb2;
}
procedure Init()
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
$bb0:
  return;
}
procedure LesOP(p: int)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var $b: bool;
  var $b11: bool;
  var $b12: bool;
  var $b17: bool;
  var $b21: bool;
  var $b24: bool;
  var $b31: bool;
  var $b32: bool;
  var $b35: bool;
  var $b36: bool;
  var $b38: bool;
  var $b39: bool;
  var $b41: bool;
  var $b42: bool;
  var $p: int;
  var $p1: int;
  var $p10: int;
  var $p13: int;
  var $p14: int;
  var $p15: int;
  var $p16: int;
  var $p18: int;
  var $p19: int;
  var $p2: int;
  var $p20: int;
  var $p22: int;
  var $p23: int;
  var $p25: int;
  var $p26: int;
  var $p27: int;
  var $p28: int;
  var $p29: int;
  var $p3: int;
  var $p30: int;
  var $p33: int;
  var $p34: int;
  var $p37: int;
  var $p4: int;
  var $p40: int;
  var $p43: int;
  var $p44: int;
  var $p45: int;
  var $p5: int;
  var $p6: int;
  var $p7: int;
  var $p8: int;
  var $p9: int;
$bb0:
  $p := $pa($pa(p, 0, 32), 0, 1);
  $p1 := $M.0[$p];
  goto $bb1;
$bb1:
  $p2 := $p1;
  $p3 := $pa($pa(location, 0, 112), $p2, 8);
  $M.5[$p3] := p;
  call $p4 := GetPosition(p);
  $p5 := $p4;
  $p6 := $pa($pa(collision, 0, 16), $p5, 4);
  $p7 := $M.6[$p6];
  $p8 := $p7;
  goto $bb2;
$bb2:
  $p9 := $p4;
  $p10 := $pa($pa(collision, 0, 16), $p9, 4);
  call $b := int_cas($p10, $p8, $p1);
  $b11 := $i2b($xor($b2i($b), $b2i(true)));
  goto $bb5, $bb6;
$bb3:
  $p43 := $p4;
  $p44 := $pa($pa(collision, 0, 16), $p43, 4);
  $p45 := $M.6[$p44];
  $p8 := $p45;
  goto $bb2;
$bb4:
  $b12 := $sgt($p8, 0);
  goto $bb9, $bb10;
$bb5:
  assume $b11;
  goto $bb3;
$bb6:
  assume !($b11);
  goto $bb4;
$bb7:
  $p18 := $p8;
  $p19 := $pa($pa(location, 0, 112), $p18, 8);
  $p20 := $M.5[$p19];
  $b21 := ($p20 != 0);
  goto $bb18, $bb19;
$bb8:
  $p13 := $pa($pa(p, 0, 32), 24, 1);
  $p14 := $M.0[$p13];
  call delay($p14);
  assume {:yield} true;
  $p15 := $p1;
  $p16 := $pa($pa(location, 0, 112), $p15, 8);
  call $b17 := ti_cas($p16, p, 0);
  goto $bb13, $bb14;
$bb9:
  assume $b12;
  goto $bb7;
$bb10:
  assume !($b12);
  goto $bb8;
$bb11:
  goto $bb1;
$bb12:
  call FinishCollision(p);
  goto $bb15;
$bb13:
  assume $b17;
  goto $bb11;
$bb14:
  assume !($b17);
  goto $bb12;
$bb15:
  return;
$bb16:
  $p22 := $pa($pa($p20, 0, 32), 0, 1);
  $p23 := $M.0[$p22];
  $b24 := ($p23 == $p8);
  goto $bb21, $bb22;
$bb17:
  goto $bb8;
$bb18:
  assume $b21;
  goto $bb16;
$bb19:
  assume !($b21);
  goto $bb17;
$bb20:
  $p25 := $pa($pa($p20, 0, 32), 4, 1);
  $p26 := $M.0[$p25];
  $p27 := $p26;
  $p28 := $pa($pa(p, 0, 32), 4, 1);
  $p29 := $M.0[$p28];
  $p30 := $p29;
  $b31 := ($p27 != $p30);
  goto $bb24, $bb25;
$bb21:
  assume $b24;
  goto $bb20;
$bb22:
  assume !($b24);
  goto $bb17;
$bb23:
  $b32 := ($p1 == 5);
  goto $bb28, $bb29;
$bb24:
  assume $b31;
  goto $bb23;
$bb25:
  assume !($b31);
  goto $bb17;
$bb26:
  $b42 := ($p8 == 4);
  goto $bb43, $bb44;
$bb27:
  assume {:yield} true;
  $p33 := $p1;
  $p34 := $pa($pa(location, 0, 112), $p33, 8);
  call $b35 := ti_cas($p34, p, 0);
  goto $bb32, $bb33;
$bb28:
  assume $b32;
  goto $bb26;
$bb29:
  assume !($b32);
  goto $bb27;
$bb30:
  call $b36 := TryCollision(p, $p20, $p8);
  $p37 := $b2p($b36);
  $b38 := ($p37 == 1);
  goto $bb36, $bb37;
$bb31:
  call FinishCollision(p);
  goto $bb15;
$bb32:
  assume $b35;
  goto $bb30;
$bb33:
  assume !($b35);
  goto $bb31;
$bb34:
  goto $bb15;
$bb35:
  goto $bb38;
$bb36:
  assume $b38;
  goto $bb34;
$bb37:
  assume !($b38);
  goto $bb35;
$bb38:
  call $b39 := TryPerformStackOp(p);
  $p40 := $b2p($b39);
  $b41 := ($p40 == 1);
  goto $bb40, $bb41;
$bb39:
  goto $bb15;
$bb40:
  assume $b41;
  goto $bb39;
$bb41:
  assume !($b41);
  goto $bb15;
$bb42:
  assert false;
  goto $bb27;
$bb43:
  assume $b42;
  goto $bb42;
$bb44:
  assume !($b42);
  goto $bb27;
}
procedure Pop()
  returns ($r: int)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var $p: int;
  var $p1: int;
  var $p2: int;
  var $p3: int;
  var $p4: int;
  var $p5: int;
  var $p6: int;
  var $p7: int;
  var $p8: int;
  var $p9: int;
$bb0:
  assume {:yield} true;
  call $p := $malloc(32);
  $p1 := $p;
  $p2 := $M.4[unique_id];
  $p3 := $add($p2, 1);
  $M.4[unique_id] := $p3;
  $p4 := $pa($pa($p1, 0, 32), 0, 1);
  $M.0[$p4] := $p3;
  $p5 := $pa($pa($p1, 0, 32), 4, 1);
  $M.0[$p5] := 0;
  $p6 := $pa($pa($p1, 0, 32), 24, 1);
  $M.0[$p6] := 1;
  call StackOp($p1);
  $p7 := $pa($pa($p1, 0, 32), 8, 1);
  $p8 := $pa($pa($p7, 0, 16), 8, 1);
  $p9 := $M.0[$p8];
  $r := $p9;
  return;
}
procedure Push(x: int)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var $p: int;
  var $p1: int;
  var $p2: int;
  var $p3: int;
  var $p4: int;
  var $p5: int;
  var $p6: int;
  var $p7: int;
  var $p8: int;
$bb0:
  assume {:yield} true;
  call $p := $malloc(32);
  $p1 := $p;
  $p2 := $M.4[unique_id];
  $p3 := $add($p2, 1);
  $M.4[unique_id] := $p3;
  $p4 := $pa($pa($p1, 0, 32), 0, 1);
  $M.0[$p4] := $p3;
  $p5 := $pa($pa($p1, 0, 32), 4, 1);
  $M.0[$p5] := 1;
  $p6 := $pa($pa($p1, 0, 32), 8, 1);
  $p7 := $pa($pa($p6, 0, 16), 8, 1);
  $M.0[$p7] := x;
  $p8 := $pa($pa($p1, 0, 32), 24, 1);
  $M.0[$p8] := 1;
  call StackOp($p1);
  return;
}
procedure StackOp(p: int)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var $b: bool;
  var $b1: bool;
  var $p: int;
$bb0:
  call $b := TryPerformStackOp(p);
  $p := $b2p($b);
  $b1 := ($p == 0);
  goto $bb3, $bb4;
$bb1:
  call LesOP(p);
  goto $bb2;
$bb2:
  return;
$bb3:
  assume $b1;
  goto $bb1;
$bb4:
  assume !($b1);
  goto $bb2;
}
procedure TryCollision(p: int, q: int, him: int)
  returns ($r: bool)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var $b: bool;
  var $b12: bool;
  var $b22: bool;
  var $b8: bool;
  var $b9: bool;
  var $p: int;
  var $p1: int;
  var $p10: int;
  var $p11: int;
  var $p13: int;
  var $p14: int;
  var $p15: int;
  var $p16: int;
  var $p17: int;
  var $p18: int;
  var $p19: int;
  var $p2: int;
  var $p20: int;
  var $p21: int;
  var $p3: int;
  var $p4: int;
  var $p5: int;
  var $p6: int;
  var $p7: int;
$bb0:
  $p := $pa($pa(p, 0, 32), 0, 1);
  $p1 := $M.0[$p];
  $p2 := $pa($pa(p, 0, 32), 4, 1);
  $p3 := $M.0[$p2];
  $p4 := $p3;
  $b := ($p4 == 1);
  goto $bb3, $bb4;
$bb1:
  assume {:yield} true;
  $p20 := him;
  $p21 := $pa($pa(location, 0, 112), $p20, 8);
  call $b22 := ti_cas($p21, q, p);
  goto $bb16, $bb17;
$bb2:
  $p5 := $pa($pa(p, 0, 32), 4, 1);
  $p6 := $M.0[$p5];
  $p7 := $p6;
  $b8 := ($p7 == 0);
  goto $bb7, $bb8;
$bb3:
  assume $b;
  goto $bb1;
$bb4:
  assume !($b);
  goto $bb2;
$bb5:
  assume {:yield} true;
  $p10 := him;
  $p11 := $pa($pa(location, 0, 112), $p10, 8);
  call $b12 := ti_cas($p11, q, 0);
  goto $bb12, $bb13;
$bb6:
  $b9 := false;
  goto $bb9;
$bb7:
  assume $b8;
  goto $bb5;
$bb8:
  assume !($b8);
  goto $bb6;
$bb9:
  $r := $b9;
  return;
$bb10:
  $p13 := $pa($pa(q, 0, 32), 8, 1);
  $p14 := $pa($pa($p13, 0, 16), 8, 1);
  $p15 := $M.0[$p14];
  $p16 := $pa($pa(p, 0, 32), 8, 1);
  $p17 := $pa($pa($p16, 0, 16), 8, 1);
  $M.0[$p17] := $p15;
  $p18 := $p1;
  $p19 := $pa($pa(location, 0, 112), $p18, 8);
  $M.5[$p19] := 0;
  $b9 := true;
  goto $bb9;
$bb11:
  $b9 := false;
  goto $bb9;
$bb12:
  assume $b12;
  goto $bb10;
$bb13:
  assume !($b12);
  goto $bb11;
$bb14:
  $b9 := true;
  goto $bb9;
$bb15:
  $b9 := false;
  goto $bb9;
$bb16:
  assume $b22;
  goto $bb14;
$bb17:
  assume !($b22);
  goto $bb15;
}
procedure TryPerformStackOp(p: int)
  returns ($r: bool)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var $b: bool;
  var $b12: bool;
  var $b27: bool;
  var $b6: bool;
  var $b7: bool;
  var $b9: bool;
  var $p: int;
  var $p1: int;
  var $p10: int;
  var $p11: int;
  var $p13: int;
  var $p14: int;
  var $p15: int;
  var $p16: int;
  var $p17: int;
  var $p18: int;
  var $p19: int;
  var $p2: int;
  var $p20: int;
  var $p21: int;
  var $p22: int;
  var $p23: int;
  var $p24: int;
  var $p25: int;
  var $p26: int;
  var $p3: int;
  var $p4: int;
  var $p5: int;
  var $p8: int;
$bb0:
  $p := $pa($pa(p, 0, 32), 4, 1);
  $p1 := $M.0[$p];
  $p2 := $p1;
  $b := ($p2 == 1);
  goto $bb3, $bb4;
$bb1:
  $p23 := $M.3[$pa($pa(S, 0, 8), 0, 1)];
  $p24 := $pa($pa(p, 0, 32), 8, 1);
  $p25 := $pa($pa($p24, 0, 16), 0, 1);
  $M.0[$p25] := $p23;
  assume {:yield} true;
  $p26 := $pa($pa(p, 0, 32), 8, 1);
  call $b27 := c_cas($pa($pa(S, 0, 8), 0, 1), $p23, $p26);
  goto $bb20, $bb21;
$bb2:
  $p3 := $pa($pa(p, 0, 32), 4, 1);
  $p4 := $M.0[$p3];
  $p5 := $p4;
  $b6 := ($p5 == 0);
  goto $bb7, $bb8;
$bb3:
  assume $b;
  goto $bb1;
$bb4:
  assume !($b);
  goto $bb2;
$bb5:
  $p8 := $M.3[$pa($pa(S, 0, 8), 0, 1)];
  $b9 := ($p8 == 0);
  goto $bb12, $bb13;
$bb6:
  $b7 := false;
  goto $bb9;
$bb7:
  assume $b6;
  goto $bb5;
$bb8:
  assume !($b6);
  goto $bb6;
$bb9:
  $r := $b7;
  return;
$bb10:
  $p20 := $M.2[$pa($pa(EMPTY, 0, 16), 8, 1)];
  $p21 := $pa($pa(p, 0, 32), 8, 1);
  $p22 := $pa($pa($p21, 0, 16), 8, 1);
  $M.0[$p22] := $p20;
  $b7 := true;
  goto $bb9;
$bb11:
  $p10 := $pa($pa($p8, 0, 16), 0, 1);
  $p11 := $M.0[$p10];
  assume {:yield} true;
  call $b12 := c_cas($pa($pa(S, 0, 8), 0, 1), $p8, $p11);
  goto $bb16, $bb17;
$bb12:
  assume $b9;
  goto $bb10;
$bb13:
  assume !($b9);
  goto $bb11;
$bb14:
  $p16 := $pa($pa($p8, 0, 16), 8, 1);
  $p17 := $M.0[$p16];
  $p18 := $pa($pa(p, 0, 32), 8, 1);
  $p19 := $pa($pa($p18, 0, 16), 8, 1);
  $M.0[$p19] := $p17;
  $b7 := true;
  goto $bb9;
$bb15:
  $p13 := $M.2[$pa($pa(EMPTY, 0, 16), 8, 1)];
  $p14 := $pa($pa(p, 0, 32), 8, 1);
  $p15 := $pa($pa($p14, 0, 16), 8, 1);
  $M.0[$p15] := $p13;
  $b7 := false;
  goto $bb9;
$bb16:
  assume $b12;
  goto $bb14;
$bb17:
  assume !($b12);
  goto $bb15;
$bb18:
  $b7 := true;
  goto $bb9;
$bb19:
  $b7 := false;
  goto $bb9;
$bb20:
  assume $b27;
  goto $bb18;
$bb21:
  assume !($b27);
  goto $bb19;
}
procedure __SMACK_assert(v: bool)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var $b: bool;
  var $p: int;
  var $p1: int;
$bb0:
  $p := $b2p(v);
  $b := $i2b($p);
  $p1 := $b2p($b);
  assert $p1 != 0;
  return;
}
procedure __SMACK_assume(v: bool)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var $b: bool;
  var $p: int;
  var $p1: int;
$bb0:
  $p := $b2p(v);
  $b := $i2b($p);
  $p1 := $b2p($b);
  assume $p1 != 0;
  return;
}
procedure __SMACK_nondet()
  returns ($r: int)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var $p: int;
$bb0:
  $p := $M.1[__SMACK_nondet.XXX];
  havoc $p;
  $r := $p;
  return;
}
procedure c_cas(p: int, cmp: int, new: int)
  returns ($r: bool)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var $b: bool;
  var $b1: bool;
  var $p: int;
$bb0:
  $p := $M.3[p];
  $b := ($p == cmp);
  goto $bb3, $bb4;
$bb1:
  $M.3[p] := new;
  $b1 := true;
  goto $bb5;
$bb2:
  $b1 := false;
  goto $bb5;
$bb3:
  assume $b;
  goto $bb1;
$bb4:
  assume !($b);
  goto $bb2;
$bb5:
  $r := $b1;
  return;
}
procedure delay(p#0: int);
procedure int_cas(p: int, cmp: int, new: int)
  returns ($r: bool)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var $b: bool;
  var $b1: bool;
  var $p: int;
$bb0:
  $p := $M.6[p];
  $b := ($p == cmp);
  goto $bb3, $bb4;
$bb1:
  $M.6[p] := new;
  $b1 := true;
  goto $bb5;
$bb2:
  $b1 := false;
  goto $bb5;
$bb3:
  assume $b;
  goto $bb1;
$bb4:
  assume !($b);
  goto $bb2;
$bb5:
  $r := $b1;
  return;
}
procedure main()
  returns ($r: int)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var x: int;
$bb0:
  call $static_init();
  call Init();
  call {:async} Push(1);
  call {:async} Push(1);
  call {:async} Push(1);
  call {:async} x := Pop();
  call {:async} Push(1);
  call {:async} x := Pop();
  assume {:yield} true;
  $r := 0;
  return;
}
procedure ti_cas(p: int, cmp: int, new: int)
  returns ($r: bool)
  modifies $Alloc, $CurrAddr, $M.0, $M.1, $M.2, $M.3, $M.4, $M.5, $M.6;
{
  var $b: bool;
  var $b1: bool;
  var $p: int;
$bb0:
  $p := $M.5[p];
  $b := ($p == cmp);
  goto $bb3, $bb4;
$bb1:
  $M.5[p] := new;
  $b1 := true;
  goto $bb5;
$bb2:
  $b1 := false;
  goto $bb5;
$bb3:
  assume $b;
  goto $bb1;
$bb4:
  assume !($b);
  goto $bb2;
$bb5:
  $r := $b1;
  return;
}
axiom (__SMACK_nondet.XXX == -38);
axiom (EMPTY == -4592);
axiom (S == -4600);
axiom (unique_id == -4604);
axiom (location == -4716);
axiom (collision == -4732);
axiom $NULL == 0;
axiom $and(0,0) == 0;
axiom $and(0,1) == 0;
axiom $and(1,0) == 0;
axiom $and(1,1) == 1;
axiom $b2i(false) == 0;
axiom $b2i(true) == 1;
axiom $b2p(false) == 0;
axiom $b2p(true) == 1;
axiom $i2b(0) == false;
axiom $or(0,0) == 0;
axiom $or(0,1) == 1;
axiom $or(1,0) == 1;
axiom $or(1,1) == 1;
axiom $p2b(0) == false;
axiom $xor(0,0) == 0;
axiom $xor(0,1) == 1;
axiom $xor(1,0) == 1;
axiom $xor(1,1) == 0;
axiom (forall i:int :: $i2b(i) <==> i != 0);
axiom (forall i:int :: $i2p(i) == i);
axiom (forall i:int :: $p2b(i) <==> i != 0);
axiom (forall i:int :: $p2i(i) == i);
axiom (forall p,s:int :: $trunc(p,s) == p);
axiom (forall p:int, i:int, s:int :: {$pa(p,i,s)} $pa(p,i,s) == p + i * s);
const $GLOBALS_BOTTOM: int;
const $MOP: $mop;
const $UNDEF: int;
const $ffalse: float;
const $ftrue: float;
const unique $NULL: int;
function $add(p1:int, p2:int) returns (int) {p1 + p2}
function $and(p1:int, p2:int) returns (int);
function $ashr(p1:int, p2:int) returns (int);
function $b2i(b: bool) returns (int);
function $b2p(b: bool) returns (int);
function $fadd(f1:float, f2:float) returns (float);
function $fdiv(f1:float, f2:float) returns (float);
function $fmul(f1:float, f2:float) returns (float);
function $foeq(f1:float, f2:float) returns (bool);
function $foge(f1:float, f2:float) returns (bool);
function $fogt(f1:float, f2:float) returns (bool);
function $fole(f1:float, f2:float) returns (bool);
function $folt(f1:float, f2:float) returns (bool);
function $fone(f1:float, f2:float) returns (bool);
function $ford(f1:float, f2:float) returns (bool);
function $fp(a:int) returns (float);
function $fp2si(f:float) returns (int);
function $fp2ui(f:float) returns (int);
function $frem(f1:float, f2:float) returns (float);
function $fsub(f1:float, f2:float) returns (float);
function $fueq(f1:float, f2:float) returns (bool);
function $fuge(f1:float, f2:float) returns (bool);
function $fugt(f1:float, f2:float) returns (bool);
function $fule(f1:float, f2:float) returns (bool);
function $fult(f1:float, f2:float) returns (bool);
function $fune(f1:float, f2:float) returns (bool);
function $funo(f1:float, f2:float) returns (bool);
function $i2b(i: int) returns (bool);
function $i2p(p: int) returns (int);
function $isExternal(p: int) returns (bool) { p < $GLOBALS_BOTTOM - 32768 }
function $lshr(p1:int, p2:int) returns (int);
function $max(p1:int, p2:int) returns (int);
function $min(p1:int, p2:int) returns (int);
function $mul(p1:int, p2:int) returns (int) {p1 * p2}
function $nand(p1:int, p2:int) returns (int);
function $obj(int) returns (int);
function $off(ptr:int) returns (int) {ptr}
function $or(p1:int, p2:int) returns (int);
function $p2b(p: int) returns (bool);
function $p2i(p: int) returns (int);
function $pa(pointer: int, index: int, size: int) returns (int);
function $ptr(obj:int, off:int) returns (int) {obj + off}
function $sdiv(p1:int, p2:int) returns (int);
function $sge(p1:int, p2:int) returns (bool) {p1 >= p2}
function $sgt(p1:int, p2:int) returns (bool) {p1 > p2}
function $shl(p1:int, p2:int) returns (int);
function $si2fp(i:int) returns (float);
function $sle(p1:int, p2:int) returns (bool) {p1 <= p2}
function $slt(p1:int, p2:int) returns (bool) {p1 < p2}
function $srem(p1:int, p2:int) returns (int);
function $sub(p1:int, p2:int) returns (int) {p1 - p2}
function $trunc(p: int, size: int) returns (int);
function $udiv(p1:int, p2:int) returns (int);
function $uge(p1:int, p2:int) returns (bool) {p1 >= p2}
function $ugt(p1:int, p2:int) returns (bool) {p1 > p2}
function $ui2fp(i:int) returns (float);
function $ule(p1:int, p2:int) returns (bool) {p1 <= p2}
function $ult(p1:int, p2:int) returns (bool) {p1 < p2}
function $umax(p1:int, p2:int) returns (int);
function $umin(p1:int, p2:int) returns (int);
function $urem(p1:int, p2:int) returns (int);
function $xor(p1:int, p2:int) returns (int);
procedure $alloca(n: int) returns (p: int)
modifies $CurrAddr, $Alloc;
{
  assume $CurrAddr > 0;
  p := $CurrAddr;
  if (n > 0) {
    $CurrAddr := $CurrAddr + n;
  } else {
    $CurrAddr := $CurrAddr + 1;
  }
  $Alloc[p] := true;
}
procedure $free(p: int)
modifies $Alloc;
{
  $Alloc[p] := false;
}
procedure $malloc(n: int) returns (p: int)
modifies $CurrAddr, $Alloc;
{
  assume $CurrAddr > 0;
  p := $CurrAddr;
  if (n > 0) {
    $CurrAddr := $CurrAddr + n;
  } else {
    $CurrAddr := $CurrAddr + 1;
  }
  $Alloc[p] := true;
}
procedure boogie_si_record_int(i: int);
procedure boogie_si_record_mop(m: $mop);
type $mop;
type float;
var $Alloc: [int] bool;
var $CurrAddr:int;

// END SMACK-GENERATED CODE
// @c2s-options --unroll 1
// @c2s-options --rounds 3
// @c2s-expected Got a trace
