{
  if($1 == "total"){
    print $0
    next
  }
  
  # may need to adjust $9 to match your name column
  if(match($9, /^(\x1B\[[0-9;]+[A-Za-z])*\./)) { # optionally look past control sequences like: ^[38;5;60m
    df[++dd] = $0
  }
  else {
    nf[++nn] = $0
  }
}
END{
  while (++d in df)
    print df[d]
  while (++n in nf)
    print nf[n]
}
