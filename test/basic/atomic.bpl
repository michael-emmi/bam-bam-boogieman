
procedure p()
{
  assume {:yield} true;
}

procedure q()
{

}

procedure r()
{
  call p();
}

procedure s()
{
  call q();
}

procedure t()
{
  call p();
}
