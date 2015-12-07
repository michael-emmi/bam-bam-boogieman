type i1 = int;
type i8 = int;
type i16 = int;
type i24 = int;
type i32 = int;
type i40 = int;
type i48 = int;
type i56 = int;
type i64 = int;
type i96 = int;
type i128 = int;
type ref = i64;
type float = i32;
const $0: i32;
axiom ($0 == 0);
const $1024.ref: ref;
axiom ($1024.ref == 1024);
var $M.0: [ref] i8;
axiom ($GLOBALS_BOTTOM == $sub.ref(0,180));
axiom ($EXTERNS_BOTTOM == $sub.ref(0,32768));
function {:inline} $ult.ref(p1: ref, p2: ref) returns (i1) { (if $ult.i64.bool(p1,p2) then 1 else 0) }
function {:inline} $slt.ref.bool(p1: ref, p2: ref) returns (bool) { $slt.i64.bool(p1,p2) }
function {:inline} $add.ref(p1: ref, p2: ref) returns (ref) { $add.i64(p1,p2) }
function {:inline} $sub.ref(p1: ref, p2: ref) returns (ref) { $sub.i64(p1,p2) }
const .str1: ref;
axiom (.str1 == $sub.ref(0,16));
const .str2: ref;
axiom (.str2 == $sub.ref(0,30));
const .str3: ref;
axiom (.str3 == $sub.ref(0,44));
const __VERIFIER_assume: ref;
axiom (__VERIFIER_assume == $sub.ref(0,52));
procedure {:inline 1} __VERIFIER_assume(x: i32)
{
$bb0:
  call {:cexpr "x"} boogie_si_record_i32(x);
  call {:cexpr "v"} boogie_si_record_i32(x);
  assume {:sourceloc "/usr/local/share/smack/lib/smack.c", 95, 3} true;
  assume true;
  assume {:sourceloc "/usr/local/share/smack/lib/smack.c", 31, 21} true;
  assume (x != $0);
  assume {:sourceloc "/usr/local/share/smack/lib/smack.c", 32, 1} true;
  $exn := false;
  return;
}
const __SMACK_dummy: ref;
axiom (__SMACK_dummy == $sub.ref(0,60));
const __SMACK_code: ref;
axiom (__SMACK_code == $sub.ref(0,68));
const __SMACK_decls: ref;
axiom (__SMACK_decls == $sub.ref(0,76));
function {:inline} $bitcast.ref.ref(i: ref) returns (ref) { i }
function {:inline} $add.i64(i1: i64, i2: i64) returns (i64) { (i1 + i2) }
function {:inline} $sub.i64(i1: i64, i2: i64) returns (i64) { (i1 - i2) }
function {:inline} $ult.i64.bool(i1: i64, i2: i64) returns (bool) { (i1 < i2) }
function {:inline} $slt.i64.bool(i1: i64, i2: i64) returns (bool) { (i1 < i2) }
function {:inline} $slt.i32(i1: i32, i2: i32) returns (i1) { (if (i1 < i2) then 1 else 0) }
function {:inline} $zext.i1.i32(i: i1) returns (i32) { i }
function $foeq.bool(f1: float, f2: float) returns (bool);
function $fp2si.float.i128(f: float) returns (i128);
function $fp2ui.float.i128(f: float) returns (i128);
function $si2fp.i128.float(i: i128) returns (float);
function $ui2fp.i128.float(i: i128) returns (float);
function $fp2si.float.i96(f: float) returns (i96);
function $fp2ui.float.i96(f: float) returns (i96);
function $si2fp.i96.float(i: i96) returns (float);
function $ui2fp.i96.float(i: i96) returns (float);
function $fp2si.float.i64(f: float) returns (i64);
function $fp2ui.float.i64(f: float) returns (i64);
function $si2fp.i64.float(i: i64) returns (float);
function $ui2fp.i64.float(i: i64) returns (float);
function $fp2si.float.i56(f: float) returns (i56);
function $fp2ui.float.i56(f: float) returns (i56);
function $si2fp.i56.float(i: i56) returns (float);
function $ui2fp.i56.float(i: i56) returns (float);
function $fp2si.float.i48(f: float) returns (i48);
function $fp2ui.float.i48(f: float) returns (i48);
function $si2fp.i48.float(i: i48) returns (float);
function $ui2fp.i48.float(i: i48) returns (float);
function $fp2si.float.i40(f: float) returns (i40);
function $fp2ui.float.i40(f: float) returns (i40);
function $si2fp.i40.float(i: i40) returns (float);
function $ui2fp.i40.float(i: i40) returns (float);
function $fp2si.float.i32(f: float) returns (i32);
function $fp2ui.float.i32(f: float) returns (i32);
function $si2fp.i32.float(i: i32) returns (float);
function $ui2fp.i32.float(i: i32) returns (float);
function $fp2si.float.i24(f: float) returns (i24);
function $fp2ui.float.i24(f: float) returns (i24);
function $si2fp.i24.float(i: i24) returns (float);
function $ui2fp.i24.float(i: i24) returns (float);
function $fp2si.float.i16(f: float) returns (i16);
function $fp2ui.float.i16(f: float) returns (i16);
function $si2fp.i16.float(i: i16) returns (float);
function $ui2fp.i16.float(i: i16) returns (float);
function $fp2si.float.i8(f: float) returns (i8);
function $fp2ui.float.i8(f: float) returns (i8);
function $si2fp.i8.float(i: i8) returns (float);
function $ui2fp.i8.float(i: i8) returns (float);
axiom (forall f1, f2: float :: ((f1 != f2) || $foeq.bool(f1,f2)));
axiom (forall i: i128 :: ($fp2ui.float.i128($ui2fp.i128.float(i)) == i));
axiom (forall f: float :: ($ui2fp.i128.float($fp2ui.float.i128(f)) == f));
axiom (forall i: i128 :: ($fp2si.float.i128($si2fp.i128.float(i)) == i));
axiom (forall f: float :: ($si2fp.i128.float($fp2si.float.i128(f)) == f));
axiom (forall i: i96 :: ($fp2ui.float.i96($ui2fp.i96.float(i)) == i));
axiom (forall f: float :: ($ui2fp.i96.float($fp2ui.float.i96(f)) == f));
axiom (forall i: i96 :: ($fp2si.float.i96($si2fp.i96.float(i)) == i));
axiom (forall f: float :: ($si2fp.i96.float($fp2si.float.i96(f)) == f));
axiom (forall i: i64 :: ($fp2ui.float.i64($ui2fp.i64.float(i)) == i));
axiom (forall f: float :: ($ui2fp.i64.float($fp2ui.float.i64(f)) == f));
axiom (forall i: i64 :: ($fp2si.float.i64($si2fp.i64.float(i)) == i));
axiom (forall f: float :: ($si2fp.i64.float($fp2si.float.i64(f)) == f));
axiom (forall i: i56 :: ($fp2ui.float.i56($ui2fp.i56.float(i)) == i));
axiom (forall f: float :: ($ui2fp.i56.float($fp2ui.float.i56(f)) == f));
axiom (forall i: i56 :: ($fp2si.float.i56($si2fp.i56.float(i)) == i));
axiom (forall f: float :: ($si2fp.i56.float($fp2si.float.i56(f)) == f));
axiom (forall i: i48 :: ($fp2ui.float.i48($ui2fp.i48.float(i)) == i));
axiom (forall f: float :: ($ui2fp.i48.float($fp2ui.float.i48(f)) == f));
axiom (forall i: i48 :: ($fp2si.float.i48($si2fp.i48.float(i)) == i));
axiom (forall f: float :: ($si2fp.i48.float($fp2si.float.i48(f)) == f));
axiom (forall i: i40 :: ($fp2ui.float.i40($ui2fp.i40.float(i)) == i));
axiom (forall f: float :: ($ui2fp.i40.float($fp2ui.float.i40(f)) == f));
axiom (forall i: i40 :: ($fp2si.float.i40($si2fp.i40.float(i)) == i));
axiom (forall f: float :: ($si2fp.i40.float($fp2si.float.i40(f)) == f));
axiom (forall i: i32 :: ($fp2ui.float.i32($ui2fp.i32.float(i)) == i));
axiom (forall f: float :: ($ui2fp.i32.float($fp2ui.float.i32(f)) == f));
axiom (forall i: i32 :: ($fp2si.float.i32($si2fp.i32.float(i)) == i));
axiom (forall f: float :: ($si2fp.i32.float($fp2si.float.i32(f)) == f));
axiom (forall i: i24 :: ($fp2ui.float.i24($ui2fp.i24.float(i)) == i));
axiom (forall f: float :: ($ui2fp.i24.float($fp2ui.float.i24(f)) == f));
axiom (forall i: i24 :: ($fp2si.float.i24($si2fp.i24.float(i)) == i));
axiom (forall f: float :: ($si2fp.i24.float($fp2si.float.i24(f)) == f));
axiom (forall i: i16 :: ($fp2ui.float.i16($ui2fp.i16.float(i)) == i));
axiom (forall f: float :: ($ui2fp.i16.float($fp2ui.float.i16(f)) == f));
axiom (forall i: i16 :: ($fp2si.float.i16($si2fp.i16.float(i)) == i));
axiom (forall f: float :: ($si2fp.i16.float($fp2si.float.i16(f)) == f));
axiom (forall i: i8 :: ($fp2ui.float.i8($ui2fp.i8.float(i)) == i));
axiom (forall f: float :: ($ui2fp.i8.float($fp2ui.float.i8(f)) == f));
axiom (forall i: i8 :: ($fp2si.float.i8($si2fp.i8.float(i)) == i));
axiom (forall f: float :: ($si2fp.i8.float($fp2si.float.i8(f)) == f));
const $GLOBALS_BOTTOM: ref;
const $EXTERNS_BOTTOM: ref;
function {:inline} $isExternal(p: ref) returns (bool) { $slt.ref.bool(p,$EXTERNS_BOTTOM) }
function {:inline} $load.i32(M: [ref] i32, p: ref) returns (i32) { M[p] }
function {:inline} $store.i32(M: [ref] i32, p: ref, v: i32) returns ([ref] i32) { M[p := v] }
procedure {:inline 1} boogie_si_record_i32(i: i32);
procedure {:inline 1} boogie_si_record_ref(i: ref);
var $CurrAddr: ref;
var $exn: bool;
const __SMACK_top_decl: ref;
axiom (__SMACK_top_decl == $sub.ref(0,84));
const __SMACK_init_func_memory_model: ref;
axiom (__SMACK_init_func_memory_model == $sub.ref(0,92));
procedure {:inline 1} __SMACK_init_func_memory_model()
{
$bb0:
  assume {:sourceloc "/usr/local/share/smack/lib/smack.c", 1010, 3} true;
  $CurrAddr := $1024.ref;
  assume {:sourceloc "/usr/local/share/smack/lib/smack.c", 1011, 1} true;
  $exn := false;
  return;
}
const sort2: ref;
axiom (sort2 == $sub.ref(0,100));
procedure {:inline 1} sort2(out2: ref, in2: ref) returns ($r: i32)
{
  var $p0: ref;
  var $i1: i32;
  var $p2: ref;
  var $i3: i32;
  var $i4: i1;
  var $p5: ref;
  var $i6: i32;
  var $p7: ref;
  var $p8: ref;
  var $i9: i32;
  var $p10: ref;
  var $p11: ref;
  var $i12: i32;
  var $p13: ref;
  var $p14: ref;
  var $i15: i32;
  var $p16: ref;
  var $i17: i1;
  var $i18: i32;
$bb0:
  call {:cexpr "out2"} boogie_si_record_ref(out2);
  call {:cexpr "in2"} boogie_si_record_ref(in2);
  assume {:sourceloc "sort.c", 16, 3} true;
  $p0 := in2;
  assume {:sourceloc "sort.c", 16, 3} true;
  $i1 := $load.i32($M.0,$p0);
  call {:cexpr "a"} boogie_si_record_i32($i1);
  assume {:sourceloc "sort.c", 17, 3} true;
  $p2 := $add.ref(in2,4);
  assume {:sourceloc "sort.c", 17, 3} true;
  $i3 := $load.i32($M.0,$p2);
  call {:cexpr "b"} boogie_si_record_i32($i3);
  assume {:sourceloc "sort.c", 18, 7} true;
  $i4 := $slt.i32($i1,$i3);
  assume {:sourceloc "sort.c", 18, 7} true;
  assume {:branchcond $i4} true;
  goto $bb1, $bb2;
$bb1:
  assume ($i4 == 1);
  assume {:sourceloc "sort.c", 19, 5} true;
  $p5 := in2;
  assume {:sourceloc "sort.c", 19, 5} true;
  $i6 := $load.i32($M.0,$p5);
  assume {:sourceloc "sort.c", 19, 5} true;
  $p7 := out2;
  assume {:sourceloc "sort.c", 19, 5} true;
  $M.0 := $store.i32($M.0,$p7,$i6);
  assume {:sourceloc "sort.c", 20, 5} true;
  $p8 := $add.ref(in2,4);
  assume {:sourceloc "sort.c", 20, 5} true;
  $i9 := $load.i32($M.0,$p8);
  assume {:sourceloc "sort.c", 20, 5} true;
  $p10 := $add.ref(out2,4);
  assume {:sourceloc "sort.c", 20, 5} true;
  $M.0 := $store.i32($M.0,$p10,$i9);
  assume {:sourceloc "sort.c", 21, 3} true;
  goto $bb3;
$bb2:
  assume !($i4 == 1);
  assume {:sourceloc "sort.c", 22, 5} true;
  $p11 := $add.ref(in2,4);
  assume {:sourceloc "sort.c", 22, 5} true;
  $i12 := $load.i32($M.0,$p11);
  assume {:sourceloc "sort.c", 22, 5} true;
  $p13 := out2;
  assume {:sourceloc "sort.c", 22, 5} true;
  $M.0 := $store.i32($M.0,$p13,$i12);
  assume {:sourceloc "sort.c", 23, 5} true;
  $p14 := in2;
  assume {:sourceloc "sort.c", 23, 5} true;
  $i15 := $load.i32($M.0,$p14);
  assume {:sourceloc "sort.c", 23, 5} true;
  $p16 := $add.ref(out2,4);
  assume {:sourceloc "sort.c", 23, 5} true;
  $M.0 := $store.i32($M.0,$p16,$i15);
  goto $bb3;
$bb3:
  assume {:sourceloc "sort.c", 25, 3} true;
  $i17 := $slt.i32($i1,$i3);
  assume {:sourceloc "sort.c", 25, 3} true;
  $i18 := $zext.i1.i32($i17);
  assume {:sourceloc "sort.c", 25, 3} true;
  $r := $i18;
  $exn := false;
  return;
}
const sort3: ref;
axiom (sort3 == $sub.ref(0,108));
procedure {:inline 1} sort3(conds: ref, out3: ref, in3: ref)
{
  var $i0: i32;
  var $p1: ref;
  var $p2: ref;
  var $i3: i32;
  var $p4: ref;
  var $p5: ref;
  var $p6: ref;
  var $i7: i32;
  var $p8: ref;
  var $p9: ref;
  var $i10: i32;
  var $p11: ref;
  var $p12: ref;
  var $i13: i32;
  var $p14: ref;
  var $i15: i32;
  var $p16: ref;
$bb0:
  call {:cexpr "conds"} boogie_si_record_ref(conds);
  call {:cexpr "out3"} boogie_si_record_ref(out3);
  call {:cexpr "in3"} boogie_si_record_ref(in3);
  assume {:sourceloc "sort.c", 29, 14} true;
  call $i0 := sort2(out3, in3);
  assume {:sourceloc "sort.c", 29, 14} true;
  $p1 := conds;
  assume {:sourceloc "sort.c", 29, 14} true;
  $M.0 := $store.i32($M.0,$p1,$i0);
  assume {:sourceloc "sort.c", 30, 3} true;
  $p2 := $add.ref(out3,4);
  assume {:sourceloc "sort.c", 30, 3} true;
  $i3 := $load.i32($M.0,$p2);
  assume {:sourceloc "sort.c", 30, 3} true;
  $p4 := $add.ref(in3,4);
  assume {:sourceloc "sort.c", 30, 3} true;
  $M.0 := $store.i32($M.0,$p4,$i3);
  assume {:sourceloc "sort.c", 31, 14} true;
  $p5 := $add.ref(out3,4);
  assume {:sourceloc "sort.c", 31, 14} true;
  $p6 := $add.ref(in3,4);
  assume {:sourceloc "sort.c", 31, 14} true;
  call $i7 := sort2($p5, $p6);
  assume {:sourceloc "sort.c", 31, 14} true;
  $p8 := $add.ref(conds,4);
  assume {:sourceloc "sort.c", 31, 14} true;
  $M.0 := $store.i32($M.0,$p8,$i7);
  assume {:sourceloc "sort.c", 32, 3} true;
  $p9 := out3;
  assume {:sourceloc "sort.c", 32, 3} true;
  $i10 := $load.i32($M.0,$p9);
  assume {:sourceloc "sort.c", 32, 3} true;
  $p11 := in3;
  assume {:sourceloc "sort.c", 32, 3} true;
  $M.0 := $store.i32($M.0,$p11,$i10);
  assume {:sourceloc "sort.c", 33, 3} true;
  $p12 := $add.ref(out3,4);
  assume {:sourceloc "sort.c", 33, 3} true;
  $i13 := $load.i32($M.0,$p12);
  assume {:sourceloc "sort.c", 33, 3} true;
  $p14 := $add.ref(in3,4);
  assume {:sourceloc "sort.c", 33, 3} true;
  $M.0 := $store.i32($M.0,$p14,$i13);
  assume {:sourceloc "sort.c", 34, 14} true;
  call $i15 := sort2(out3, in3);
  assume {:sourceloc "sort.c", 34, 14} true;
  $p16 := $add.ref(conds,8);
  assume {:sourceloc "sort.c", 34, 14} true;
  $M.0 := $store.i32($M.0,$p16,$i15);
  assume {:sourceloc "sort.c", 35, 1} true;
  $exn := false;
  return;
}
const sort3_wrapper: ref;
axiom (sort3_wrapper == $sub.ref(0,116));
procedure {:entrypoint} sort3_wrapper(conds: ref, out: ref, in: ref) returns ($r: ref)
{
  var $p0: ref;
  var $i1: i1;
  var $p3: ref;
  var $i4: i1;
  var $i2: i1;
  var $i5: i32;
  var $p6: ref;
  var $i7: i1;
  var $p9: ref;
  var $i10: i1;
  var $i8: i1;
  var $i11: i32;
  var $p12: ref;
  var $i13: i1;
  var $p15: ref;
  var $i16: i1;
  var $i14: i1;
  var $i17: i32;
  var $p18: ref;
  var $p19: ref;
  var $p20: ref;
  var $p21: ref;
  var $p22: ref;
  var $p23: ref;
  var $p24: ref;
  var $p25: ref;
  var $p26: ref;
  var $p27: ref;
$bb0:
  call $initialize();
  call {:cexpr "conds"} boogie_si_record_ref(conds);
  call {:cexpr "out"} boogie_si_record_ref(out);
  call {:cexpr "in"} boogie_si_record_ref(in);
  assume {:sourceloc "sort.c", 38, 3} true;
  $p0 := $add.ref(conds,48);
  assume {:sourceloc "sort.c", 38, 3} true;
  $i1 := $ult.ref($p0,out);
  assume {:sourceloc "sort.c", 38, 3} true;
  $i2 := 1;
  assume {:branchcond $i1} true;
  goto $bb1, $bb3;
$bb1:
  assume {:sourceloc "sort.c", 38, 3} true;
  assume ($i1 == 1);
  goto $bb2;
$bb2:
  assume {:sourceloc "sort.c", 38, 3} true;
  $i5 := $zext.i1.i32($i2);
  assume {:sourceloc "sort.c", 38, 3} true;
  call __VERIFIER_assume($i5);
  assume {:sourceloc "sort.c", 39, 3} true;
  $p6 := $add.ref(conds,48);
  assume {:sourceloc "sort.c", 39, 3} true;
  $i7 := $ult.ref($p6,in);
  assume {:sourceloc "sort.c", 39, 3} true;
  $i8 := 1;
  assume {:branchcond $i7} true;
  goto $bb4, $bb6;
$bb3:
  assume !($i1 == 1);
  assume {:sourceloc "sort.c", 38, 3} true;
  $p3 := $add.ref(out,48);
  assume {:sourceloc "sort.c", 38, 3} true;
  $i4 := $ult.ref($p3,conds);
  assume {:sourceloc "sort.c", 38, 3} true;
  $i2 := $i4;
  goto $bb2;
$bb4:
  assume {:sourceloc "sort.c", 39, 3} true;
  assume ($i7 == 1);
  goto $bb5;
$bb5:
  assume {:sourceloc "sort.c", 39, 3} true;
  $i11 := $zext.i1.i32($i8);
  assume {:sourceloc "sort.c", 39, 3} true;
  call __VERIFIER_assume($i11);
  assume {:sourceloc "sort.c", 40, 3} true;
  $p12 := $add.ref(out,48);
  assume {:sourceloc "sort.c", 40, 3} true;
  $i13 := $ult.ref($p12,in);
  assume {:sourceloc "sort.c", 40, 3} true;
  $i14 := 1;
  assume {:branchcond $i13} true;
  goto $bb7, $bb9;
$bb6:
  assume !($i7 == 1);
  assume {:sourceloc "sort.c", 39, 3} true;
  $p9 := $add.ref(in,48);
  assume {:sourceloc "sort.c", 39, 3} true;
  $i10 := $ult.ref($p9,conds);
  assume {:sourceloc "sort.c", 39, 3} true;
  $i8 := $i10;
  goto $bb5;
$bb7:
  assume {:sourceloc "sort.c", 40, 3} true;
  assume ($i13 == 1);
  goto $bb8;
$bb8:
  assume {:sourceloc "sort.c", 40, 3} true;
  $i17 := $zext.i1.i32($i14);
  assume {:sourceloc "sort.c", 40, 3} true;
  call __VERIFIER_assume($i17);
  assume {:sourceloc "sort.c", 43, 13} true;
  call {:name conds} $p18 := __SMACK_value.ref(conds);
  assume $isExternal($p18);
  assume {:sourceloc "sort.c", 43, 3} true;
  call public_in($p18);
  assume {:sourceloc "sort.c", 44, 13} true;
  call {:name out} $p19 := __SMACK_value.ref(out);
  assume $isExternal($p19);
  assume {:sourceloc "sort.c", 44, 3} true;
  call public_in($p19);
  assume {:sourceloc "sort.c", 45, 13} true;
  call {:name in} $p20 := __SMACK_value.ref(in);
  assume $isExternal($p20);
  assume {:sourceloc "sort.c", 45, 3} true;
  call public_in($p20);
  assume {:sourceloc "sort.c", 48, 20} true;
  $p21 := $bitcast.ref.ref(conds);
  assume {:sourceloc "sort.c", 48, 20} true;
  call {:name conds} {:array "$load.i32", $M.0, conds, 4, 12} $p22 := __SMACK_values($p21, 3);
  assume $isExternal($p22);
  assume {:sourceloc "sort.c", 48, 3} true;
  call declassified_out($p22);
  assume {:sourceloc "sort.c", 51, 13} true;
  $p23 := $bitcast.ref.ref(conds);
  assume {:sourceloc "sort.c", 51, 13} true;
  call {:name conds} {:array "$load.i32", $M.0, conds, 4, 12} $p24 := __SMACK_values($p23, 3);
  assume $isExternal($p24);
  assume {:sourceloc "sort.c", 51, 3} true;
  call public_in($p24);
  assume {:sourceloc "sort.c", 52, 14} true;
  $p25 := $bitcast.ref.ref(conds);
  assume {:sourceloc "sort.c", 52, 14} true;
  call {:name conds} {:array "$load.i32", $M.0, conds, 4, 12} $p26 := __SMACK_values($p25, 3);
  assume $isExternal($p26);
  assume {:sourceloc "sort.c", 52, 3} true;
  call public_out($p26);
  assume {:sourceloc "sort.c", 53, 14} true;
  call {:name $r} $p27 := __SMACK_value.ref($r);
  assume $isExternal($p27);
  assume {:sourceloc "sort.c", 53, 3} true;
  call public_out($p27);
  assume {:sourceloc "sort.c", 59, 3} true;
  call sort3(conds, out, in);
  assume {:sourceloc "sort.c", 60, 3} true;
  $r := conds;
  $exn := false;
  return;
$bb9:
  assume !($i13 == 1);
  assume {:sourceloc "sort.c", 40, 3} true;
  $p15 := $add.ref(in,48);
  assume {:sourceloc "sort.c", 40, 3} true;
  $i16 := $ult.ref($p15,out);
  assume {:sourceloc "sort.c", 40, 3} true;
  $i14 := $i16;
  goto $bb8;
}
const public_in: ref;
axiom (public_in == $sub.ref(0,124));
procedure {:inline 1} public_in($p0: ref);
const __SMACK_value: ref;
axiom (__SMACK_value == $sub.ref(0,132));
procedure {:inline 1} __SMACK_value.ref(p.0: ref) returns ($r: ref);
const declassified_out: ref;
axiom (declassified_out == $sub.ref(0,140));
procedure {:inline 1} declassified_out($p0: ref);
const __SMACK_values: ref;
axiom (__SMACK_values == $sub.ref(0,148));
procedure {:inline 1} __SMACK_values($p0: ref, $i1: i32) returns ($r: ref);
const public_out: ref;
axiom (public_out == $sub.ref(0,156));
procedure {:inline 1} public_out($p0: ref);
const __SMACK_return_value: ref;
axiom (__SMACK_return_value == $sub.ref(0,164));
const llvm.dbg.value: ref;
axiom (llvm.dbg.value == $sub.ref(0,172));
const __SMACK_static_init: ref;
axiom (__SMACK_static_init == $sub.ref(0,180));
procedure {:inline 1} __SMACK_static_init()
{
$bb0:
  $exn := false;
  return;
}
procedure {:inline 1} $initialize()
{
  call __SMACK_static_init();
  call __SMACK_init_func_memory_model();
  return;
}