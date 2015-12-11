const c: bool;

axiom true;
axiom c == true;

var x: bool;
var y: bool;
var z: bool;

function f(bool) returns (bool);

procedure p1()
{
  havoc x;
}

procedure p2()
{
  assert f(y);
}

procedure p3()
{
  assume f(y);
}

procedure p4() returns (r: bool)
{
  r := true;
}

procedure p5() returns (r: bool)
{
  havoc r;
}

procedure p6()
{
entry:
  goto first;

first:
  goto next;

next:
  z := true;
  goto b1, b2;

b1:
  goto b3;

b2:
  goto b3;

b3:
  return;
}

procedure p7()
{
  z := true;
  assert true;
  assume true;
  call p2();
  call p3();
}

procedure p8()
{
  call p9();
}

procedure p9()
{
  assert true;
}
