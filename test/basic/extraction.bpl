function f(bool) returns (bool);

procedure main()
{
  var x: bool;

  while (x)
  invariant true;
  {
    x := f(x);
  }

  while (x) {
    x := f(x);
  }

  goto head1;

head1:
  goto body1, exit1;

body1:
  assume x;
  x := f(x);
  goto head1;

exit1:
  assume !x;
  goto head2;

head2:
  assert true;
  goto body2, exit2;

body2:
  assume x;
  x := f(x);
  goto head2;

exit2:
  assume !x;
  return;

}
