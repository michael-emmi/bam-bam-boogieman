// @c2s-options --unroll 1
// @c2s-options --rounds 3
// @c2s-expected Verified

// BEGIN SMACK-GENERATED CODE

// Memory region declarations: 4
var $M.0: [int] int;
var $M.1: [int] int;
var $M.2: [int] int;
var $M.3: [int] int;

axiom $GLOBALS_BOTTOM == -9423;
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
const unique .str110: int;
const unique .str111: int;
const unique .str112: int;
const unique .str113: int;
const unique .str114: int;
const unique .str115: int;
const unique .str116: int;
const unique .str117: int;
const unique .str118: int;
const unique .str119: int;
const unique .str12: int;
const unique .str120: int;
const unique .str121: int;
const unique .str122: int;
const unique .str123: int;
const unique .str124: int;
const unique .str125: int;
const unique .str126: int;
const unique .str127: int;
const unique .str128: int;
const unique .str129: int;
const unique .str13: int;
const unique .str130: int;
const unique .str131: int;
const unique .str132: int;
const unique .str133: int;
const unique .str134: int;
const unique .str135: int;
const unique .str136: int;
const unique .str137: int;
const unique .str138: int;
const unique .str139: int;
const unique .str14: int;
const unique .str140: int;
const unique .str141: int;
const unique .str142: int;
const unique .str143: int;
const unique .str144: int;
const unique .str145: int;
const unique .str146: int;
const unique .str147: int;
const unique .str148: int;
const unique .str149: int;
const unique .str15: int;
const unique .str150: int;
const unique .str151: int;
const unique .str152: int;
const unique .str153: int;
const unique .str154: int;
const unique .str155: int;
const unique .str156: int;
const unique .str157: int;
const unique .str158: int;
const unique .str159: int;
const unique .str16: int;
const unique .str160: int;
const unique .str161: int;
const unique .str162: int;
const unique .str163: int;
const unique .str164: int;
const unique .str165: int;
const unique .str166: int;
const unique .str167: int;
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
const unique __SMACK_assert: int;
const unique __SMACK_assume: int;
const unique __SMACK_decls: int;
const unique __SMACK_nondet: int;
const unique __SMACK_nondet.XXX: int;
const unique cas: int;
const unique initialize: int;
const unique main: int;
const unique malloc: int;
const unique pop: int;
const unique push: int;
const unique s: int;
const unique violin_decls: int;
procedure $static_init()
  modifies $Alloc, $CurrAddr, N, C, W, $M.0, $M.1, $M.2, $M.3;
{
  $M.2[__SMACK_nondet.XXX] := 0;
  $M.3[s] := 0;
  return;
}
procedure __SMACK_assert(v: bool)
  modifies $Alloc, $CurrAddr, N, C, W, $M.0, $M.1, $M.2, $M.3;
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
  modifies $Alloc, $CurrAddr, N, C, W, $M.0, $M.1, $M.2, $M.3;
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
procedure __SMACK_mod#0(p#0: int);
procedure __SMACK_nondet()
  returns ($r: int)
  modifies $Alloc, $CurrAddr, N, C, W, $M.0, $M.1, $M.2, $M.3;
{
  var $p: int;
$bb0:
  $p := $M.2[__SMACK_nondet.XXX];
  havoc $p;
  $r := $p;
  return;
}
procedure cas(p: int, t: int, x: int)
  returns ($r: bool)
  modifies $Alloc, $CurrAddr, N, C, W, $M.0, $M.1, $M.2, $M.3;
{
  var $b: bool;
  var $b1: bool;
  var $p: int;
$bb0:
  $p := $M.3[p];
  $b := ($p == t);
  goto $bb3, $bb4;
$bb1:
  $M.3[p] := x;
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
procedure initialize()
  modifies $Alloc, $CurrAddr, N, C, W, $M.0, $M.1, $M.2, $M.3;
{
$bb0:
  $M.3[s] := 0;
  return;
}
procedure main()
  returns ($r: int)
  modifies N, C, Ai, A, Ri, W, $Alloc, $CurrAddr, N, C, W, $M.0, $M.1, $M.2, $M.3;
{
  var x: int;
$bb0:
  call $static_init();
  call violin.init();
  call initialize();
  call {:async} push(1);
  call {:async} push(2);
  call {:async} x := pop();
  call {:async} x := pop();
  assume {:yield} true;
  assert stack_spec(N,C,Ai,W);
  $r := 0;
  return;
}
procedure pop()
  returns ($r: int)
  modifies N, C, Ai, A, Ri, W, $Alloc, $CurrAddr, N, C, W, $M.0, $M.1, $M.2, $M.3;
{
  var $b: bool;
  var $b4: bool;
  var $b5: bool;
  var $p: int;
  var $p1: int;
  var $p10: int;
  var $p2: int;
  var $p3: int;
  var $p6: int;
  var $p7: int;
  var $p8: int;
  var $p9: int;
  var $myop: int;
$bb0:
  call $myop := remove.start(0);
  call $p := $malloc(16);
  goto $bb1;
$bb1:
  assume {:yield} true;
  $p1 := $M.3[s];
  $b := ($p1 == 0);
  goto $bb4, $bb5;
$bb2:
  call remove.finish($myop,-1);
  $p10 := -1;
  goto $bb10;
$bb3:
  $p2 := $pa($pa($p1, 0, 16), 8, 1);
  $p3 := $M.0[$p2];
  goto $bb6;
$bb4:
  assume $b;
  goto $bb2;
$bb5:
  assume !($b);
  goto $bb3;
$bb6:
  call $b4 := cas(s, $p1, $p3);
  $b5 := $i2b($xor($b2i($b4), $b2i(true)));
  goto $bb8, $bb9;
$bb7:
  $p6 := $pa($pa($p1, 0, 16), 0, 1);
  $p7 := $M.0[$p6];
  call remove.finish($myop,$p7);
  $p8 := $pa($pa($p1, 0, 16), 0, 1);
  $p9 := $M.0[$p8];
  $p10 := $p9;
  goto $bb10;
$bb8:
  assume $b5;
  goto $bb1;
$bb9:
  assume !($b5);
  goto $bb7;
$bb10:
  $r := $p10;
  return;
}
procedure push(v: int)
  modifies N, C, Ai, A, Ri, W, $Alloc, $CurrAddr, N, C, W, $M.0, $M.1, $M.2, $M.3;
{
  var $b: bool;
  var $b5: bool;
  var $p: int;
  var $p1: int;
  var $p2: int;
  var $p3: int;
  var $p4: int;
  var $myop: int;
$bb0:
  call $myop := add.start(v);
  call $p := $malloc(16);
  $p1 := $p;
  $p2 := $pa($pa($p1, 0, 16), 0, 1);
  $M.0[$p2] := v;
  goto $bb1;
$bb1:
  assume {:yield} true;
  $p3 := $M.3[s];
  $p4 := $pa($pa($p1, 0, 16), 8, 1);
  $M.0[$p4] := $p3;
  goto $bb2;
$bb2:
  call $b := cas(s, $p3, $p1);
  $b5 := $i2b($xor($b2i($b), $b2i(true)));
  goto $bb4, $bb5;
$bb3:
  call add.finish($myop,v);
  return;
$bb4:
  assume $b5;
  goto $bb1;
$bb5:
  assume !($b5);
  goto $bb3;
}
procedure violin_decls()
  modifies $Alloc, $CurrAddr, N, C, W, $M.0, $M.1, $M.2, $M.3;
{
$bb0:
  return;
}
axiom (__SMACK_nondet.XXX == -38);
axiom (s == -9132);
axiom #VALUES == 2;
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
axiom (empty == -1);
axiom (forall i, j, k: int :: {O(i), O(j), O(k)} $po(i,j) && $po(j,k) ==> $po(i,k));
axiom (forall i, j: int :: {O(i), O(j)} $po(i,j) && $po(j,i) ==> i == j);
axiom (forall i: int :: {O(i)} $po(i,i));
axiom (forall i:int :: $i2b(i) <==> i != 0);
axiom (forall i:int :: $i2p(i) == i);
axiom (forall i:int :: $p2b(i) <==> i != 0);
axiom (forall i:int :: $p2i(i) == i);
axiom (forall p,s:int :: $trunc(p,s) == p);
axiom (forall p:int, i:int, s:int :: {$pa(p,i,s)} $pa(p,i,s) == p + i * s);
const #VALUES: int;
const $GLOBALS_BOTTOM: int;
const $MOP: $mop;
const $UNDEF: int;
const $ffalse: float;
const $ftrue: float;
const unique $NULL: int;
const unique add: method;
const unique empty: val;
const unique remove: method;
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
function $po(i,j: int) returns (bool);
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
function O(op) returns (bool);
function V(op) returns (bool);
function active(o: op, N: int, C: [op] bool) returns (bool) { started(o,N) && !completed(o,N,C) }
function bag_spec(N: int, C: [op] bool, Ai: [val] bool, W: [op] bool) returns (bool) {  no_thinair(N,C,Ai) && unique_removes(N,C) && no_false_empty(N,C,W)}
function bef(o1, o2: op) returns (bool) { $po(o1,o2) }
function bef?(o1, o2: op) returns (bool) { !$po(o2,o1) }
function completed(o: op, N: int, C: [op] bool) returns (bool) { started(o,N) && C[o] }
function m(op) returns (method);
function match(o1: op, o2: op) returns (bool) {   m(o1) == add && m(o2) == remove && v(o1) == v(o2) }
function no_false_empty(N: int, C: [op] bool, W: [op] bool) returns (bool) {  (forall o: op :: {O(o)} completed(o,N,C) && m(o) == remove && v(o) == empty ==> W[o])}
function no_thinair(N: int, C: [op] bool, Ai: [int] bool) returns (bool) {  (forall o: op :: {O(o)} completed(o,N,C) && m(o) == remove ==>     Ai[v(o)] || v(o) == empty  )}
function queue_order(N: int, C: [op] bool) returns (bool) {  (forall o1, o2, o1', o2': op :: {O(o1), O(o2), O(o1'), O(o2')}     started(o1,N) && started(o2,N) && completed(o1',N,C) && completed(o2',N,C)    && uniq4(o1,o2,o1',o2')    && match(o1,o1') && match (o2,o2')    && bef(o1',o2') ==> bef?(o1,o2)  )}
function queue_spec(N: int, C: [op] bool, Ai: [val] bool, W: [op] bool)returns (bool) {  bag_spec(N,C,Ai,W) && queue_order(N,C)}
function sees_empty(A: [val] bool, Ri: [val] bool) returns (bool) {  (forall v: val :: {V(v)} V(v) && A[v] ==> Ri[v])}
function stack_order(N: int, C: [op] bool) returns (bool) {  (forall o1, o2, o1', o2': op :: {O(o1), O(o2), O(o1'), O(o2')}     started(o1,N) && started(o2,N) && completed(o1',N,C) && completed(o2',N,C)    && uniq4(o1,o2,o1',o2')     && match(o1,o1') && match(o2,o2')    && bef(o1',o2') ==> bef?(o2,o1) || (bef?(o1,o2) && bef?(o1',o2))  )}
function stack_spec(N: int, C: [op] bool, Ai: [val] bool, W: [op] bool)returns (bool) {  bag_spec(N,C,Ai,W) && stack_order(N,C)}
function started(o: op, N: int) returns (bool) { 0 <= o && o < N }
function uniq4(o1,o2,o3,o4: op) returns (bool) { o1 != o2 && o1 != o3 && o1 != o4 && o2 != o3 && o2 != o4 && o3 != o4 }
function unique_removes(N: int, C: [op] bool) returns (bool) {  (forall o1, o2: op :: {O(o1), O(o2)} completed(o1,N,C) && completed(o2,N,C) && o1 != o2 ==>      m(o1) != m(o2) || v(o1) != v(o2) || v(o1) == empty || v(o2) == empty  )}
function v(op) returns (val);
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
procedure add.finish(o: op, ignored: val)modifies C;modifies A;{  call op.finish(o);  A[v(o)] := true;}
procedure add.start(v: val) returns (o: op)modifies N;modifies Ai;{  call o := op.start();  assume m(o) == add;  assume v(o) == v;  assume V(v);  Ai[v(o)] := true;  return;}
procedure boogie_si_record_int(i: int);
procedure boogie_si_record_mop(m: $mop);
procedure op.finish(o: op)modifies C;{  C[o] := true;  assume completed(o,N,C);}
procedure op.init()modifies N, C;{  assume (forall o: op :: {O(o)} !C[o]);  N := 0;}
procedure op.start() returns (o: op)modifies N;{  o := N;  assume O(o);  assume (forall oo: op :: {O(oo)} completed(oo,N,C) ==> bef(oo,o));  assume (forall oo: op :: {O(oo)} active(oo,N,C) ==> !bef(o,oo) && !bef(oo,o));  N := N + 1;}
procedure remove.finish(o: op, v: val)modifies C;{  assume v(o) == v;  call op.finish(o);  return;}
procedure remove.start(ignored: val) returns (o: op)modifies N;modifies Ri, W;{  call o := op.start();  assume m(o) == remove;  if (v(o) == empty) {    W[o] := sees_empty(A,Ri);  } else {    Ri[v(o)] := true;    if (sees_empty(A,Ri)) {      call see_empty();    }  }  return;}
procedure see_empty();modifies W;ensures sees_empty(A,Ri) ==> (forall o: op :: {O(o)} active(o,N,C) ==> W[o]);ensures sees_empty(A,Ri) ==> (forall o: op :: {O(o)} !active(o,N,C) ==> W[o] == old(W[o]));
procedure violin.init()modifies N, C;{  call op.init();  assume (forall v: val :: {V(v)} V(v) ==> v >= 0 && v <= #VALUES);  assume (forall v: val :: {V(v)} !Ai[v]);  assume (forall v: val :: {V(v)} !A[v]);  assume (forall v: val :: {V(v)} !Ri[v]);  assume !Ai[empty];  assume !A[empty];  assume !Ri[empty];  assume (forall o: op :: {O(o)} !W[o]);}
type $mop;
type float;
type method;
type op = int;
type val = int;
var $Alloc: [int] bool;
var $CurrAddr:int;
var Ai, A, Ri: [val] bool;
var C: [op] bool;
var N: op;
var W: [op] bool;

// END SMACK-GENERATED CODE
