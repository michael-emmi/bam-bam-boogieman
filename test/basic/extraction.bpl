function f(bool) returns (bool);
function g(bool) returns (bool);
function h(bool) returns (bool);

procedure main()
{
  var x: bool;

  while (f(x))
  invariant g(x);
  {
    x := h(x);
  }

  while (f(x)) {
    x := h(x);
  }

  while (f(x))
  invariant g(x);
  {
    x := h(x);
    while (f(x))
    invariant g(x);
    {
      x := h(x);
    }
    x := h(x);
  }

  goto head1;

head1:
  goto body1, exit1;

body1:
  assume f(x);
  x := h(x);
  goto head1;

exit1:
  assume !f(x);
  goto head2;

head2:
  assert g(x);
  goto body2, exit2;

body2:
  assume f(x);
  x := h(x);
  goto nested_head;

nested_head:
  assert g(x);
  goto nested_body, nested_exit;

nested_body:
  assume f(x);
  x := h(x);
  goto nested_head;

nested_exit:
  assume !f(x);
  x := h(x);
  goto head2;

exit2:
  assume !f(x);
  return;

}
