
function f(int) returns (int);

procedure p()
{
  var x, y, z: int;
  x, y, z := 0, 1, 2;
  x, y, z := f(z), f(x), f(y);
  return;
}
