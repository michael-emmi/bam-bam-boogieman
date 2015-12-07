var x, y, z: int;

procedure p()
{
  x := 0;
}

procedure q()
{
  y := 0;
  call p();
  call s();
}

procedure r()
{
  z := 0;
  call q();
}

procedure s()
{
  call r();
}

procedure t()
{
  call r();
}
