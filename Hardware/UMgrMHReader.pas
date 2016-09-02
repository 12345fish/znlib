{*******************************************************************************
  ����: dmzn@163.com 2016-08-18
  ����: ����RF-35LT������������Ԫ
*******************************************************************************}
unit UMgrMHReader;

interface

uses
  Windows, Classes, SysUtils, NativeXml, USysLoger;

const
  cLibDLL = 'mwrf32.dll';

function rf_init(port: smallint;baud:longint): longint; stdcall;
  far;external cLibDLL name 'rf_init';
function rf_exit(icdev: longint):smallint;stdcall;
  far;external cLibDLL name 'rf_exit';
function rf_encrypt(key:pchar;ptrsource:pchar;msglen:smallint;
  ptrdest:pchar):smallint;stdcall;far;external cLibDLL name 'rf_encrypt';
function rf_decrypt(key:pchar;ptrsource:pchar;msglen:smallint;
  ptrdest:pchar):smallint;stdcall;far;external cLibDLL name 'rf_decrypt';
//xxxxx

function rf_card(icdev:longint;mode:smallint;snr:pChar):smallint;stdcall;
  far;external cLibDLL name 'rf_card';
function rf_load_key(icdev:longint;mode,secnr:smallint;
  nkey:pchar):smallint;stdcall;far;external cLibDLL name 'rf_load_key';
function rf_load_key_hex(icdev:longint;mode,secnr:smallint;
  nkey:pchar):smallint;stdcall;far;external cLibDLL name 'rf_load_key_hex';
function rf_authentication(icdev:longint;mode,secnr:smallint):smallint;stdcall;
  far;external cLibDLL name 'rf_authentication';
//xxxxx

function rf_read(icdev:longint;adr:smallint;data:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_read';
function rf_read_hex(icdev:longint;adr:smallint;data:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_read_hex';
function rf_write(icdev:longint;adr:smallint;data:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_write';
function rf_write_hex(icdev:longint;adr:smallint;data:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_write_hex';
function rf_HL_writehex(icdev:longint;adr:smallint;snr:longint;
  data:pchar):smallint;stdcall;far;external cLibDLL name 'rf_HL_writehex';
//xxxxx

function rf_halt(icdev:longint):smallint;stdcall;
  far;external cLibDLL name 'rf_halt';
function rf_reset(icdev:longint;msec:smallint):smallint;stdcall;
  far;external cLibDLL name 'rf_reset';
//xxxxx

function rf_initval(icdev:longint;adr:smallint;value:longint):smallint;stdcall;
  far;external cLibDLL name 'rf_initval';
function rf_readval(icdev:longint;adr:smallint;value:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_readval';
function rf_increment(icdev:longint;adr:smallint;value:longint):smallint;stdcall;
  far;external cLibDLL name 'rf_increment';
function rf_decrement(icdev:longint;adr:smallint;value:longint):smallint;stdcall;
  far;external cLibDLL name 'rf_decrement';
function rf_restore(icdev:longint;adr:smallint):smallint;stdcall;
  far;external cLibDLL name 'rf_restore';
function rf_transfer(icdev:longint;adr:smallint):smallint;stdcall;
  far;external cLibDLL name 'rf_transfer';
function rf_check_write(icdev,snr:longint;adr,authmode:smallint;
  data:pchar):smallint;stdcall;far;external cLibDLL name 'rf_check_write';
function rf_check_writehex(icdev,snr:longint;adr,authmode:smallint;
  data:pchar):smallint;stdcall;far;external cLibDLL name 'rf_check_writehex';
//xxxxx

//M1 CARD HIGH FUNCTION
function rf_HL_initval(icdev:longint;mode:smallint;secnr:smallint;value:longint;
  snr:pchar):smallint;stdcall;far;external cLibDLL name 'rf_HL_initval';
function rf_HL_increment(icdev:longint;mode:smallint;secnr:smallint;
  value,snr:longint;svalue,ssnr:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_HL_increment';
function rf_HL_decrement(icdev:longint;mode:smallint;secnr:smallint;
  value:longint;snr:longint;svalue,ssnr:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_HL_decrement';
function rf_HL_write(icdev:longint;mode,adr:smallint;
  ssnr,sdata:pchar):smallint;stdcall; far;external cLibDLL name 'rf_HL_write';
function rf_HL_read(icdev:longint;mode,adr:smallint;snr:longint;
  sdata,ssnr:pchar):smallint;stdcall;far;external cLibDLL name 'rf_HL_read';
function rf_changeb3(icdev:longint;Adr:smallint;keyA:pchar;B0:smallint;
  B1:smallint;B2:smallint;B3:smallint;Bk:smallint;KeyB:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_changeb3';
//xxxxx

function rf_get_status(icdev:longint;status:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_get_status';
function rf_beep(icdev:longint;time:smallint):smallint;stdcall;
  far;external cLibDLL name 'rf_beep';
function rf_ctl_mode(icdev:longint;ctlmode:smallint):smallint;stdcall;
  far;external cLibDLL name 'rf_ctl_mode';
function rf_disp_mode(icdev:longint;mode:smallint):smallint;stdcall;
  far;external cLibDLL name 'rf_disp_mode';
function rf_disp8(icdev:longint;len:longint;disp:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_disp8';
function rf_disp(icdev:longint;pt_mode:smallint;disp:longint):smallint;stdcall;
  far;external cLibDLL name 'rf_disp';
//xxxxx

function rf_request(icdev:longint;find_mode:smallint;
  cardtype:pchar):smallint;stdcall;far;external cLibDLL name 'rf_request';
function rf_anticoll(icdev:longint;find_mode:pchar;snr:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_anticoll';
function rf_select(icdev:longint;snr:longint;size:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_select';
//xxxxx

function rf_settimehex(icdev:longint;dis_time:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_settimehex';
function rf_gettimehex(icdev:longint;dis_time:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_gettimehex';
function rf_swr_eeprom(icdev:longint;offset,len:smallint;
  data:pchar):smallint;stdcall;far;external cLibDLL name 'rf_swr_eeprom';
function rf_srd_eeprom(icdev:longint;offset,len:smallint;
  data:pchar):smallint;stdcall;far;external cLibDLL name 'rf_srd_eeprom';
//xxxxx

function rf_authentication_2(icdev:longint;mode,keyNum,
  secnr:smallint):smallint;stdcall;far;external cLibDLL name 'rf_authentication_2';
function rf_initval_ml(icdev:longint;value:longint):smallint;stdcall;
  far;external cLibDLL name 'rf_initval_ml';
function rf_readval_ml(icdev:longint;rvalue:pchar):smallint;stdcall;
  far;external cLibDLL name 'rf_readval_ml';
function rf_decrement_transfer(icdev:longint;adr:smallint;
  value:longint):smallint;stdcall;far;external cLibDLL name 'rf_decrement_transfer';
function rf_sam_rst(icdev:longint;baud:smallint;samack:pChar):smallint;stdcall;
  far;external cLibDLL name 'rf_sam_rst';
function rf_sam_trn(icdev:longint;samblock,recv:pChar):smallint;stdcall;
  far;external cLibDLL name 'rf_sam_trn';
function rf_sam_off(icdev:longint):smallint;stdcall;
  far;external cLibDLL name 'rf_sam_off';
function rf_cpu_rst(icdev:longint;baud:smallint;cpuack:pChar):smallint;stdcall;
  far;external cLibDLL name 'rf_cpu_rst';
function rf_cpu_trn(icdev:longint;cpublock,recv:pChar):smallint;stdcall;
  far;external cLibDLL name 'rf_cpu_trn';
function rf_pro_rst(icdev:longint;_Data:pChar):smallint;stdcall;
  far;external cLibDLL name 'rf_pro_rst';
function rf_pro_trn(icdev:longint;problock,recv:pChar):smallint;stdcall;
  far;external cLibDLL name 'rf_pro_trn';
function rf_pro_halt(icdev:longint):smallint;stdcall;
  far;external cLibDLL name 'rf_pro_halt';
function hex_a(hex,a:pChar;length:smallint):smallint;stdcall;
  far;external cLibDLL name 'hex_a';
function a_hex(a,hex:pChar;length:smallint):smallint;stdcall;
  far;external cLibDLL name 'a_hex';
//xxxxx

//------------------------------------------------------------------------------
type
  TMHReader = record
    FEnable: Boolean;        //���ñ��
    FID: string;             //��ʶ
    FName: string;           //����
    FPort: Integer;          //�˿�
    FBaud: Integer;          //������
    FHwnd: LongInt;          //�˿ھ��
  end;

  TMHReaderManager = class(TObject)
  private
    FReaders: array of TMHReader;
    //��ͷ�б�
    FErrorCode: Integer;
    FErrorDesc: string;
    //������Ϣ
    FReaderLog: Boolean;
    FReaderBeep: Boolean;
    //���п���
  protected
    function GetReader(const nID: string): Integer;
    //������ͷ
    function InitReader(const nIdx: Integer;
      const nReset: Boolean = True): Boolean;
    procedure CloseReader(const nIdx: Integer = -1);
    //�򿪹ر�
    procedure BeepReader(const nIdx: Integer; const nNum: Integer = 1);
    //��ͷ����
    procedure WriteReaderLog(const nIdx,nCode: Integer;
      const nAction,nResult: string);
    //��¼��־
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    class function GetErrorDesc(const nErr: Integer): string;
    //��������
    procedure LoadConfig(const nFile: string);
    //��������
    function ReadCardID(const nID: string = ''): string;
    //��ȡ���
    function ReadCardData(const nID: string = ''): string;
    function WriteCardData(const nData: string; const nID: string = ''): Boolean;
    //��д����
    property LastError: Integer read FErrorCode;
    property ErrorDesc: string read FErrorDesc;
    property ReaderLog: Boolean read FReaderLog write FReaderLog;
    property ReaderBeep: Boolean read FReaderBeep write FReaderBeep;
    //�������
  end;

var
  gMHReaderManager: TMHReaderManager = nil;
  //ȫ��ʹ��

implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TMHReaderManager, '����RF����', nEvent);
end;

constructor TMHReaderManager.Create;
begin
  FReaderLog := True;
  FReaderBeep := True;
  SetLength(FReaders, 0);
end;

destructor TMHReaderManager.Destroy;
begin
  CloseReader;
  inherited;
end;

//Date: 2016-09-01
//Parm: ��ͷ����;������;����;���
//Desc: ��¼nIdx��ͷ�Ĵ�����Ϣ
procedure TMHReaderManager.WriteReaderLog(const nIdx, nCode: Integer;
  const nAction,nResult: string);
var nStr: string;
begin
  if not FReaderLog then Exit;
  //xxxxx
  
  with FReaders[nIdx] do
  begin
    nStr := '%s[ %s.%s ]%s,����:[ %d.%s ].';
    nStr := Format(nStr, [nAction, FID, FName, nResult,
                          nCode, GetErrorDesc(nCode)]);
    //xxxxx

    FErrorCode := nCode;
    FErrorDesc := nStr;
    WriteLog(nStr);
  end;
end;

//Date: 2016-09-01
//Parm: ��ͷ��ʶ
//Desc: ������ʶΪnID�Ķ�ͷ����
function TMHReaderManager.GetReader(const nID: string): Integer;
var nIdx: Integer;
begin
  Result := -1;
  if (nID = '') and (Length(FReaders) > 0) then
    Result := 0;
  //first reader is default

  for nIdx:=Low(FReaders) to High(FReaders) do
  if CompareText(nID, FReaders[nIdx].FID) = 0 then
  begin
    Result := nIdx;
    Break;
  end;
end;

//Date: 2016-09-01
//Parm: ��ͷ����;�Ƿ�����
//Desc: ��������ΪnIdx�Ķ�ͷ
function TMHReaderManager.InitReader(const nIdx: Integer;
  const nReset: Boolean): Boolean;
var nStr: string;
    nHwnd: LongInt;
    nBuf: array[0..18] of Char;
begin
  with FReaders[nIdx] do
  begin
    Result := False;
    if not FEnable then
    begin
      WriteReaderLog(nIdx, 50, '������', '�ѹر�');
      Exit;
    end;

    if nReset then
      CloseReader(nIdx);
    //xxxxx

    if FHwnd > 0 then
         nHwnd := FHwnd
    else nHwnd := rf_init(FPort, FBaud);

    if nHwnd <= 0 then
    begin
      WriteReaderLog(nIdx, nHwnd, '��ʼ��', 'ʧ��');
      Exit;
    end;

    Result := True;
    FHwnd := nHwnd;

    if nReset and FReaderLog and (rf_get_status(nHwnd, @nBuf) = 0) then
    begin
      nStr := '��ʼ��[ %s.%s ]�ɹ�,�汾:[ %s ].';
      nStr := Format(nStr, [FID, FName, nBuf]);
      WriteLog(nStr);
    end; //device version
  end;
end;

//Date: 2016-09-01
//Parm: ��ͷ����(-1��ʾȫ��)
//Desc: �ر�����Ϊ��ͷ
procedure TMHReaderManager.CloseReader(const nIdx: Integer);
var i: Integer;
    nHwnd: LongInt;
begin
  for i:=Low(FReaders) to High(FReaders) do
  if (i = nIdx) or (nIdx = -1) then
  begin
    nHwnd := FReaders[i].FHwnd;
    FReaders[i].FHwnd := 0;

    if nHwnd > 0 then
      rf_exit(nHwnd);
    //close reader
  end;
end;

//Date: 2016-09-01
//Parm: �����ļ�
//Desc: ����nFile�����ļ�
procedure TMHReaderManager.LoadConfig(const nFile: string);
var nIdx: Integer;
    nNode: TXmlNode;
    nXML: TNativeXml;
begin
  nXML := TNativeXml.Create;
  try
    nXML.LoadFromFile(nFile);
    nNode := nXML.Root.NodeByName('readers');
    SetLength(FReaders, nNode.NodeCount);
    
    for nIdx:=0 to nNode.NodeCount - 1 do
    begin
      with FReaders[nIdx],nNode.Nodes[nIdx] do
      begin
        FHwnd := 0;
        FID := AttributeByName['id'];
        FName := AttributeByName['name'];

        FPort := NodeByName('port').ValueAsInteger;
        FBaud := NodeByName('baud').ValueAsInteger;
        FEnable := NodeByName('enable').ValueAsString <> 'N';
      end;
    end;
  finally
    nXML.Free;
  end;
end;

//Date: 2016-09-01
//Parm: �������
//Desc: ����nCode��Ӧ����������
class function TMHReaderManager.GetErrorDesc(const nErr: Integer): string;
begin
  case nErr of
    0: Result := '��ȷ';
    1: Result := '�޿�';
    2: Result := 'CRCУ���';
    3: Result := 'ֵ���';
    4: Result := 'δ��֤����';
    5: Result := '��żУ���';
    6: Result := 'ͨѶ����';
    8: Result := '��������к�';
    10: Result := '��֤����ʧ��';
    11: Result := '���յ�����λ����';
    12: Result := '���յ������ֽڴ���';
    14: Result := 'Transfer����';
    15: Result := 'дʧ��';
    16: Result := '��ֵʧ��';
    17: Result := '��ֵʧ��';
    18: Result := '��ʧ��';
    -$10: Result := 'PC���д��ͨѶ����';
    -$11: Result := 'ͨѶ��ʱ';
    -$20: Result := '��ͨ�ſ�ʧ��';
    -$24: Result := '�����ѱ�ռ��';
    -$30: Result := '��ַ��ʽ����';
    -$31: Result := '�ÿ����ݲ���ֵ��ʽ';
    -$32: Result := '�ȴ���';
    -$40: Result := 'ֵ����ʧ��';
    -$50: Result := '���е�ֵ������';

    50: Result := '����ҵ����' else Result := 'δ֪����';
  end;
end;

//------------------------------------------------------------------------------
//Date: 2016-09-01
//Parm: ��ͷ����;��������
//Desc: ʹnIdx�Ķ�ͷ����nNum��
procedure TMHReaderManager.BeepReader(const nIdx: Integer; const nNum: Integer);
var i: Integer;
begin
  if FReaderBeep and (FReaders[nIdx].FHwnd > 0) then
  begin
    for i:=nNum downto 1 do
    begin
      rf_beep(FReaders[nIdx].FHwnd, 12);
      Sleep(20);
    end; //beep loop
  end;
end;

//Date: 2016-09-01
//Parm: ��ͷ��ʶ
//Desc: ��ȡnID�ϵ�ǰ�ſ���0����0����,Ĭ��Ϊ����
function TMHReaderManager.ReadCardID(const nID: string): string;
var nStr: string;
    nCr: LongInt;
    nIdx,nHwnd: Integer;
begin
  Result := '';
  nIdx := GetReader(nID);

  if nIdx < 0 then Exit;
  if not InitReader(nIdx) then Exit;

  with FReaders[nIdx] do
  try
    nHwnd := rf_card(FHwnd, 1, @nCr);
    if nHwnd <> 0 then
    begin
      WriteReaderLog(nIdx, nHwnd, '��ȡ����', 'ʧ��');
      BeepReader(nIdx, 2);
      Exit;
    end;

    nStr := Format('%x', [nCr]);
    if Length(nStr) <> 8 then
    begin
      WriteReaderLog(nIdx, 50, '��ȡ����', 'ʧ��');
      BeepReader(nIdx, 2);
      Exit;
    end;

    Result := nStr[7] + nStr[8] +
              nStr[5] + nStr[6] +
              nStr[3] + nStr[4] +
              nStr[1] + nStr[2];
    //xxxxx

    BeepReader(nIdx, 1);
    rf_halt(FHwnd);
  except
    on E:Exception do
    begin
      nStr := '��ȡ����[ %s.%s ]ʧ��,����: %s';
      WriteLog(Format(nStr, [FID, FName, E.Message]));
      CloseReader(nIdx);
    end;
  end;
end;

//Date: 2016-09-01
//Parm: ��ͷ��ʶ
//Desc: ��ȡnID�ϵĿ�Ƭ����
function TMHReaderManager.ReadCardData(const nID: string): string;
begin

end;

//Date: 2016-09-01
//Parm: ��ͷ��ʶ
//Desc: ��nDataд��nID��ͷ�ϵĿ�Ƭ
function TMHReaderManager.WriteCardData(const nData, nID: string): Boolean;
begin

end;

initialization
  gMHReaderManager := nil;
finalization
  FreeAndNil(gMHReaderManager);
end.
 