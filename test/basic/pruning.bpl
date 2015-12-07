const c: int;
const d: int;

function f(x: int) returns (int);
function g(x: int) returns (int);
function h(x: int) returns (int);

axiom (c == 0);
axiom (d == 0);
axiom (forall x: int :: (g(x) == 0));

var w: int;
var x: int;
var y, z: int;

procedure p()
{
  call r();
}

procedure q1()
{
  call q2();
}

procedure q2()
{
  call q1();
  w := 0;
}

procedure r()
{
  x := 0;
}

procedure main()
{
  z := g(c);
  call p();
}
