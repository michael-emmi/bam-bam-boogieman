function f(int) returns (int);
function g(int, int) returns (bool);

procedure main()
{
  var i, j, k: int;

  i, j, k := 0, 0, 0;

  if (*) {
    i := f(i);
    if (j < 10) {
      i := f(i);
    } else if (j < 20) {
      j := f(i);
    } else {
      j := f(i);
      k := f(j);
    }
  } else {
    j := f(j);
  }

  while (i < 10)
  invariant g(i,j);
  {
    i, j := f(i), f(j);
  }

  while (k < 1)
  {
    k := f(k);
    while (*) {
      j := j(k);
      break;
    }
    k := f(k);
  }

  assert false;
}
