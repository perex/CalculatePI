program CalculatePI;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Diagnostics,
  System.Threading,
  System.Classes,
  System.Math,
  System.SyncObjs,
  System.Generics.Collections;

const
  num_steps = 10;//000; //000;
  kOutput = False;

var
  Timer: TStopwatch;
  FACount: array of array of Double;
  I: Integer;
  local: Double;

threadvar
//
  sum_parallel: Double;



// 4 * ( -1.0 / 3.0 + 1.0/5.0 - 1.0/7.0 + 1.0/9.0 - 1.0/11.0 ... )
(*private static double CalculatePi(int iterations)
{
double pi = 1;
double multiplier = -1;
for (int i = 3; i < iterations; i+=2)
{
pi += 1.0/(double) i*multiplier;
multiplier *= -1;
}
return pi*4.0;
}
*)
// 4 * ( -1.0 / 3.0 + 1.0/5.0 - 1.0/7.0 + 1.0/9.0 - 1.0/11.0 ... )
(*function SerialPI: Double;
var
  I: Integer;
  pi, multiplier: Double;
begin
  pi := 1;
  multiplier := -1;

  I := 3;
  while I < num_steps do
  begin
    pi := pi + (1.0 / (I * multiplier));
    multiplier := multiplier * -1;
    Inc(I, 2);
  end;
  Result := pi * 4.0;
end;
*)
procedure MyWriteln(mystring: String);
begin
  if kOutput then
    Writeln(mystring);
end;

function calculate(iteration: Integer; step: Double): Double;
var
  x: Double;
begin
  x := (iteration + 0.5) * step;
  Result := (local + 4.0) / (1.0 + (x * x));
  //Result := (iteration + 0.5) * step;
end;

function SerialPI: Double;
var
  I: Integer;
  sum, step, x: Double;
begin
  sum := 0.0;
  step := 1.0 / num_steps;

  for I := 0 to num_steps-1 do
    begin
      x := (I + 0.5) * step;
      sum := sum + (4.0 / (1.0 + x * x));
      WriteLn(Format('%d;%0.15f;%0.15f',[I, x, sum]));
    end;
  Result := step * sum;
end;

function ParallelPI: Double;
var
  step: Double;
  FLock : TObject;
  LoopResult : TParallel.TLoopResult;
  AHighExclusive: Integer;
  pi : Double;
  Results: TDictionary<Cardinal,Double>;
begin
  Results := TDictionary<Cardinal,Double>.Create;
  sum_parallel := 0.0;
  step := 1.0 / num_steps;
  FLock := TObject.Create;
  local := 0.0;

  //TParallel.&For(ALowInclusive, AHighExclusive: Integer; const AIteratorEvent: TProc<Integer, TLoopState>): TLoopResult;
  WriteLn('I;CurrentThread;Results.Items[aa];local;sum_parallel');
  TParallel.&For(
    0,
    num_steps-1,
    procedure (I: Integer)
      var
        x: Double;
        aa: Cardinal;
      begin
        aa := TThread.CurrentThread.Handle;

        x := (I + 0.5) * step;
        local := local + 4.0 / (1.0 + (x * x));

        TMonitor.Enter(FLock);
        try
          if Results.ContainsKey(aa) then
            Results.Items[aa] := local
          else
            Results.Add(aa, local);

          //WriteLn(Format('I=%d;CurrentThread=%d;Value=%0.15f',[I,aa, Results.Items[aa]]));
          sum_parallel := sum_parallel + local;
          //MyWriteln('  sum_parallel = ' + sum_parallel.ToString());
          //WriteLn(Format('local=%0.15f;sum_parallel=%0.15f',[local, sum_parallel]));
          WriteLn(Format('%d;%0.15f;%d;%0.15f;%0.15f;%0.15f',[I, x, aa, Results.Items[aa], local,sum_parallel]));
        finally
          TMonitor.Exit(FLock);
        end;
      end
    );
//   Result := step * sum_parallel;
   Result := step * local;

(*   pi := 1;

   AHighExclusive := (num_steps - 3) div 2;

   LoopResult := TParallel.&For(
    0,
    AHighExclusive,
    procedure (loopIndex: Integer)
      var
        i, multiplier: Double;

      begin
        if loopIndex mod 2 = 0 then
          multiplier := -1
        else
          multiplier := 1;

        i := 3 + loopIndex * 2;

        local := local + 1.0 / (i * multiplier);

        TMonitor.Enter(FLock);
        try
          MyWriteln('-------------INSIDE TMONITOR');
          pi := pi + local;
          MyWriteln('  pi = ' + pi.ToString());
        finally
          TMonitor.Exit(FLock);
        end;
      end
    );
   Result := pi * 4.0;
   *)
end;

begin

  Timer := TStopWatch.Create() ;
  try
    Timer.Start;
    Writeln('SerialPI: ');
    Write(Format('%10e', [SerialPI]));
    Timer.Stop;
    Writeln(' Time: ' + Timer.ElapsedMilliseconds.ToString() + ' milliseconds');
    //Writeln(' Time: ' + Timer.Elapsed.Seconds.ToString() + ' seconds');

    Timer.StartNew;
    //Write('Parallel: ');
    Write(Format('%10e', [ParallelPI]));
    //ParallelPI;
    Timer.Stop;
    //Writeln(' Time: ' + Timer.Elapsed.Seconds.ToString() + ' seconds');
    //Writeln(' Time: ' + Timer.ElapsedMilliseconds.ToString() + ' milliseconds');

    //Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
