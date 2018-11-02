(** @file paex_sine.c
	@ingroup examples_src
	@brief Play a sine wave for several seconds.
	@author Ross Bencina <rossb@audiomulch.com>
    @author Phil Burk <philburk@softsynth.com>
*)
(*
 * $Id$
 *
 * This program uses the PortAudio Portable Audio Library.
 * For more information see: http://www.portaudio.com/
 * Copyright (c) 1999-2000 Ross Bencina and Phil Burk
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *)

(*
 * The text above constitutes the entire PortAudio license; however,
 * the PortAudio community also makes the following non-binding requests:
 *
 * Any person wishing to distribute modifications to the Software is
 * requested to send the modifications to the original developer so that
 * they can be incorporated into the canonical version. It is also
 * requested that these non-binding requests be included along with the
 * license above.
 *)

program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Math,
  portaudio in '..\..\Include\portaudio.pas';

const
  NUM_SECONDS = 5;
  SAMPLE_RATE = 44100;
  FRAMES_PER_BUFFER = 64;
  TABLE_SIZE = 200;

type
  PPaTestData = ^TPaTestData;
  TPaTestData = record
    Sine          : array[0..TABLE_SIZE - 1] of Double;
    left_phase    : integer;
    right_phase   : integer;
    AMessage      : MarshaledAstring;
  end;

var
  LPaError            : TPaError;


(* This routine will be called by the PortAudio engine when audio is needed.
** It may called at interrupt level on some machines so don't do anything
** that could mess up the system like calling malloc() or free().
*)
function PaTestCallback(inputBuffer : pointer; OutputBuffer : pointer;
      framesPerBuffer : longword; timeInfo : PPaStreamCallbackTimeInfo;
      statusFlags : TPaStreamCallbackFlags; UserData : pointer) : integer;
      cdecl;
var
  OutBuffer : PDouble;
  i : longword;
  data : PPaTestData;
begin
  OutBuffer := PDouble(OutputBuffer);
  data := PPaTestData(UserData);

  // Fill the buffer...
  for i := 0 to (FramesPerBuffer-1) do
  begin

    OutBuffer^ := data^.Sine[data^.left_phase];
    Inc(OutBuffer);

    OutBuffer^ := data^.Sine[data^.right_phase];
    Inc(OutBuffer);

    Inc(data^.left_phase, 1);
    if (data^.left_phase >= TABLE_SIZE ) then  data^.left_phase :=  (data^.left_phase - TABLE_SIZE);

    Inc(data^.right_phase, 3);
    if ( data^.right_phase >= TABLE_SIZE ) then data^.right_phase :=  (data^.right_phase - TABLE_SIZE);
  end;

  PaTestCallback := paContinue;
end;

{ This is called when playback is finished.
  Remember: ALWAYS USE CDECL or your pointers will be messed up!
  Pointers to this function must be castable to PPaStreamFinishedCallback: }
procedure StreamFinished( UserData : pointer ); cdecl;
var
  data : PPaTestData;
begin
  data := PPaTestData(UserData);
  WriteLn('Stream Completed: ', UTF8String(data^.AMessage));
end;


procedure Error;
begin
  Pa_Terminate();
  WriteLn('An error occured while using the portaudio Stream');
  WriteLn('Error number: ', LPaError );
  WriteLn('Error message: ', Pa_GetErrorText(LPaError));
  halt;
end;

var
  j                   : integer;
  LPaOutputParameters : TPaStreamParameters;
  LPaStream           : PPaStream;
  Data                : TPaTestData;

begin
  try
    WriteLn('PortAudio Test: Output Sine wave. SR = ', SAMPLE_RATE, ', BufSize = ', FRAMES_PER_BUFFER);

    // Fill a Sine wavetable (Float Data -1 .. +1)
    for j := 0 to TABLE_SIZE-1 do begin
      Data.Sine[j] := double((Sin((j/TABLE_SIZE) * Pi * 2 )));
    end;

    Data.left_phase := 0;
    Data.right_phase := 0;

    LPaError := Pa_Initialize;
    if not LPaError = 0 then Error;

    LPaOutputParameters.Device := Pa_GetDefaultOutputDevice;
    LPaOutputParameters.ChannelCount := 2;
    LPaOutputParameters.SampleFormat := paFloat32;
    LPaOutputParameters.SuggestedLatency := (Pa_GetDeviceInfo(LPaOutputParameters.device)^.defaultHighOutputLatency)*1;
    LPaOutputParameters.HostApiSpecificStreamInfo := nil;

    WriteLn('Latency ', FloatToStr(Pa_GetDeviceInfo(LPaOutputParameters.device)^.defaultHighOutputLatency));

    LPaError := Pa_OpenStream(LPaStream, nil, @LPaOutputParameters, SAMPLE_RATE, FRAMES_PER_BUFFER, paClipOff, @PaTestCallback,  @Data);

    if not LPaError = 0 then Error;

    Data.AMessage := 'No Message'#0;

    LPaError := Pa_SetStreamFinishedCallback(LPaStream, PPaStreamFinishedCallback(@StreamFinished));
    if not LPaError = 0 then Error;

    LPaError := Pa_StartStream(LPaStream);
    if not LPaError = 0 then Error;

    WriteLn('Play for ', NUM_SECONDS, ' seconds.');
    Pa_Sleep( NUM_SECONDS * 1000 );

    LPaError := Pa_StopStream(LPaStream);
    if not LPaError = 0 then Error;

    LPaError := Pa_CloseStream(LPaStream);
    if not LPaError = 0 then Error;

    Pa_Terminate;
    WriteLn('Test finished.');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  readln;
end.
