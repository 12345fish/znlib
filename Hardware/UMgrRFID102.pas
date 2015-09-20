{*******************************************************************************
  ����: dmzn@163.com 2014-10-24
  ����: �������пƻ���Ƽ����޹�˾ RFID102��ȡ������
*******************************************************************************}
unit UMgrRFID102;

interface

uses
  Windows, Classes, SysUtils, SyncObjs, NativeXml, UWaitItem, 
  USysLoger, IdTCPClient, IdGlobal, ULibFun;

const
  cHYReader_Wait_Short     = 5;
  cHYReader_Wait_Long      = 2 * 1000;

type
  TReadCmdType = (
    tCmd_Err_Cmd                  = $00,
    //δʶ������
    
    tCmd_G2_Seek                  = $01,
    tCmd_G2_ReadData              = $02,
    tCmd_G2_WriteData             = $03,
    tCmd_G2_WriteEPCID            = $04,
    tCmd_G2_Destory               = $05,
    tCmd_G2_SetMemRWProtect       = $06,
    tCmd_G2_EreaseArea            = $07,
    tCmd_G2_InstalReadProtect     = $08,
    tCmd_G2_SetReadProtect        = $09,
    tCmd_G2_UnlockRProtect        = $0A,
    tCmd_G2_ChargeRProtect        = $0B,
    tCmd_G2_SetEASWarn            = $0C,
    tCmd_G2_ChargeEASWarn         = $0D,
    tCmd_G2_UseAreaLock           = $0E,
    tCmd_G2_SeekSingle            = $0F,
    tCmd_G2_WriteArea             = $10,
    //����EPC C1G2���� ��Χ0x01-0x10
    //1	0x01	ѯ���ǩ
    //2	0x02	������
    //3	0x03	д����
    //4	0x04	дEPC��
    //5	0x05	���ٱ�ǩ
    //6	0x06	�趨�洢����д����״̬
    //7	0x07	�����
    //8	0x08	����EPC���趨����������
    //9	0x09	����ҪEPC�Ŷ������趨
    //10	0x0a	����������
    //11	0x0b	���Ա�ǩ�Ƿ����ö�����
    //12	0x0c	EAS��������
    //13	0x0d	EAS����̽��
    //14	0x0e	user������
    //15	0x0f	ѯ�鵥��ǩ
    //16	0x10	��д

    
    tCmd_6B_SeekSingle             = $50,
    tCmd_6B_SeekMulti              = $51,
    tCmd_6B_ReadData               = $52,
    tCmd_6B_WriteData              = $53,
    tCmd_6B_ChargeLock             = $54,
    tCmd_6B_Lock                   = $55,
    //����1800-68���� ��Χ0x50-0x55
    //1	0x50	ѯ������(����)���������ÿ��ֻ��ѯ��һ�ŵ��ӱ�ǩ����������ѯ�顣
    //2	0x51	����ѯ������(����)�����������ݸ�������������ѯ���ǩ�����ط��������ĵ��ӱ�ǩ��UID������ͬʱѯ����ŵ��ӱ�ǩ��
    //3	0x52	�����������������ȡ���ӱ�ǩ�����ݣ�һ�������Զ�32���ֽڡ�
    //4	0x53	д�������д�����ݵ����ӱ�ǩ�У�һ��������д32���ֽڡ�
    //5	0x54	�������������ĳ���洢��Ԫ�Ƿ��Ѿ���������
    //6	0x55	�����������ĳ����δ�������ĵ��ӱ�ǩ��
    
    
    tCmd_Reader_ReadInfo              = $21,
    tCmd_Reader_SetWorkrate           = $22,
    tCmd_Reader_SetAddr               = $24,
    tCmd_Reader_SetSeekTimeOut        = $25,
    tCmd_Reader_SetBoundrate          = $28,
    tCmd_Reader_SetOutweight          = $2F,
    tCmd_Reader_SetRoundAndRight      = $33,
    tCmd_Reader_SetWGParam            = $34,
    tCmd_Reader_SetWorkmode           = $35,
    tCmd_Reader_ReadWorkmode          = $36,
    tCmd_Reader_SetEASweight          = $37,
    tCmd_Reader_SetSyris485TimeOut    = $38,
    tCmd_Reader_SetReplyTimeOut       = $3B
    //��д���Զ�������

    //1	0x21	��ȡ��д����Ϣ
    //2	0x22	���ö�д������Ƶ��
    //3	0x24	���ö�д����ַ
    //4	0x25	���ö�д��ѯ��ʱ��
    //5	0x28	���ö�д���Ĳ�����
    //6	0x2F	������д���������
    //7	0x33	�����������
    //8	0x34	Τ��������������
    //9	0x35	����ģʽ��������
    //10	0x36	��ȡ����ģʽ��������
    //11	0x37	EAS���Ծ�����������
    //12	0x38	����Syris485��Ӧƫִʱ��
    //13	0x3b	���ô�����Чʱ��
  );

  PRFIDReaderCmd = ^TRFIDReaderCmd;
  TRFIDReaderCmd = record
    FLen :Char;
    //ָ����������ݿ�ĳ��ȣ���������Len����
    //�����ݿ�ĳ��ȵ���4��Data[]�ĳ��ȡ�Len��������ֵΪ96����СֵΪ4

    FAddr:Char;
    //��д����ַ����ַ��Χ��0x00~0xFE��0xFFΪ�㲥��ַ��
    //��д��ֻ��Ӧ�������ַ��ͬ����ַΪ0xFF�������д������ʱ��ַΪ0x00

    FCmd :TReadCmdType;
    //������롣

    FStatus: Char;
    //����ִ�н��״ֵ̬��

    FData:string;
    //��������ʵ�������У����Բ����ڡ�

    FLSB, FMSB:Char;
    //CRC16���ֽں͸��ֽڡ�CRC16�Ǵ�Len��Data[]��CRC16ֵ
  end;

  TRFIDReaderClass = class(TObject)
  private 
    function Crc16Calc(const nStrSrc: string;
      const nStart,nEnd: Integer; nCrcValue: Word=$FFFF;
      nGenPoly: Word=$8408): Word;
    //������ӱ�ǩCrc16�㷨

    function AsciConvertBuf(const nTxt: string; var nBuf: TIdBytes): Integer;
    function BufConvertAsci(var nTxt: string; const nBuf: TIdBytes): Integer;
  public    
    function PackSendData(var nStrDest: string; nItem:TRFIDReaderCmd): Boolean;
    function UnPackRecvData(var nItem:TRFIDReaderCmd; nStrSrc: string): Boolean;
    //��װ��������ӱ�ǩЭ��
  end;

//------------------------------------------------------------------------------

  PHYReaderItem = ^THYReaderItem;
  THYReaderItem = record
    FID     : string;          //��ͷ��ʶ
    FHost   : string;          //��ַ
    FPort   : Integer;         //�˿�

    FCard   : string;          //����
    FTunnel : string;          //ͨ����
    FEnable : Boolean;         //�Ƿ�����
    FLocked : Boolean;         //�Ƿ�����
    FLastActive: Int64;        //�ϴλ

    FClient : TIdTCPClient;       //ͨ�ŷ�ʽ
  end;

  THYReaderManager = class;
  THYRFIDReader = class(TThread)
  private
    FOwner: THYReaderManager;
    //ӵ����
    FWaiter: TWaitObject;
    //�ȴ�����
    FActiveReader: PHYReaderItem;
    //��ǰ��ͷ

    FSendItem, FRecvItem: TRFIDReaderCmd;
    //����ָ�����ָ��
    FRFIDReader: TRFIDReaderClass;
    //���ӱ�ǩ����������
    
    FEPCList: TStrings;
    //���ӱ�ǩ
  protected
    procedure DoExecute;
    procedure Execute; override;
    function ReadCard(const nReader: PHYReaderItem): Boolean;
    //ִ���߳�
  public
    constructor Create(AOwner: THYReaderManager);
    destructor Destroy; override;
    //�����ͷ�
    procedure StopMe;
    //ֹͣ�߳�
  end;

//------------------------------------------------------------------------------

  THYReaderProc = procedure (const nItem: PHYReaderItem);
  THYReaderEvent = procedure (const nItem: PHYReaderItem) of Object;

  THYReaderManager = class(TObject)
  private
    FEnable: Boolean;
    //�Ƿ�����
    FReaderIndex: Integer;
    FReaders: TList;
    //��ͷ�б�
    FThreads: array[0..2] of THYRFIDReader;
    //��������
    FSyncLock: TCriticalSection;
    //ͬ������
    FOnProc: THYReaderProc;
    FOnEvent: THYReaderEvent;
    //�¼�����

    FThreadCount: Int64;
    //�����߳���
  protected
    procedure ClearReaders(const nFree: Boolean);
    //������Դ
    procedure CloseReader(const nReader: PHYReaderItem);
    //�رն�ͷ
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure LoadConfig(const nFile: string);
    //��������
    procedure StartReader;
    procedure StopReader;
    //��ͣ��ͷ
    property OnCardProc: THYReaderProc read FOnProc write FOnProc;
    property OnCardEvent: THYReaderEvent read FOnEvent write FOnEvent;
    //�������
  end;

var
  gHYReaderManager: THYReaderManager = nil;
  //ȫ��ʹ��
  
implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(THYReaderManager, '����RFID������', nEvent);
end;
//------------------------------------------------------------------------------
constructor THYReaderManager.Create;
var nIdx: Integer;
begin
  for nIdx:=Low(FThreads) to High(FThreads) do
    FThreads[nIdx] := nil;
  //xxxxx
  
  FEnable := False;
  FReaders := TList.Create;
  FSyncLock := TCriticalSection.Create;
end;

destructor THYReaderManager.Destroy;
begin
  StopReader;
  ClearReaders(True);

  FSyncLock.Free;
  inherited;
end;

procedure THYReaderManager.ClearReaders(const nFree: Boolean);
var nIdx: Integer;
begin
  for nIdx:=FReaders.Count - 1 downto 0 do
  begin
    Dispose(PHYReaderItem(FReaders[nIdx]));
    FReaders.Delete(nIdx);
  end;

  if nFree then
    FReaders.Free;
  //xxxxx
end;

procedure THYReaderManager.StartReader;
var nIdx,nNum: Integer;
begin
  if not FEnable then Exit;
  nNum := 0;
  FReaderIndex := 0;

  for nIdx:=Low(FThreads) to High(FThreads) do
   if Assigned(FThreads[nIdx]) then
    Inc(nNum);
  //xxxxx

  for nIdx:=Low(FThreads) to High(FThreads) do
  begin
    if (nNum > 0) and (FReaders.Count < 2) then Exit;
    //һ����ͷ���߳�
    if nNum >= FThreadCount then Exit;
    //�̲߳��ܳ���Ԥ��ֵ

    if not Assigned(FThreads[nIdx]) then
    begin
      FThreads[nIdx] := THYRFIDReader.Create(Self);
      Inc(nNum);
    end;
  end;
end;

procedure THYReaderManager.CloseReader(const nReader: PHYReaderItem);
begin
  if Assigned(nReader) and Assigned(nReader.FClient) then
  begin 
    nReader.FClient.Disconnect;
    if Assigned(nReader.FClient.IOHandler) then
      nReader.FClient.IOHandler.InputBuffer.Clear;
  end;
end;

procedure THYReaderManager.StopReader;
var nIdx: Integer;
begin
  for nIdx:=Low(FThreads) to High(FThreads) do
   if Assigned(FThreads[nIdx]) then
    FThreads[nIdx].Terminate;
  //�����˳����

  for nIdx:=Low(FThreads) to High(FThreads) do
  if Assigned(FThreads[nIdx]) then
  begin
    FThreads[nIdx].StopMe;
    FThreads[nIdx] := nil;
  end;

  FSyncLock.Enter;
  try
    for nIdx:=FReaders.Count - 1 downto 0 do
      CloseReader(FReaders[nIdx]);
    //�رն�ͷ
  finally
    FSyncLock.Leave;
  end;
end;

procedure THYReaderManager.LoadConfig(const nFile: string);
var nIdx: Integer;
    nXML: TNativeXml;
    nNode,nTmp: TXmlNode;
    nReader: PHYReaderItem;
begin
  FEnable := False;
  if not FileExists(nFile) then Exit;

  nXML := nil;
  try
    nXML := TNativeXml.Create;
    nXML.LoadFromFile(nFile);

    nNode := nXML.Root.FindNode('readers');
    if not Assigned(nNode) then Exit;
    ClearReaders(False);

    nTmp := nNode.FindNode('threadcount');
    if Assigned(nTmp) then
         FThreadCount := nTmp.ValueAsInteger
    else FThreadCount := 1;

    for nIdx:=0 to nNode.NodeCount - 1 do
    begin
      nTmp := nNode.Nodes[nIdx];
      if CompareText(nTmp.Name, 'reader') <> 0 then Continue;

      New(nReader);
      FReaders.Add(nReader);

      with nTmp,nReader^ do
      begin
        FLocked := False;
        FLastActive := GetTickCount;

        FID := AttributeByName['id'];
        FHost := NodeByName('ip').ValueAsString;
        FPort := NodeByName('port').ValueAsInteger;
        FEnable := NodeByName('enable').ValueAsString <> 'N';

        if FEnable then
          Self.FEnable := True;
        //��Ч�ڵ�

        nTmp := FindNode('tunnel');
        if Assigned(nTmp) then
          FTunnel := nTmp.ValueAsString;
        //ͨ����

        FClient := TIdTCPClient.Create;
        with FClient do
        begin
          Host := FHost;
          Port := FPort;

          ConnectTimeout := cHYReader_Wait_Long;   
        end;  
      end;
    end;
  finally
    nXML.Free;
  end;
end;

//------------------------------------------------------------------------------
constructor THYRFIDReader.Create(AOwner: THYReaderManager);
begin
  inherited Create(False);
  FreeOnTerminate := False;

  FOwner := AOwner;
  FWaiter := TWaitObject.Create;
  FWaiter.Interval := cHYReader_Wait_Short;

  FEPCList:=TStringList.Create;
  FRFIDReader := TRFIDReaderClass.Create;
end;

destructor THYRFIDReader.Destroy;
begin
  FreeAndNil(FEPCList);
  FreeAndNil(FRFIDReader);
  FWaiter.Free;
  inherited;
end;

procedure THYRFIDReader.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure THYRFIDReader.Execute;
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    DoExecute;
    //ִ�ж���
  except
    on E: Exception do
    begin
      WriteLog(E.Message);
      Sleep(500);
    end;
  end;
end;

procedure THYRFIDReader.DoExecute;
var nIdx: Integer;
    nStr: string;
    nReader: PHYReaderItem;
begin
  FActiveReader := nil;
  //init

  with FOwner do
  try
    FSyncLock.Enter;
    try
      if FThreadCount>1 then  //��������߳�ʱ���п��ŵĶ�ͷ����
      for nIdx:=FReaders.Count - 1 downto 0 do
      begin
        nReader := FReaders[nIdx];
        if nReader.FEnable and (not nReader.FLocked) and
           (GetTickCount - nReader.FLastActive < cHYReader_Wait_Long) then
        //�п��ŵĶ�ͷ����
        begin
          FActiveReader := nReader;
          FActiveReader.FLocked := True;
          Break;
        end;
      end;

      if not Assigned(FActiveReader) then
      begin
        nIdx := 0;
        //init

        while True do
        begin
          if FReaderIndex >= FReaders.Count then
          begin
            FReaderIndex := 0;
            Inc(nIdx);

            if nIdx > 1 then Break;
            //ɨ��һ��,��Ч�˳�
          end;

          nReader := FReaders[FReaderIndex];
          Inc(FReaderIndex);
          if nReader.FLocked or (not nReader.FEnable) then Continue;

          FActiveReader := nReader;
          FActiveReader.FLocked := True;
          Break;
        end;
      end;
    finally
      FSyncLock.Leave;
    end;

    if Assigned(FActiveReader) and (not Terminated) then
    try
      if ReadCard(FActiveReader) then
      begin
        FWaiter.Interval := cHYReader_Wait_Short;
        FActiveReader.FLastActive := GetTickCount;
      end else
      begin
        if (FActiveReader.FLastActive > 0) and
           (GetTickCount - FActiveReader.FLastActive >= 3 * 1000) then
        begin
          FActiveReader.FLastActive := 0;

          if FThreadCount>1 then
            FWaiter.Interval := cHYReader_Wait_Long;
          //��������߳�ʱ��������ʱ���ӳ�ʱ��
        end;
      end;
    except
      on E: Exception do
      begin
        nStr := '������[%s:%s.%d]����ʧ�ܣ�������Ϣ[%s]';
        nStr := Format(nStr, [FActiveReader.FID, FActiveReader.FHost,
                FActiveReader.FPort, E.Message]);
        //xxxx
                                     
        CloseReader(FActiveReader);
        raise Exception.Create(nStr);
      end;
    end;
  finally
    if Assigned(FActiveReader) then
      FActiveReader.FLocked := False;
    //unlock
  end;
end;

function getStr(pStr: pchar; len: Integer): string;
var
  i: Integer;
begin
  result := '';
  for i := 0 to len - 1 do
    result := result + (pStr + i)^;
end;

function getHexStr(sBinStr: string): string; //���ʮ�������ַ���
var
  i: Integer;
begin
  result := '';
  for i := 1 to Length(sBinStr) do
    result := result + IntToHex(ord(sBinStr[i]), 2);
end;

function THYRFIDReader.ReadCard(const nReader: PHYReaderItem): Boolean;
var nSendData, nRecvData,nEPC: string;
    nBuf, nRecv: TIdBytes;
    nStart, nLen: Integer;
    nInt, nIdx: Integer;   
begin
  Result := False;

  FOwner.FSyncLock.Enter;
  try
    with FRFIDReader, nReader^ do
    begin
      with FSendItem do
      begin
        FCmd  := tCmd_G2_Seek;
        FAddr := Chr($FF);
        FData := '' ;
      end;  

      if not PackSendData(nSendData, FSendItem) then Exit;

      try
        if not FClient.Connected then
          FClient.Connect;

        AsciConvertBuf(nSendData, nBuf);
        FClient.IOHandler.Write(nBuf);

        Sleep(150);
        //Wait for

        FClient.IOHandler.CheckForDataOnSource;
        if FClient.IOHandler.InputBufferIsEmpty then  Exit;
        //No Data Recv

        nInt := FClient.IOHandler.InputBuffer.Size;
        FClient.IOHandler.ReadBytes(nRecv, nInt, False);
        BufConvertAsci(nRecvData, nRecv);

        if not UnPackRecvData(FRecvItem, nRecvData) then Exit;
        //Unpack Error

        if FRecvItem.FCmd <> FSendItem.FCmd then Exit;
        //not sample cmd

        if (FRecvItem.FStatus <> #01) and (FRecvItem.FStatus <> #02)
        and (FRecvItem.FStatus <> #03) and (FRecvItem.FStatus <> #04)
        then Exit;

        nStart:=1;
        nInt := Ord(FRecvItem.FData[1]);
        for nIdx:=0 to nInt-1 do
        begin
          nLen := Ord(FRecvItem.FData[nStart+1]);
          nEPC := getHexStr(Copy(FRecvItem.FData, nStart+2, nLen));

          nStart := nStart + nLen + 1;
          FEPCList.Add(nEPC);
        end;  
      except
        on E: Exception do
        begin
          raise;
        end;
      end;
    end;
    
    if Terminated then Exit;
    //thread exit

    nReader.FCard := CombinStr(FEPCList, ',', False);
    FEPCList.Clear;
    //xxxxx
  finally
    FOwner.FSyncLock.Leave;
  end;

  if Assigned(FOwner.FOnProc) then
    FOwner.FOnProc(nReader);
  //xxxxx

  if Assigned(FOwner.FOnEvent) then
    FOwner.FOnEvent(nReader);
  //xxxxx

  Result := True;
end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//Date: 2015/7/8
//Parm: Ŀ���ַ������������ݸ�ʽ
//Desc: ����ͨ��Э���װ
function TRFIDReaderClass.PackSendData(var nStrDest: string;
    nItem:TRFIDReaderCmd):Boolean;
var nCRC: Word;
    nTmpSend: string;
    nTmpCmd: TRFIDReaderCmd;
begin
  nTmpSend := '';
  nTmpCmd  := nItem;

  with nTmpCmd do
  begin
    FLen := Chr(4 + Length(FData));

    nTmpSend := FLen + FAddr + Chr(Ord(FCmd)) + FData;
    nCRC := Crc16Calc(nTmpSend, 1, Length(nTmpSend));

    FLSB := Chr(nCRC mod 256);
    FMSB := Chr(nCRC div 256);

    nTmpSend := nTmpSend + FLSB + FMSB;
  end;

  nStrDest := nTmpSend;
  Result := True;
end;
//------------------------------------------------------------------------------
//Date: 2015/7/8
//Parm: Ŀ��Э��ṹ��ԭʼ�ַ���
//Desc: ����ͨ��Э�����
function TRFIDReaderClass.UnPackRecvData(var nItem:TRFIDReaderCmd;
  nStrSrc: string): Boolean;
var nLen, nLenSrc: Integer;
    nRecvCRC: Word;
begin
  Result := False;

  nLenSrc:=Length(nStrSrc);
  if nLenSrc<0 then Exit;
  //����Ϊ��

  nLen := Ord(nStrSrc[1]);
  if nLen>(nLenSrc-1) then Exit;
  //����δ������ȫ

  nRecvCRC := Crc16Calc(nStrSrc, 1, nLen-1);
  if (Ord(nStrSrc[nLen]) <> (nRecvCRC mod 256)) or
     (Ord(nStrSrc[nLen+1]) <> (nRecvCRC div 256)) then Exit;
  //CRC Error

  with nItem do
  begin
    FLen      := Chr(nLen);
    FAddr     := nStrSrc[2];
    FCmd      := TReadCmdType(Ord(nStrSrc[3]));
    FStatus   := nStrSrc[4];

    FData     := Copy(nStrSrc, 5, nLen-5);
    FLSB      := nStrSrc[nLen];
    FMSB      := nStrSrc[nLen + 1];
  end;

  if (nItem.FCmd=tCmd_Err_Cmd) then Exit;
  //Err Command type
  
  Result := True;
end;

//Date: 2015/2/8
//Parm: �ַ�����Ϣ;�ַ�����
//Desc: �ַ���ת����
function TRFIDReaderClass.AsciConvertBuf(const nTxt: string;
  var nBuf: TIdBytes): Integer;
var nIdx: Integer;
    nC: char;
begin
  Result := 0;
  SetLength(nBuf, Length(nTxt));
  //xxxxx

  for nIdx:=1 to Length(nTxt) do
  begin
    nC := nTxt[nIdx];
    nBuf[Result] := Ord(nC);

    Inc(Result);
  end;
end;
//------------------------------------------------------------------------------
//Date: 2015/7/8
//Parm: Ŀ���ַ���;ԭʼ�ַ�����
//Desc: ����ת�ַ���
function TRFIDReaderClass.BufConvertAsci(var nTxt: string;
  const nBuf: TIdBytes): Integer;
var nIdx: Integer;
begin
  Result := 0;
  nTxt   := '';

  for nIdx:=0 to Length(nBuf)-1 do
  begin
    nTxt := nTxt + Chr(nBuf[nIdx]);
    Inc(Result);
  end;
end;

//Date: 2015/6/19
//Parm: ԭʼ����(16����);У����ʼ����;У����ֹ��������ʼCRC������ʽ
//Desc: �пƻ�����ӱ�ǩCRC16У���㷨
function TRFIDReaderClass.Crc16Calc(const nStrSrc: string;
    const nStart,nEnd: Integer; nCrcValue: Word=$FFFF;
    nGenPoly: Word=$8408): Word;
var nIdx,nInt: Integer;
    nCrcTmp: Word;
begin
  Result := 0;
  if (nStart > nEnd) or (nEnd < 1) then Exit;

  nCrcTmp := nCrcValue;
  for nIdx:=nStart to nEnd do
  begin
    nCrcTmp := nCrcTmp xor Ord(nStrSrc[nIdx]);

    for nInt:=0 to 7 do
    if (nCrcTmp and $0001)<>0 then
         nCrcTmp := (nCrcTmp shr 1) xor nGenPoly
    else nCrcTmp := nCrcTmp shr 1;
  end;

  Result := nCrcTmp;
end;

initialization
  gHYReaderManager := nil;
finalization
  FreeAndNil(gHYReaderManager);
end.
