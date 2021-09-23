#!/usr/bin/perl
use strict;
use Switch;

my $pacol = $ARGV[0];
my $pbcol = $ARGV[1];

sub genotype{
  my ($ref, $alternate, $dp, $pl) = @_;
  my @alt=split(/,/,$alternate);
  if (scalar(@alt) >2){
    warn "More than two alternate alleles!: $pl $alternate"
  }
  my $geno = 0;
  my $type;
  my @arr=split(/,/,$pl);
  if($dp > 0){
    for(my $i=0;$i < scalar(@arr); $i++){ 
      if ($arr[$i] == 0){
        $geno = $i;
      }
    }
    switch($geno){
      case (0)	{$type = $ref.$ref;}
      case (1)	{$type = $ref.$alt[0];}
      case (2)	{$type = $alt[0].$alt[0];}
      case (3)	{$type = $ref.$alt[1];}
      case (4)	{$type = $alt[0].$alt[1];}
      case (5)	{$type = $alt[1].$alt[1];}
      else	{die "Genotype out of bounds!";}
    }
  } else {
    $type = "-";
  }
  return $type;
}

while(<STDIN>){
  chomp;
  my @arr=split(/\t/, $_);
  my $ref=0;
  my $altc=0;
  my $het=0;
  my $mis=0;
# first define the parental alleles (a&b) from available info
  my $paa = genotype($arr[$pacol]);
  my $pab = genotype($arr[$pbcol]);
  if (($arr[4] =~ /^[ATCG]$/) ||($arr[4] =~ /^[ATCG]\,[ATCG]$/)){ #no funny business here
    my $callsref;

    print "$arr[0]\t$arr[1]\t$arr[3]\t$arr[4]";

    for (my $i=9;$i < scalar(@arr);$i++){
      my @all=split(/[:]/, $arr[$i]);
      $callsref->{$arr[0]}->{$arr[1]}->{$i} = genotype($arr[3],$arr[4],$all[2],$all[1]); #.":".$all[2];
      print "\t".$callsref->{$arr[0]}->{$arr[1]}->{$i};
      if ($callsref->{$arr[0]}->{$arr[1]}->{$i} =~ /$arr[3]$arr[3]/){
        $ref++;
      }
#      my @alt = split(/,/,$arr[4]);
      if (($callsref->{$arr[0]}->{$arr[1]}->{$i} =~ /$arr[4]$arr[4]/)){
        $altc++;
      }
      if (($callsref->{$arr[0]}->{$arr[1]}->{$i} =~ /($arr[3])($arr[4])/)||($callsref->{$arr[0]}->{$arr[1]}->{$i} =~ /($arr[4])($arr[3])/)){
        $het++;
      }
      if ($callsref->{$arr[0]}->{$arr[1]}->{$i} =~ /X/ || $callsref->{$arr[0]}->{$arr[1]}->{$i} =~ /-/){
        $mis++;
      }
    }
 #   my $total = (scalar(@arr) - 9);
 #   my $totcalls = $ref+$altc+$het;
 #   my $falt = ($altc/$totcalls);
 #   my $fmis = ($mis/$total);
 #   my $fhet = ($het/$totcalls);
#   print "$falt\t$fmis\t$fhet";


  print "\n"
  }
}

