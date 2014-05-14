// @c2s-options --unroll 1
// @c2s-options --rounds 2
// @c2s-expected Got a trace

var x: int;

procedure p()
{
  x := x + 1;
  return;
}

procedure main()
{
  x := 0;
  call {:async} p();
  assume {:yield} true;
  assert x == 0;
  return;
}
