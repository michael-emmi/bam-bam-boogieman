
procedure p()
{
  return;
}

procedure q()
requires true;
ensures true;
{
  call p();
  return;
}

procedure {:entrypoint} r()
{
  call p();
  call q();
  return;
}
