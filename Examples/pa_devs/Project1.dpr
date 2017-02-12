(** @file pa_devs.c
	@ingroup examples_src
    @brief List available devices, including device information.
	@author Phil Burk http://www.softsynth.com

    @note Define PA_USE_ASIO=0 to compile this code on Windows without
        ASIO support.
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
  portaudio in '..\..\Include\portaudio.pas';


(*******************************************************************)
procedure PrintSupportedStandardSampleRates(
        const inputParameters: PPaStreamParameters;
        const outputParameters: PPaStreamParameters);
const
  standardSampleRates: array[1..13] of double =
    ( 8000.0,  9600.0,  11025.0,  12000.0,  16000.0,
     22050.0, 24000.0,  32000.0,  44100.0,  48000.0,
     88200.0, 96000.0, 192000.0
    );
var
  err : TPaError;
  i, printCount : integer;
begin
  printCount := 0;

  for  i := 0 to length(standardSampleRates) - 1 do
  begin
    err := Pa_IsFormatSupported( inputParameters, outputParameters, standardSampleRates[i]);
    if( err = paFormatIsSupported ) then
    begin
      if( printCount = 0 ) then
      begin
        write(Format('%8.2f', [standardSampleRates[i]]));
        printCount := 1;
      end else
      if( printCount = 4 ) then
      begin
        writeln;
        write(Format(',%8.2f', [standardSampleRates[i]]));
        printCount := 1;
      end else
      begin
        write(Format(', %8.2f', [standardSampleRates[i]]));
        inc(printCount);
      end;
    end;
  end;

  if printCount = 0 then
    writeln('None')
  else writeln;

end;

label error;

var
  i, numDevices, defaultDisplayed   : integer;
  deviceInfo                        : PPaDeviceInfo;
  inputParameters, outputParameters : TPaStreamParameters;
  err                               : TPaError;
  hostInfo                          : PPaHostApiInfo;
{$IFDEF PA_USE_ASIO}
  minLatency,
  maxLatency,
  preferredLatency,
  granularity                       : longint;
{$ENDIF}
begin
  try
    err := Pa_Initialize();
    if (err <> paNoError) then
    begin
      writeln(Format('ERROR: Pa_Initialize returned 0x%x', [err]));
      goto error;
    end;

    writeln(Format('PortAudio version: 0x%08X', [Pa_GetVersion()]));
    writeln(Format('Version text: %s', [Pa_GetVersionInfo()^.versionText]));

    numDevices := Pa_GetDeviceCount();
    if( numDevices < 0 ) then
    begin
      writeln(Format('ERROR: Pa_GetDeviceCount returned 0x%x', [numDevices]));
      err := numDevices;
      goto error;
    end;


    writeln(Format('Number of devices = %d', [numDevices]));
    for i:=0 to numDevices - 1 do
    begin
      deviceInfo := Pa_GetDeviceInfo(i);
      writeln(Format('--------------------------------------- device #%d', [i]));

      (* Mark global and API specific default devices *)
      defaultDisplayed := 0;
      if i = Pa_GetDefaultInputDevice() then
      begin
        write('[ Default Input');
        defaultDisplayed := 1;
      end else
      if i = Pa_GetHostApiInfo(deviceInfo^.hostApi)^.defaultInputDevice then
      begin
        hostInfo := Pa_GetHostApiInfo(deviceInfo^.hostApi);
        write(Format('[ Default %s Input', [hostInfo^.name]));
        defaultDisplayed := 1;
      end;

      if i = Pa_GetDefaultOutputDevice() then
      begin
        if defaultDisplayed > 0 then
          write(',') else write('[');
        write('Default Output');
        defaultDisplayed := 1;
      end else
      if i = Pa_GetHostApiInfo(deviceInfo^.hostApi )^.defaultOutputDevice then
      begin
        hostInfo := Pa_GetHostApiInfo(deviceInfo^.hostApi);
        if defaultDisplayed > 0 then
          write(',') else write('[');
        write(Format('Default %s Output', [hostInfo^.name]));
        defaultDisplayed := 1;
      end;

      if defaultDisplayed > 0 then
        writeln(' ]');

      (* print device info fields *)

      writeln(Format('Name                        = %s', [deviceInfo^.name]));

      writeln(Format('Host API                    = %s', [Pa_GetHostApiInfo(deviceInfo^.hostApi)^.name]));
      writeln(Format('Max inputs = %d, Max outputs = %d', [deviceInfo^.maxInputChannels, deviceInfo^.maxOutputChannels]));

      writeln(Format('Default low input latency   = %8.4f', [deviceInfo^.defaultLowInputLatency]));
      writeln(Format('Default low output latency  = %8.4f', [deviceInfo^.defaultLowOutputLatency]));
      writeln(Format('Default high input latency  = %8.4f', [deviceInfo^.defaultHighInputLatency]));
      writeln(Format('Default high output latency = %8.4f', [deviceInfo^.defaultHighOutputLatency]));


{$IFDEF PA_USE_ASIO}
      (* ASIO specific latency information *)
      if( Pa_GetHostApiInfo(deviceInfo^.hostApi)^.typeId = paASIO ) then
      begin
        minLatency, maxLatency, preferredLatency, granularity;

        err := PaAsio_GetAvailableLatencyValues(i, @minLatency, @maxLatency, @preferredLatency, @granularity);

        writeln(Format('ASIO minimum buffer size    = %ld', [minLatency]));
        writeln(Format('ASIO maximum buffer size    = %ld', [maxLatency]));
        writeln(Format('ASIO preferred buffer size  = %ld', [preferredLatency]));

        if( granularity = -1 ) then
          writeln(Format('ASIO buffer granularity     = power of 2');
        else
          writeln(Format('ASIO buffer granularity     = %ld', [granularity]));
      end;
{$ENDIF} (* PA_USE_ASIO *)

      writeln(Format('Default sample rate         = %8.2f', [deviceInfo^.defaultSampleRate]));

      (* poll for standard sample rates *)
      inputParameters.device := i;
      inputParameters.channelCount := deviceInfo^.maxInputChannels;
      inputParameters.sampleFormat := paInt16;
      inputParameters.suggestedLatency := 0; (* ignored by Pa_IsFormatSupported() *)
      inputParameters.hostApiSpecificStreamInfo := nil;

      outputParameters.device := i;
      outputParameters.channelCount := deviceInfo^.maxOutputChannels;
      outputParameters.sampleFormat := paInt16;
      outputParameters.suggestedLatency := 0; (* ignored by Pa_IsFormatSupported() *)
      outputParameters.hostApiSpecificStreamInfo := nil;

      if (inputParameters.channelCount > 0) then
      begin
        writeln('Supported standard sample rates');
        writeln(Format('for half-duplex 16 bit %d channel input = ', [inputParameters.channelCount]));
        PrintSupportedStandardSampleRates(@inputParameters, nil);
      end;

      if (outputParameters.channelCount > 0) then
      begin
        writeln('Supported standard sample rates');
        writeln(Format('for half-duplex 16 bit %d channel output = ', [outputParameters.channelCount]));
        PrintSupportedStandardSampleRates(nil, @outputParameters);
      end;

      if ((inputParameters.channelCount > 0) and (outputParameters.channelCount > 0)) then
      begin
        writeln('Supported standard sample rates');
        writeln(Format('for full-duplex 16 bit %d channel input, %d channel output = ', [inputParameters.channelCount, outputParameters.channelCount]));
        PrintSupportedStandardSampleRates(@inputParameters, @outputParameters);
      end;
    end;


    Pa_Terminate();

    writeln('----------------------------------------------');
    readln;
    exit;

    error:
      Pa_Terminate();
      writeln(Format('Error number: %d', [err]));
      writeln(Format('Error message: %s', [Pa_GetErrorText(err)]));


  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
