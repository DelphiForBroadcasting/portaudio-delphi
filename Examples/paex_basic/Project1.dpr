program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  portaudio in '..\..\Include\portaudio.pas';

var
  i : integer;
  LPaHostApiCount: integer;
  LPaHostApiInfo: PPaHostApiInfo;
  LPaError : TPaError;
begin
  try
    WriteLn('PA version int: ', IntToStr(Pa_GetVersion));
    WriteLn('PA version text: ', Pa_GetVersionText);

    // init PA
    LPaError := Pa_Initialize;
    try
      WriteLn('Doing PA init: ', Pa_GetErrorText(LPaError));

      // print some system information provided by PA
      LPaHostApiCount := Pa_GetHostApiCount;
      WriteLn('Host API count (OK if positive): ', IntToStr(LPaHostApiCount));
      WriteLn('Default host API: ', IntToStr(Pa_GetDefaultHostApi));

      for i := 0 to (LPaHostApiCount-1) do begin
        LPaHostApiInfo := Pa_GetHostApiInfo ( i );
        WriteLn('Found host API ', i, ' which is ', UTF8String(LPaHostApiInfo^.name),
            ' (devices: ', IntToStr(LPaHostApiInfo^.deviceCount), ')');
      end;

      WriteLn('Default output device: ', IntToStr(Pa_GetDefaultOutputDevice));

    finally
      LPaError := Pa_Terminate;
      // end all PA activity
      WriteLn('Doing PA termination: ' + Pa_GetErrorText(LPaError));
    end;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  readln;
end.
