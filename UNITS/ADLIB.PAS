{
  AdLib FM synthesiser interface utility unit
  Part of Posit-92 game framework
  Some parts are adapted from ccodere/pascal-adlib's GitHub repo

  20-06-2025: The current version doesn't support playing percussion alongside melodic mode
}

{$DEFINE DEBUG}
{ TODO: Adapt the old instrument to the new one }
{ TODO: Implement TVoice, which handles the melody & drum scheduling }

unit AdLib;

interface

const
  { Internal chip values for notes }
  NOTE_C  = $157;
  NOTE_CS = $16B;
  NOTE_D  = $181;
  NOTE_DS = $198;
  NOTE_E  = $1B0;
  
  NOTE_F  = $1CA;
  NOTE_FS = $1E5;
  NOTE_G = $202;
  NOTE_GS = $220;
  NOTE_A = $241;
  NOTE_AS = $263;
  NOTE_B = $287;

  
type
  TNote = record
    freq: word;
    octave: byte;
    duration: double;  { in seconds }
    velocity: byte  { 0..127 }
  end;

  PMelody = ^TMelody;
  TMelody = record
    notes: array[0..15] of TNote;
    noteCount: byte;
    instrument: byte;
  end;

  TInstrParams = record
    tremolo: boolean;
    vibrato: boolean;
    sustain: boolean;
    keyScale: boolean;
    multiplier: byte;
    totalLevel: byte; { octaves? }
    attackRate, decayRate: byte;
    sustainRate, releaseRate: byte;
    waveform: byte;
  end;
  PInstrument = ^TInstrument;
  TInstrument = record
    modulator: TInstrParams;
    carrier: TInstrParams;
    feedback: byte;
    algorithm: byte;  { 0 = FM, 1 = Additive }
  end;

  { TODO: Write an adapter to TInstrument }
  { Note: Don't use this, use TInstrument instead }
  TOldInstrument = Record
    WaveChar: Byte;       { Wave Characteristic          }
    ScalingOutput: Byte;  { Scaling Level / Output level }
    AttackDecay: Byte;    { Attack / Decay Rate          }
    SustainRelease: Byte; { Sustain / Release Rate       }
    Feedback: Byte;       { Feedback                     }
    SetWaveSelect: Byte;  { Type of Wave to use          }
  end;

  PAdLibDriver = ^TAdLibDriver;
  TAdLibDriver = object
    SemiToneCurrent: Array[0..10] of Integer;
    Function CalcNote(const Voice, Note: byte): Word;

    function getIsInitialised: boolean;
    procedure init;
    procedure update;
    procedure shutdown;
    procedure setPercussive(const value: boolean);

    procedure loadInstrument(const instrSlot: byte; const instr: PInstrument);
    procedure selectInstrument(const voice, instrSlot: byte);
    procedure assignInstrument(const voice: byte; const instr: PInstrument);

    procedure setupMelodicInstruments;
    procedure setupRhythmInstruments;

    { Playback }
    procedure playNote(const voice: byte; const freq: word; const octave, velocity: byte);
    procedure stopVoice(const voice: byte);

    procedure drumOn(const voice, note: byte);
    procedure drumOff(const voice: byte);

    procedure playMelodyNoInstrument(const melody: PMelody; const voice: byte);
    procedure playMelody(const melody: PMelody; const voice: byte);
    procedure stopAllVoices;

    procedure drawDebug;
  end;

const 
  BassDrumVoice = 6;
  SnareDrumVoice = 7;
  TomTomVoice = 8;
  CymbalVoice = 9;
  HiHatVoice = 10;

var
  AdLibDrv: TAdLibDriver;

procedure initNote(
  var note: TNote;
  const freq: word;
  const octave: byte;
  const duration: double;
  const velocity: byte);

procedure AdLibWrite(const reg, value: byte);


implementation

uses
  CRT,
  Conv, Logger, Panic, Timing, VGA;

type
  TVoiceState = record
    active: boolean;
    melody: PMelody;
    noteIndex: byte;
    noteEndTick: double; { in seconds }
    instrument: PInstrument;
    volume: byte; { 0..127 }
  end;

const
  AddressPort = $388;  { Address / status port }
  StatusPort = $388;
  DataPort = $389;  { Data port }

  MAX_MELODIC_VOICES = 9; { indices 0..8 }
  MAX_PERCUSSIVE_VOICES = 6; { for melodies: indices 0..5, percussions: 6, 7, 8 }
  MAX_INSTRUMENTS = 16; { indices 0..15 }

  BassDrumBit = $10;
  SnareDrumBit = $08;
  TomTomBit = $04;
  CymbalBit = $02;
  HiHatBit = $01;

  PercussionBits: array[0..4] of byte =
    { $10, $08, $04, $02, $01 }
    (BassDrumBit, SnareDrumBit, TomTomBit, CymbalBit, HiHatBit);


var
  isInitialised: boolean;
  isPercussiveMode: boolean;
  BDRegister: byte;
  voices: array[0..MAX_MELODIC_VOICES-1] of TVoiceState;
  instruments: array[0..MAX_INSTRUMENTS-1] of PInstrument;


procedure AdLibWrite(const reg, value: byte);
var
  a: byte;
begin
  Port[AddressPort] := reg;
  for a:=1 to 3 do;  { simulated delay }
  Port[DataPort] := value;
  for a:=1 to 12 do;  { simulated delay }
end;

{
  freq uses NOTE_ prefix
  octave is the same as "block" in AdLib
  duration is in seconds
  velocity: 0..127
}
procedure initNote(
  var note: TNote;
  const freq: word;
  const octave: byte;
  const duration: double;
  const velocity: byte);
begin
  note.freq := freq;
  note.octave := octave;
  note.duration := duration;
  note.velocity := velocity;
end;

function getModulatorOffset(const voice: byte): byte;
const
  offsets: array[0..8] of byte = (
    $00, $01, $02,
    $08, $09, $0A,
    $10, $11, $12
  );
begin
  getModulatorOffset := offsets[voice]
end;

function getCarrierOffset(const voice: byte): byte;
const
  offsets: array[0..8] of byte = (
    $03, $04, $05,
    $0B, $0C, $0D,
    $13, $14, $15
  );
begin
  getCarrierOffset := offsets[voice]
end;


procedure TAdLibDriver.assignInstrument(const voice: byte; const instr: PInstrument);
var
  { modulator & carrier offsets }
  modOffset, carOffset: byte;
begin
  if instr = nil then panicHalt('assignInstrument: instr is nil!');
  
  modOffset := getModulatorOffset(voice);
  carOffset := getCarrierOffset(voice);

  { Set up modulator }
  with instr^.modulator do begin
    AdLibWrite($20 + modOffset,
      (ord(tremolo) shl 7) or
      (ord(vibrato) shl 6) or
      (ord(sustain) shl 5) or
      (ord(keyScale) shl 4) or multiplier);
      
    AdLibWrite($40 + modOffset, (ord(keyScale) and 1) shl 6 or totalLevel);
    AdLibWrite($60 + modOffset, (attackRate shl 4) or decayRate);
    AdLibWrite($80 + modOffset, (sustainRate shl 4) or releaseRate);
    AdLibWrite($e0 + modOffset, waveform)
  end;
  
  { Set up carrier }
  with instr^.carrier do begin
    AdLibWrite($20 + carOffset,
      (ord(tremolo) shl 7) or
      (ord(vibrato) shl 6) or
      (ord(sustain) shl 5) or
      (ord(keyScale) shl 4) or multiplier);
      
    AdLibWrite($40 + carOffset, (ord(keyScale) and 1) shl 6 or totalLevel);
    AdLibWrite($60 + carOffset, (attackRate shl 4) or decayRate);
    AdLibWrite($80 + carOffset, (sustainRate shl 4) or releaseRate);
    AdLibWrite($e0 + carOffset, waveform)
  end;
  
  { Set algorithm and feedback }
  AdLibWrite(
    $C0 + voice,
    (instr^.feedback shl 1) or instr^.algorithm)
end;

{ Loads a PInstrument to a slot }
{ TODO: reduce this into something like assignInstrument }
procedure TAdLibDriver.loadInstrument(const instrSlot: byte; const instr: PInstrument);
begin
  if instr = nil then panicHalt('TAdLibDriver.loadInstrument: Attempting to load a nil instrument');
  if instrSlot >= MAX_INSTRUMENTS then exit;

  instruments[instrSlot] := instr
end;

{ TODO: reduce this into something like assignInstrument }
procedure TAdLibDriver.selectInstrument(const voice, instrSlot: byte);
begin
  if voice >= MAX_MELODIC_VOICES then exit;
  if instrSlot >= MAX_INSTRUMENTS then exit;

  voices[voice].instrument := instrSlot;
  assignInstrument(voice, instruments[instrSlot])
end;


procedure resetAllRegisters;
var
  a: byte;
begin
  for a := $20 to $F5 do
    AdLibWrite(a, 0);
end;


function TAdLibDriver.getIsInitialised: boolean;
begin
  getIsInitialised := isInitialised
end;


{ Adapted from ccodere/pascal-adlib's GitHub repo }
procedure TAdLibDriver.setPercussive(const value: boolean);
begin
  isPercussiveMode := value;

{$IFDEF DEBUG}
  writeLog('Changed percussive mode to ' + boolStr(value));
{$ENDIF}

  if value then begin
    { Skipped MaxVoices value }
    BDRegister := $E0;
    AdLibWrite($BD, BDRegister);
    setupRhythmInstruments;
  end else begin
    BDRegister := $C0;
    AdLibWrite($BD, BDRegister);
    setupMelodicInstruments;
  end;
end;

procedure convertOldInstrument(var output: TInstrument; var src: TOldInstrument);
begin
  with output.modulator do begin
    tremolo := (src.WaveChar and $80) <> 0;  { bit 7 }
    vibrato := (src.WaveChar and $40) <> 0;  { bit 6 }
    sustain := (src.WaveChar and $20) <> 0;  { bit 5 }
    keyScale := (src.WaveChar and $10) <> 0;  { bit 4: key scale rate }
    multiplier := src.WaveChar and $0F;  { bits 0-3: frequency multiplier }

    attackRate := hi(src.AttackDecay);
    decayRate := lo(src.AttackDecay);
    sustainRate := hi(src.SustainRelease);
    releaseRate := lo(src.SustainRelease);
    waveform := src.SetWaveSelect and $07; { waveform select }
  end;

  with output.carrier do begin
    tremolo := (src.WaveChar and $80) <> 0;  { bit 7 }
    vibrato := (src.WaveChar and $40) <> 0;  { bit 6 }
    sustain := (src.WaveChar and $20) <> 0;  { bit 5 }
    keyScale := (src.WaveChar and $10) <> 0;  { bit 4: key scale rate }
    multiplier := src.WaveChar and $0F;  { bits 0-3: frequency multiplier }

    attackRate := hi(src.AttackDecay);
    decayRate := lo(src.AttackDecay);
    sustainRate := hi(src.SustainRelease);
    releaseRate := lo(src.SustainRelease);
    waveform := src.SetWaveSelect and $07; { waveform select }
  end;

  output.modulator.totalLevel := 25;  { octaves? }
  output.carrier.totalLevel := 0;

  output.feedback := (src.Feedback and $0E) shr 1;  { bits 1-3 }
  output.algorithm := src.Feedback and $01;
end;



{ Assigns all voices with the electric piano preset }
procedure TAdLibDriver.setupMelodicInstruments;
const
  OpModulator: array[0..13] of byte = (
    $00, $01, $02, $08, $09, $0a,
    $10, $11, $12, $01, $11, $4f,
    $00, $f1);
  { Todo: adapt this with the TInstrument format }
  OldElectricPiano: array[0..1] of TOldInstrument = (
  (
    WaveChar: 65; ScalingOutput: 127;
    AttackDecay: 242; SustainRelease: 81;
    FeedBack: 7; SetWaveSelect: 1),

  (
    WaveChar: 19; ScalingOutput: 0;
    AttackDecay: 242; SustainRelease: 241;
    FeedBack: 0; SetWaveSelect: 0));
var
  voice, op, portOffset: byte;
begin
  for voice:=0 to MAX_MELODIC_VOICES do begin
    { 0: Modulator, 1: Carrier }
    for op:=0 to 1 do begin
      if op = 0 then portOffset := 0 else portOffset := 3;

      AdLibWrite($20 + portOffset + OpModulator[voice],
        OldElectricPiano[op].WaveChar);

      AdLibWrite($40 + portOffset + OpModulator[voice],
        OldElectricPiano[op].ScalingOutput);

      AdLibWrite($60 + portOffset + OpModulator[voice],
        OldElectricPiano[op].AttackDecay);

      AdLibWrite($80 + portOffset + OpModulator[voice],
        OldElectricPiano[op].SustainRelease);

      AdLibWrite($E0 + portOffset + OpModulator[voice],
        OldElectricPiano[op].SetWaveSelect);
    end;

    AdLibWrite($C0 + voice, OldElectricPiano[0].FeedBack)
  end;
end;


procedure TAdLibDriver.setupRhythmInstruments;
const
  OpModulator: array[0..10] of byte = (
    $F2, $53, $74, $00, $00, $08,
    $10, $14, $12, $15, $11
  );

  { PERCUSSIVE MODE VOICES }
  { TODO: Adapt this with the TInstrument format }
  BassDrum:array[0..1] of TOldInstrument = (
    (WaveChar: 0; ScalingOutput: 11;
      AttackDecay: 168; SustainRelease: 76;
      FeedBack: 1; SetWaveSelect: 1),
    (WaveChar: 0; ScalingOutput: 0;
      AttackDecay: 214; SustainRelease: 79;
      FeedBack: 1; SetWaveSelect: 0));

  InstrArray:Array[7..10] of TOldInstrument =
  (* SnareDrum Instrument *)
  ((
    WaveChar:12; ScalingOutput: 0;
    AttackDecay: 248; SustainRelease: 181;
    FeedBack: 0; SetWaveSelect: 0),

  (* TomTom Voice instrument *)
  (WaveChar: 4; ScalingOutput: 0;
    AttackDecay: 247; SustainRelease: 181;
    FeedBack: 0; SetWaveSelect: 0),
  (* Cymbal Voice Instrument *)
  (WaveChar: 1; ScalingOutput: 0;
    AttackDecay: 245; SustainRelease: 181;
    FeedBack: 0; SetWaveSelect: 0),
  (* hihat Voice Instrument *)
  (WaveChar: 1; ScalingOutput: 0;
    AttackDecay: 247; SustainRelease: 181;
    FeedBack: 0; SetWaveSelect: 0));

var
  a, opOffset: byte;

begin
  { Skipped Carrier up to Volume array accesses }

  opOffset := OpModulator[BassDrumVoice];

  { Modulator }
  with BassDrum[0] do begin
    AdLibWrite(opOffset + $20, WaveChar);
    AdLibWrite(opOffset + $40, ScalingOutput);
    AdLibWrite(opOffset + $60, AttackDecay);
    AdLibWrite(opOffset + $80, SustainRelease);
    AdLibWrite(BassDrumVoice + $C0, Feedback);
    AdLibWrite(opOffset + $E0, SetWaveSelect);
  end;

  { Carrier }
  with BassDrum[1] do begin
    AdLibWrite(opOffset + $23, WaveChar);
    AdLibWrite(opOffset + $43, ScalingOutput);
    AdLibWrite(opOffset + $63, AttackDecay);
    AdLibWrite(opOffset + $83, SustainRelease);
    AdLibWrite(opOffset + $E3, SetWaveSelect);
  end;
  
  { The other percussive voices only have one operator }
  for a:=SnareDrumVoice to HiHatVoice do begin
    opOffset := OpModulator[a];
    AdLibWrite(opOffset + $20, InstrArray[a].WaveChar);
    AdLibWrite(opOffset + $40, InstrArray[a].ScalingOutput);
    AdLibWrite(opOffset + $60, InstrArray[a].AttackDecay);
    AdLibWrite(opOffset + $80, InstrArray[a].SustainRelease);
    AdLibWrite(a + $C0, InstrArray[a].Feedback);
    AdLibWrite(opOffset + $E0, InstrArray[a].SetWaveSelect);
  end;
end;


{ Adapted from BoardInstalled from ccodere/pascal-adlib }
function checkAdLib: boolean;
var
  status1, status2: integer;
begin
  AdLibWrite($04, $60);  { Reset both timers }
  AdLibWrite($04, $80);  { Enable timer interrupts }
  status1 := Port[StatusPort];

  AdLibWrite($02, $FF);
  AdLibWrite($04, $21);  { Start timer 21h }
  delay(100);  { Important }

  status2 := Port[StatusPort];
  AdLibWrite($04, $60);  { Reset both timers }
  AdLibWrite($04, $80);  { Enable timer interrupts }

  status1 := status1 and $E0;
  status2 := status2 and $E0;
  checkAdLib := (status1 = $00) and (status2 = $C0)
end;


{ Taken from ccodere/pascal-adlib's GitHub repo }
const
  NoteTab: array[0..126] of byte = (
    $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,
    $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,
    $10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B,
    $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2A,$2B,
    $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,
    $40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,
    $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A,$5B,
    $60,$61,$62,$63,$64,$65,$66,$67,$69,$6A,$6B,
    $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,
    $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,
    $7B,$7B,$7B,$7B,$7B,$7B,$7B,$7B);

  FreqTable: array[0..767] of byte = (
    Ord('W'),
    $01,$58,$01,$58,$01,$59,
    $01,$59,$01,$5a,$01,$5b,
    $01,$5b,$01,$5c,$01,$5d,
    $01,$5d,$01,$5e,$01,$5e,
    $01,$5f,$01,$60,$01,$60,
    $01,$61,$01,$62,$01,$62,
    $01,$63,$01,$64,$01,$64,
    $01,$65,$01,$65,$01,$66,
    $01,$67,$01,$67,$01,$68,
    $01,$69,$01,$69,$01,$6a,
    $01,$6b,$01,$6b,$01,$6c,
    $01,$6d,$01,$6d,$01,$6e,
    $01,$6f,$01,$6f,$01,$70,
    $01,$71,$01,$71,$01,$72,
    $01,$73,$01,$73,$01,$74,
    $01,$75,$01,$75,$01,$76,
    $01,$77,$01,$77,$01,$78,
    $01,$79,$01,$79,$01,$7a,
    $01,$7b,$01,$7b,$01,$7c,
    $01,$7d,$01,$7d,$01,$7e,
    $01,$7f,$01,$80,$01,$80,
    $01,$81,$01,$82,$01,$82,
    $01,$83,$01,$84,$01,$84,
    $01,$85,$01,$86,$01,$87,
    $01,$87,$01,$88,$01,$89,
    $01,$89,$01,$8a,$01,$8b,
    $01,$8b,$01,$8c,$01,$8d,
    $01,$8e,$01,$8e,$01,$8f,
    $01,$90,$01,$91,$01,$91,
    $01,$92,$01,$93,$01,$93,
    $01,$94,$01,$95,$01,$96,
    $01,$96,$01,$97,$01,$98,
    $01,$99,$01,$99,$01,$9a,
    $01,$9b,$01,$9c,$01,$9c,
    $01,$9d,$01,$9e,$01,$9e,
    $01,$09f,$01,$0a0,$01,$0a1,
    $01,$0a1,$01,$0a2,$01,$0a3,
    $01,$0a4,$01,$0a5,$01,$0a5,
    $01,$0a6,$01,$0a7,$01,$0a8,
    $01,$0a8,$01,$0a9,$01,$0aa,
    $01,$0ab,$01,$0ab,$01,$0ac,
    $01,$0ad,$01,$0ae,$01,$0ae,
    $01,$0af,$01,$0b0,$01,$0b1,
    $01,$0b2,$01,$0b2,$01,$0b3,
    $01,$0b4,$01,$0b5,$01,$0b6,
    $01,$0b6,$01,$0b7,$01,$0b8,
    $01,$0b9,$01,$0ba,$01,$0ba,
    $01,$0bb,$01,$0bc,$01,$0bd,
    $01,$0be,$01,$0be,$01,$0bf,
    $01,$0c0,$01,$0c1,$01,$0c2,
    $01,$0c2,$01,$0c3,$01,$0c4,
    $01,$0c5,$01,$0c6,$01,$0c6,
    $01,$0c7,$01,$0c8,$01,$0c9,
    $01,$0ca,$01,$0cb,$01,$0cb,
    $01,$0cc,$01,$0cd,$01,$0ce,
    $01,$0cf,$01,$0d0,$01,$0d0,
    $01,$0d1,$01,$0d2,$01,$0d3,
    $01,$0d4,$01,$0d5,$01,$0d5,
    $01,$0d6,$01,$0d7,$01,$0d8,
    $01,$0d9,$01,$0da,$01,$0db,
    $01,$0db,$01,$0dc,$01,$0dd,
    $01,$0de,$01,$0df,$01,$0e0,
    $01,$0e1,$01,$0e1,$01,$0e2,
    $01,$0e3,$01,$0e4,$01,$0e5,
    $01,$0e6,$01,$0e7,$01,$0e8,
    $01,$0e8,$01,$0e9,$01,$0ea,
    $01,$0eb,$01,$0ec,$01,$0ed,
    $01,$0ee,$01,$0ef,$01,$0f0,
    $01,$0f0,$01,$0f1,$01,$0f2,
    $01,$0f3,$01,$0f4,$01,$0f5,
    $01,$0f6,$01,$0f7,$01,$0f8,
    $01,$0f9,$01,$0fa,$01,$0fa,
    $01,$0fb,$01,$0fc,$01,$0fd,
    $01,$0fe,$01,$0ff,$01,$00,
    $02,$01,$02,$02,$02,$03,
    $02,$04,$02,$05,$02,$06,
    $02,$06,$02,$07,$02,$08,
    $02,$09,$02,$0a,$02,$0b,
    $02,$0c,$02,$0d,$02,$0e,
    $02,$0f,$02,$10,$02,$11,
    $02,$12,$02,$13,$02,$14,
    $02,$15,$02,$16,$02,$17,
    $02,$18,$02,$19,$02,$1a,
    $02,$1a,$02,$1b,$02,$1c,
    $02,$1d,$02,$1e,$02,$1f,
    $02,$20,$02,$21,$02,$22,
    $02,$23,$02,$24,$02,$25,
    $02,$26,$02,$27,$02,$28,
    $02,$29,$02,$2a,$02,$2b,
    $02,$2c,$02,$2d,$02,$2e,
    $02,$2f,$02,$30,$02,$31,
    $02,$32,$02,$33,$02,$34,
    $02,$35,$02,$36,$02,$37,
    $02,$38,$02,$39,$02,$3b,
    $02,$3c,$02,$3d,$02,$3e,
    $02,$3f,$02,$40,$02,$41,
    $02,$42,$02,$43,$02,$44,
    $02,$45,$02,$46,$02,$47,
    $02,$48,$02,$49,$02,$4a,
    $02,$4b,$02,$4c,$02,$4d,
    $02,$4e,$02,$4f,$02,$51,
    $02,$52,$02,$53,$02,$54,
    $02,$55,$02,$56,$02,$57,
    $02,$58,$02,$59,$02,$5a,
    $02,$5b,$02,$5c,$02,$5e,
    $02,$5f,$02,$60,$02,$61,
    $02,$62,$02,$63,$02,$64,
    $02,$65,$02,$66,$02,$67,
    $02,$69,$02,$6a,$02,$6b,
    $02,$6c,$02,$6d,$02,$6e,
    $02,$6f,$02,$70,$02,$72,
    $02,$73,$02,$74,$02,$75,
    $02,$76,$02,$77,$02,$78,
    $02,$79,$02,$7b,$02,$7c,
    $02,$7d,$02,$7e,$02,$7f,
    $02,$80,$02,$82,$02,$83,
    $02,$84,$02,$85,$02,$86,
    $02,$87,$02,$89,$02,$8a,
    $02,$8b,$02,$8c,$02,$8d,
    $02,$8e,$02,$90,$02,$91,
    $02,$92,$02,$93,$02,$94,
    $02,$96,$02,$97,$02,$98,
    $02,$99,$02,$9a,$02,$9c,
    $02,$9d,$02,$9e,$02,$09f,
    $02,$0a0,$02,$0a2,$02,$0a3,
    $02,$0a4,$02,$0a5,$02,$0a6,
    $02,$0a8,$02,$0a9,$02,$0aa,
    $02,$0ab,$02,$0ad,$02);


Function TAdLibDriver.CalcNote(const Voice, Note: byte): Word; Assembler;
(* Calculate the note to output to A0 and B0 registers *)
(* Taken directly from the SBlaster FM Driver          *)
(* Possible value is from 0 to 127                     *)
ASM
    Xor     Ax, Ax
    Xor     Bx, Bx
    LES     SI, [Self]

    Mov     Bl, [Voice]
    Mov     Al,Byte Ptr [Note]
    Cbw
    Xor     Di, Di
    Add     Di,Ax
    Jns     @b06c12
    Sub     Di,Di

@b06c12:
    And     Di,7fh
    Mov     Al,Byte Ptr NoteTab[Di]
    Mov     Dl,Al
    And     Dl,70h
    Shr     Dl,1
    Shr     Dl,1
    And     Al,0fh
    Cbw
    Xchg    Al,Ah
    Shr     Ax,1
    Shr     Ax,1
    Shr     Ax,1
    Shl     Bx,1
    Add     Ax,Word ptr ES:[SI].SemiToneCurrent[Bx]
    Jns     @b06c43
    Add     Ax,0180h
    Sub     Dl,04
    Jns     @b06c58
    Sub     Dl,Dl
    Sub     Ax,Ax
    Jmp     @b06c58

@b06c43:
    Cmp     Ax,0180h
    Jb      @b06c58
    Sub     Ax,0180h
    Add     Dl,04
    Cmp     Dl,1ch
    Jnb     @b06c58
    Mov     Ax,017fh
    Mov     Dl,1ch

{ This area returns the value }
@b06c58:
    Shl     Ax,1
    Mov     Di,Ax
    Mov     Ax,Word Ptr FreqTable[Di]
    Or      Ah,Dl
end;


function isVoiceMelodic(const voice: byte): boolean;
begin
  isVoiceMelodic := (isPercussiveMode and (voice < BassDrumVoice)) or
    (not isPercussiveMode)
end;

{ low-level interface, doesn't change the `active` flag }
procedure melodicKeyOn(const voice, freqLow, freqHigh: byte);
var
  isMelodic: boolean;
begin
  if voice >= MAX_MELODIC_VOICES then exit;

  isMelodic := isVoiceMelodic(voice);

  if isMelodic then begin
    AdLibWrite($A0 + voice, freqLow); { low byte of frequency }
    AdLibWrite($B0 + voice, freqHigh or $20) { high byte + key-on flag }
  end;
end;


{ low-level interface, doesn't change the `active` flag }
procedure melodicKeyOff(const voice: byte);
var
  isMelodic: boolean;
begin
  if voice >= MAX_MELODIC_VOICES then exit;

  isMelodic := isVoiceMelodic(voice);

  if isMelodic then
    AdLibWrite($B0 + voice, 0);
end;


procedure TAdLibDriver.drumOn(const voice, note: byte);
const
  PercussiveOffset: array[0..10] of byte = (
    $11, $10, $08, $04, $02, $01,
    $06, $07, $08, $08, $07);
var
  output: word;
begin
  if not isPercussiveMode then exit;

  BDRegister := BDRegister OR PercussionBits[Voice - 6];
  output := CalcNote(voice, note);
  AdLibWrite($A0 + PercussiveOffset[Voice], lo(output));
  AdLibWrite($B0 + PercussiveOffset[Voice], hi(output));

  AdLibWrite($BD, BDRegister);
end;


procedure TAdLibDriver.drumOff(const voice: byte);
begin
  if not isPercussiveMode then exit;

  BDRegister := BDRegister AND (NOT PercussionBits[Voice - 6]);
  AdLibWrite($BD, BDRegister);
end;


procedure TAdLibDriver.init;
var
  a: byte;
begin
  if isInitialised then exit;

  if not checkAdLib then begin
    writeLog('TAdLibDriver.init: Can''t find the AdLib card!');
    exit
  end;

  resetAllRegisters;

  { Let us decide which waveforms we wish to have }
  AdLibWrite($01, $20);
  { Set key-scaling to ON }
  AdLibWrite($08, $40);
  
  for a := 0 to MAX_MELODIC_VOICES-1 do begin
    voices[a].active := false;
    voices[a].melody := nil;
    voices[a].noteIndex := 0;
    voices[a].noteEndTick := 0;
    voices[a].instrument := 0;
    voices[a].volume := 127
  end;

  { Select SINUS Waves for Output }
  for a:=0 to 8 do begin
    {
    AdLibWrite($E0 + SlotMVoice[i][Modulator], $00);
    AdLibWrite($E0 + SlotMVoice[i][Carrier], $00);
    }
    AdLibWrite($E0 + getModulatorOffset(a), $00);
    AdLibWrite($E0 + getCarrierOffset(a), $00);
  end;
  
  isInitialised := true;

  setPercussive(false);
end;

procedure TAdLibDriver.playNote(
  const voice: byte;
  const freq: word;
  const octave, velocity: byte);
var
  volume: byte;
  carrierOffset: byte;
begin
  if voice >= MAX_MELODIC_VOICES then exit;

  carrierOffset := getCarrierOffset(voice);

  volume := (velocity * voices[voice].volume) div 127;

  { Important: Don't delete this! }
  {
  with instruments[voices[voice].instrument]^.carrier do
    AdLibWrite($40 + carrierOffset, ($3F - (volume div 2)) and $3F);
  }
  AdLibWrite($40 + carrierOffset, ($3F - (volume div 2)) and $3F);

  melodicKeyOn(
    voice,
    lo(freq),
    (hi(freq) and $03) or (octave shl 2))
end;

procedure TAdLibDriver.stopVoice(const voice: byte);
begin
  if voice >= MAX_MELODIC_VOICES then exit;

  { AdLibWrite($B0 + voice, 0); }
  melodicKeyOff(voice);
  voices[voice].active := false
end;

procedure TAdLibDriver.stopAllVoices;
var
  a: byte;
begin
  for a:=0 to MAX_MELODIC_VOICES - 1 do
    stopVoice(a);
end;


procedure TAdLibDriver.playMelodyNoInstrument(const melody: PMelody; const voice: byte);
var
  found: boolean;
begin
  stopVoice(voice);

  if melody = nil then panicHalt('TAdLibDriver.playMelody: Attempting to play a nil melody!');
  
  voices[voice].active := true;
  voices[voice].melody := melody;
  voices[voice].noteIndex := 0;
  voices[voice].noteEndTick := getTimer + melody^.notes[0].duration;
  { voices[voice].instrument := melody^.instrument; }

  { assignInstrument(voice, instruments[melody^.instrument]); }
  playNote(
    voice,
    melody^.notes[0].freq,
    melody^.notes[0].octave,
    melody^.notes[0].velocity)
end;

procedure TAdLibDriver.playMelody(const melody: PMelody; const voice: byte);
var
  found: boolean;
begin
  stopVoice(voice);

  if melody = nil then panicHalt('TAdLibDriver.playMelody: Attempting to play a nil melody!');
  
  voices[voice].active := true;
  voices[voice].melody := melody;
  voices[voice].noteIndex := 0;
  voices[voice].noteEndTick := getTimer + melody^.notes[0].duration;
  voices[voice].instrument := melody^.instrument;

  assignInstrument(voice, instruments[melody^.instrument]);
  playNote(
    voice,
    melody^.notes[0].freq,
    melody^.notes[0].octave,
    melody^.notes[0].velocity)
end;


procedure TAdLibDriver.update;
var
  a: byte;
  now: double;
begin
  if not isInitialised then exit;
  
  now := getTimer;
  
  for a:=0 to MAX_MELODIC_VOICES-1 do begin
    if not voices[a].active then continue;
    
    if now >= voices[a].noteEndTick then begin
      melodicKeyOff(a);
      inc(voices[a].noteIndex);
      
      if voices[a].noteIndex >= voices[a].melody^.noteCount then begin
        voices[a].active := false;
        continue
      end;
      
      with voices[a].melody^.notes[voices[a].noteIndex] do begin
        playNote(a, freq, octave, velocity);
        voices[a].noteEndTick := now + duration
      end;
    end;
  end;
end;


procedure TAdLibDriver.drawDebug;
begin
  if not isInitialised then begin
    asmPrint('AdLib is not initialised!', 0, 0, 7);
    exit
  end;

  asmPrint('$BD: ' + i32str(BDRegister), 0, 8, 7);
end;


procedure TAdLibDriver.shutdown;
begin
  if not isInitialised then exit;
  
  stopAllVoices;
  resetAllRegisters;

  isInitialised := false
end;

end.
