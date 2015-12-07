
function f(int) returns (int);

var g: int;

procedure {:atomic} p()
{
  g := 0;
  g := 1;
  return;
}

procedure q()
{
  var x: int;
  x := g;
  x := f(x);
  g := x;
  x := f(x);
  call p();
  x := f(x);
  havoc g;
  x := g;
  x := f(x);
  g := x;
  return;
}

procedure r()
{
  call p();
  return;
}
