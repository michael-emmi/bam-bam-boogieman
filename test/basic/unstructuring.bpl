function f(int) returns (int);
function g(int, int) returns (bool);

procedure main()
{
  var i, j, k: int;

  i, j, k := 0, 0, 0;

  while (i < 10)
  invariant g(i,j);
  {
    i, j := f(i), f(j);
  }

  while (k < 1)
  {
    k := f(k);
  }

  assert false;
}
