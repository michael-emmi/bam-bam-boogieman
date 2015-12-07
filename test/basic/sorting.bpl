
procedure r();

var u: int;

procedure p()
modifies x, w, z, u;
ensures x == 0;
requires x == 0;
modifies y;
ensures w == 0;
requires y == 0;
{
  var d: int;
  var a, c: int;
  var e, b: int;

  return;
}

axiom (D == 2);

procedure q();

var z: int;

var v, y: int;

var x, w: int;

const D: int;

axiom (C == 1);

function foo(x: int) returns (int);

const C: int;

function zoo(x: int) returns (int);
