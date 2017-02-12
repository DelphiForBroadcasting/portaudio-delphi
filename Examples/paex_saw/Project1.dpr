(** @file paex_saw.c
	@ingroup examples_src
	@brief Play a simple (aliasing) sawtooth wave.
	@author Phil Burk  http://www.softsynth.com
*)
(*
 * $Id$
 *
 * This program uses the PortAudio Portable Audio Library.
 * For more information see: http://www.portaudio.com
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
  NUM_SECONDS = 4;
  SAMPLE_RATE = 44100;


type
  PPaTestData = ^TPaTestData;
  TPaTestData = record
    left_phase   : double;
    right_phase  : double;
  end;

var
  LPaStream   : PPaStream;
  LPaError    : TPaError;
  Data        : TPaTestData;

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
  i         : integer;
  data      : PPaTestData;
begin
  OutBuffer := PDouble(OutputBuffer);
  data := PPaTestData(UserData);

  // Fill the buffer...
  for i := 0 to (FramesPerBuffer-1) do
  begin
    OutBuffer^ := data^.left_phase;
    Inc(OutBuffer);

    OutBuffer^ := data^.right_phase;
    Inc(OutBuffer);

    data^.left_phase := data^.left_phase + 0.1;
    if (data^.left_phase >= 1.0 ) then data^.left_phase :=  data^.left_phase - 2.0;

    data^.right_phase := data^.right_phase + 0.3;
    if ( data^.right_phase >= 1.0 ) then data^.right_phase :=  data^.right_phase - 2.0;
  end;

  result := paContinue;
end;

procedure Error;
begin
  Pa_Terminate();
  WriteLn('An error occured while using the portaudio Stream');
  WriteLn('Error number: ', LPaError );
  WriteLn('Error message: ', Pa_GetErrorText(LPaError));
  halt;
end;


begin
  try
    WriteLn('PortAudio Test: output sawtooth wave.');

    Data.left_phase := 0;
    Data.right_phase := 0;

    LPaError := Pa_Initialize;
    if not LPaError = 0 then Error;

    LPaError := Pa_OpenDefaultStream(LPaStream, 0, 2, paFloat32, SAMPLE_RATE, 256, @PaTestCallback,  @Data);
    if not LPaError = 0 then Error;

    LPaError := Pa_StartStream(LPaStream);
    if not LPaError = 0 then Error;

    Pa_Sleep(NUM_SECONDS * 1000 );

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
