{*******************************************************************************
  ����: dmzn@163.com 2016-09-05
  ����: ʹ��PLC-OPC���������ĳ��������ͨѶ��Ԫ
*******************************************************************************}
unit UMgrTruckProbeOPC;

{.$DEFINE DEBUG}
interface

uses
  Windows, Classes, SysUtils, ExtCtrls, SyncObjs, dOPCIntf, dOPCComn, dOPCDA,
  dOPC, NativeXml, UMemDataPool, USysLoger, ULibFun;

type
  POPCProberHost = ^TOPCProberHost;
  TOPCProberHost = record
    FEnable  : Boolean;                 //�Ƿ���
    FID      : string;                  //��ʶ
    FName    : string;                  //����
    FServerName : string;
    FServerObj  : TdOPCServer;          //�������

    FInSignalOn: Byte;
    FInSignalOff: Byte;                 //�����ź�
    FOutSignalOn: Byte;
    FOutSignalOff: Byte;                //����ź�
  end;

  TOPCProberIOAddress = array[0..7] of string;
  //in-out address

  POPCProberTunnel = ^TOPCProberTunnel;
  TOPCProberTunnel = record
    FEnable : Boolean;                  //�Ƿ�����
    FID     : string;                   //��ʶ
    FName   : string;                   //����

    FIn     : TOPCProberIOAddress;      //�����ַ
    FOut    : TOPCProberIOAddress;      //�����ַ
    FHost   : POPCProberHost;           //��������
  end;

  POPCFolder = ^TOPCFolder;
  TOPCFolder = record                   
    FID     : string;                   //�ڵ���
    FName   : string;                   //OPCĿ¼����
    FFolder : TdOPCBrowseItem;          //OPCĿ¼����

    FHost   : POPCProberHost;           //��������
    FItems  : TList;                    //Ŀ¼����Ŀ
  end;

  POPCItem = ^TOPCItem;
  TOPCItem = record
    FID    : string;                    //�ڵ���
    FName  : string;                    //OPC��Ŀ����
    FItem  : TdOPCBrowseItem;           //OPC�������
    FGItem : TdOPCItem;                 //OPC��Ŀ����
  end;

  TOPCWriteAction = (waWrite, waConnSrv);
  //OPC����: д����,���ӷ�����

  POPCWriteItem = ^TOPCWriteItem;
  TOPCWriteItem = record
    FEnable : Boolean;                  //�Ƿ�����
    FAction: TOPCWriteAction;           //����

    FHost: string;                      //OPC����
    FFolder: string;                    //OPCĿ¼
    FItem: string;                      //��Ŀ������
    FValue: OleVariant;                 //��Ŀ����ֵ
  end;

  TProberOPCManager = class(TObject)
  private
    FFolders: TList;
    //Ŀ¼�б�
    FHosts: TList;
    //�����б�
    FTunnels: TList;
    //ͨ���б�
    FIDWriteData: Integer;
    FWriteList: TList;
    FWriteTimer: TTimer;
    //���߳�д��
    FSyncLock: TCriticalSection;
    //ͬ������
  protected
    procedure ClearFolders(const nFree: Boolean = True);
    procedure ClearHosts(const nFree: Boolean = True);
    procedure ClearTunnels(const nFree: Boolean = True);
    procedure ClearWriteList(const nFree: Boolean = True);
    //������Դ
    function GetHost(const nID: string): POPCProberHost;
    function GetTunnel(const nTunnel: string): Integer;
    function GetItem(var nFolder: POPCFolder; var nItem: POPCItem;
      const nIDName: string; const nType: Byte = 1): Integer;
    //������Ŀ
    function LoadFolderItemList(const nHost: POPCProberHost;
      var nErr: string; var nLevel: Integer): Boolean;
    function BuildOPCGroup(const nHost: POPCProberHost; var nErr: string): Boolean;
    //����OPC�б�
    procedure RegisterDataType;
    //ע������
    function WriteOPCData: Boolean;
    procedure OnWriteTimer(Sender: TObject);
    //���߳�д��
    procedure ReConnectOPCServer(const nHost,nFolder: string);
    //����������
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure LoadConfig(const nFile: string);
    //��ȡ����
    function ConnectOPCServer(var nErr: string;
      const nHost: POPCProberHost = nil): Boolean;
    procedure DisconnectServer(const nHost: POPCProberHost = nil);
    //���ӷ���
    function OpenTunnel(const nTunnel: string): Boolean;
    function CloseTunnel(const nTunnel: string): Boolean;
    function TunnelOC(const nTunnel: string; nOC: Boolean): string;
    //����ͨ��
    function IsTunnelOK(const nTunnel: string): Boolean;
    //��ѯ״̬
    property Tunnels: TList read FTunnels;
    //�������
  end;

var
  gProberOPCManager: TProberOPCManager = nil;
  //ȫ��ʹ��
  
implementation

const
  cProber_NullASCII           = Char($01);       //ASCII���ֽ�

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TProberOPCManager, '����������', nEvent);
end;

//------------------------------------------------------------------------------
constructor TProberOPCManager.Create;
begin
  RegisterDataType;
  //do first

  FFolders := TList.Create;
  FHosts := TList.Create;
  FTunnels := TList.Create;

  FWriteTimer := TTimer.Create(nil);
  FWriteTimer.OnTimer := OnWriteTimer;
  FWriteTimer.Interval := 200;
  FWriteTimer.Enabled := False;

  FWriteList := TList.Create;
  FSyncLock := TCriticalSection.Create;
end;

destructor TProberOPCManager.Destroy;
begin
  ClearHosts();
  ClearFolders();
  ClearTunnels();

  FWriteTimer.Free;
  ClearWriteList();
  
  FSyncLock.Free;
  inherited;
end;

procedure OnNew(const nFlag: string; const nType: Word; var nData: Pointer);
var nWrite: POPCWriteItem;
begin
  if nFlag = 'WriteData' then
  begin
    New(nWrite);
    nData := nWrite;
  end;
end;

procedure OnFree(const nFlag: string; const nType: Word; const nData: Pointer);
begin
  if nFlag = 'WriteData' then
  begin
    Dispose(POPCWriteItem(nData));
  end;
end;

procedure TProberOPCManager.RegisterDataType;
begin
  if not Assigned(gMemDataManager) then
    raise Exception.Create('ProberOPCManager Needs MemDataManager Support.');
  //xxxxx

  with gMemDataManager do
    FIDWriteData := RegDataType('WriteData', 'OPCManager', OnNew, OnFree, 2);
  //xxxxx
end;

//Date: 2016-09-05
//Parm: �ͷŶ���
//Desc: ����Ŀ¼�б�
procedure TProberOPCManager.ClearFolders(const nFree: Boolean);
var i,nIdx: Integer;
    nI: POPCItem;
    nF: POPCFolder;
begin
  if not Assigned(FFolders) then Exit;
  //has be freed

  for nIdx:=FFolders.Count-1 downto 0 do
  begin
    nF := FFolders[nIdx];
    if not Assigned(nF) then Continue;
    FFolders[nIdx] := nil;

    if Assigned(nF.FItems) then
    begin
      for i:=nF.FItems.Count-1 downto 0 do
      begin
        nI := nF.FItems[i];
        if not Assigned(nI) then Continue;
        nF.FItems[i] := nil;

        if Assigned(nI.FItem) then
          FreeAndNil(nI.FItem);
        Dispose(nI);
      end;

      FreeAndNil(nF.FItems);
    end;

    if Assigned(nF.FFolder) then
      FreeAndNil(nF.FFolder);
    Dispose(nF);
  end;

  if nFree then
       FreeAndNil(FFolders)
  else FFolders.Clear;
end;

//Date: 2016-09-05
//Parm: �ͷŶ���
//Desc: ���������б�
procedure TProberOPCManager.ClearHosts(const nFree: Boolean);
var nIdx: Integer;
    nHost: POPCProberHost;
begin
  for nIdx:=FHosts.Count-1 downto 0 do
  begin
    nHost := FHosts[nIdx];
    if not Assigned(nHost) then Continue;
    FHosts[nIdx] := nil;

    if Assigned(nHost.FServerObj) then
      FreeAndNil(nHost.FServerObj);
    Dispose(nHost);
  end;

  if nFree then
       FreeAndNil(FHosts)
  else FHosts.Clear;
end;

//Date: 2016-09-05
//Parm: �ͷŶ���
//Desc: ����ͨ���б�
procedure TProberOPCManager.ClearTunnels(const nFree: Boolean);
var nIdx: Integer;
begin
  for nIdx:=FTunnels.Count-1 downto 0 do
  begin
    Dispose(POPCProberTunnel(FTunnels[nIdx]));
    FTunnels.Delete(nIdx);
  end;

  if nFree then
    FreeAndNil(FTunnels);
  //xxxxx
end;

//Date: 2016-09-08
//Parm: �ͷŶ���
//Desc: �����д���б�
procedure TProberOPCManager.ClearWriteList(const nFree: Boolean);
var nIdx: Integer;
begin
  for nIdx:=FWriteList.Count-1 downto 0 do
  begin
    gMemDataManager.UnLockData(FWriteList[nIdx]);
    FWriteList.Delete(nIdx);
  end;

  if nFree then
    FreeAndNil(FWriteList);
  //xxxxx
end;

//Date: 2016-09-08
//Parm: ������ʶ
//Desc: ������ʶΪnID��������
function TProberOPCManager.GetHost(const nID: string): POPCProberHost;
var nIdx: Integer;
begin
  Result := nil;

  for nIdx:=FHosts.Count-1 downto 0 do
  if CompareText(nID, POPCProberHost(FHosts[nIdx]).FID) = 0 then
  begin
    Result := FHosts[nIdx];
    Break;
  end;
end;

//Date: 2016-09-06
//Parm: ͨ����
//Desc: ����nTunnel������
function TProberOPCManager.GetTunnel(const nTunnel: string): Integer;
var nIdx: Integer;
begin
  Result := -1;

  for nIdx:=FTunnels.Count-1 downto 0 do
  if CompareText(nTunnel, POPCProberTunnel(FTunnels[nIdx]).FID) = 0 then
  begin
    Result := nIdx;
    Break;
  end;
end;

//Date: 2016-09-05
//Parm: Ŀ¼;��Ŀ;��ʶor����;��������(1,��ʶ;2,����;3,��ʶ+����)
//Desc: ������ʶΪnIDName������,��������.
function TProberOPCManager.GetItem(var nFolder: POPCFolder; var nItem: POPCItem;
  const nIDName: string; const nType: Byte): Integer;
var i,nIdx: Integer;
    nF: POPCFolder;
    nI: POPCItem;
begin
  nFolder := nil;
  nItem := nil;
  Result := -1;

  for nIdx:=FFolders.Count-1 downto 0 do
  begin
    nF := FFolders[nIdx];
    if not Assigned(nF) then Continue;

    if (((nType=1) or (nType = 3)) and (CompareText(nIDName, nF.FID) = 0)) or
       ( (nType=2) and (CompareText(nIDName, nF.FName) = 0)) then //folder match
    begin
      nFolder := nF;
      Result := nIdx;
      Exit;
    end;

    if Assigned(nF.FItems) then
    for i:=nF.FItems.Count-1 downto 0 do
    begin
      nI := nF.FItems[i];
      if not Assigned(nI) then Continue;

      if (((nType=1) or (nType = 3)) and (CompareText(nIDName, nI.FID) = 0)) or
         ( (nType=2) and (CompareText(nIDName, nI.FName) = 0)) then //item match
      begin
        nFolder := nF;
        nItem := nI;
        Result := i;
        Exit;
      end;
    end;
  end;
end;

//Date��2016-9-5
//Parm����ַ�ṹ;��ַ�ַ���,����: 1,2,3
//Desc����nStr��,����nAddr�ṹ��
procedure SplitAddr(var nAddr: TOPCProberIOAddress; const nStr: string);
var nIdx: Integer;
    nList: TStrings;
begin
  nList := TStringList.Create;
  try
    SplitStr(nStr, nList, 0 , ',');
    //���
    
    for nIdx:=Low(nAddr) to High(nAddr) do
    begin
      if nIdx < nList.Count then
           nAddr[nIdx] := nList[nIdx]
      else nAddr[nIdx] := cProber_NullASCII;
    end;
  finally
    nList.Free;
  end;
end;

//Date: 2016-09-05
//Parm: �����ļ�
//Desc: ��ȡOPC�ڵ�����
procedure TProberOPCManager.LoadConfig(const nFile: string);
var nXML: TNativeXml;
    i,j,nIdx: Integer;
    nRoot,nNode,nTmp: TXmlNode;

    nFolder: POPCFolder;
    nItem: POPCItem;
    nHost: POPCProberHost;
    nTunnel: POPCProberTunnel;
begin
  ClearFolders(False);
  ClearHosts(False);
  ClearTunnels(False);

  nXML := TNativeXml.Create;
  try
    nXML.LoadFromFile(nFile);
    //load config

    for nIdx:=0 to nXML.Root.NodeCount - 1 do
    begin
      nRoot := nXML.Root.Nodes[nIdx];
      //prober node

      New(nHost);
      FHosts.Add(nHost);

      with nHost^,nRoot do
      begin
        FID    := AttributeByName['id'];
        FName  := AttributeByName['name'];
        {$IFDEF DEBUG}
        WriteLog('Host: ' + FName);
        {$ENDIF}

        FServerObj := nil;
        FServerName := NodeByName('server').ValueAsString;
        FEnable := NodeByName('enable').ValueAsString <> 'N';

        nTmp := nRoot.FindNode('signal_in');
        if Assigned(nTmp) then
        begin
          FInSignalOn := StrToInt(nTmp.AttributeByName['on']);
          FInSignalOff := StrToInt(nTmp.AttributeByName['off']);
        end else
        begin
          FInSignalOn := 1;
          FInSignalOff := 0;
        end;

        nTmp := nRoot.FindNode('signal_out');
        if Assigned(nTmp) then
        begin
          FOutSignalOn := StrToInt(nTmp.AttributeByName['on']);
          FOutSignalOff := StrToInt(nTmp.AttributeByName['off']);
        end else
        begin
          FOutSignalOn := 1;
          FOutSignalOff := 0;
        end;
      end;

      //------------------------------------------------------------------------
      nRoot := nXML.Root.Nodes[nIdx].FindNode('tunnels');
      if not Assigned(nRoot) then Continue;

      for i:=0 to nRoot.NodeCount - 1 do
      begin
        nNode := nRoot.Nodes[i];
        New(nTunnel);
        FTunnels.Add(nTunnel);

        with nTunnel^,nNode do
        begin
          FID    := AttributeByName['id'];
          FName  := AttributeByName['name'];
          {$IFDEF DEBUG}
          WriteLog('Tunnel: ' + FName);
          {$ENDIF}

          FHost  := nHost;
          SplitAddr(FIn, NodeByName('in').ValueAsString);
          SplitAddr(FOut, NodeByName('out').ValueAsString);

          nTmp := nNode.FindNode('enable');
          FEnable := (not Assigned(nTmp)) or (nTmp.ValueAsString <> 'N');
        end;
      end;
                  
      //------------------------------------------------------------------------
      nRoot := nXML.Root.Nodes[nIdx].FindNode('folders');
      if not Assigned(nRoot) then Continue;
      
      for i:=0 to nRoot.NodeCount - 1 do
      begin
        nNode := nRoot.Nodes[i];
        New(nFolder);
        FFolders.Add(nFolder);

        with nFolder^,nNode do
        begin
          FID    := AttributeByName['id'];
          FName  := AttributeByName['name'];
          {$IFDEF DEBUG}
          WriteLog('Folder: ' + FName);
          {$ENDIF}

          FFolder := nil;
          FHost  := nHost;
          FItems := nil;

          nTmp := FindNode('item');
          if not Assigned(nTmp) then Continue;
          FItems := TList.Create;

          for j:=NodeCount-1 downto 0 do
          begin
            New(nItem);
            FItems.Add(nItem);

            with nNode.Nodes[j] do
            begin
              nItem.FID   := AttributeByName['id'];
              nItem.FName := AttributeByName['name'];
              nItem.FItem := nil;
              nItem.FGItem := nil;

              {$IFDEF DEBUG}
              WriteLog('Item: ' + nItem.FName);
              {$ENDIF}
            end;
          end;
        end;
      end
    end;
  finally
    nXML.Free;
  end;
end;

//------------------------------------------------------------------------------
//Date: 2016-09-06
//Parm: ����;������Ϣ;�㼶
//Desc: ����nHost������Ŀ¼�б�,�ϲ���FFolders��
function TProberOPCManager.LoadFolderItemList(const nHost: POPCProberHost;
  var nErr: string; var nLevel: Integer): Boolean;
var i,j,nIdx: Integer;
    nF: POPCFolder;
    nI: POPCItem;
    nItems: TdOPCBrowseItems;

    //ö���Ӷ���
    function EnumSub(const nBroser: TdOPCBrowser): Boolean;
    begin
      Result := True;

      if nBroser.MoveDown(nItems[nIdx]) then   //one level down
      try
        Inc(nLevel);
        Result := LoadFolderItemList(nHost, nErr, nLevel);
      finally
        nBroser.Moveup; //back to up level
        Dec(nLevel);
      end;
    end;
begin
  Result := False;
  nItems := nil;

  with nHost.FServerObj do
  try
    Browser.ShowBranches;
    nItems := TdOPCBrowseItems.Create;
    nItems.Assign(Browser.Items);

    for nIdx:=0 to nItems.Count - 1 do
    begin
      {$IFDEF DEBUG}
      with nItems[nIdx] do
      begin
        nErr := '����Ŀ¼:[ ID: %s, Name: %s, Path: %s ].';
        WriteLog(Format(nErr, [ItemId, Name, ItemPath]));
      end;
      {$ENDIF}
      
      i := GetItem(nF, nI, nItems[nIdx].Name, 2);
      if i < 0 then
      begin  
        if not EnumSub(Browser) then
          Exit;
        Continue;
      end;

      if Assigned(nI) then
      begin
        nErr := 'Ŀ¼[ %s.%s ]����Ŀ[ %s.%s ]��������ϵ�Ŀ¼����.';
        nErr := Format(nErr, [nF.FID, nF.FName, nI.FID, nI.FName]);

        WriteLog(nErr);
        Exit;
      end;

      if not Assigned(nF.FFolder) then
        nF.FFolder := TdOPCBrowseItem.Create;
      nF.FFolder.Assign(nItems[nIdx]);

      with nItems[nIdx] do
      begin
        nErr := 'ѡ��Ŀ¼:[ ID: %s, Name: %s, Path: %s ]';
        WriteLog(Format(nErr, [ItemId, Name, ItemPath]));
      end;

      if not EnumSub(Browser) then
        Exit;
      //get sub folder
    end;
  finally
    nItems.Free;
  end;

  if nLevel = 0 then //get folder done,try to get items
  with nHost.FServerObj do
  begin
    for nIdx:=FFolders.Count-1 downto 0 do
    begin
      nF := FFolders[nIdx];
      if not (Assigned(nF) and Assigned(nF.FFolder)) then Continue;

      Browser.Moveto(nF.FFolder);
      Browser.ShowLeafs(); //get all items in path

      for i:=Browser.Items.Count-1 downto 0 do
      begin
        {$IFDEF DEBUG}
        with Browser.Items[i] do
        begin
          nErr := '������Ŀ:[ ID: %s, Name: %s, Path: %s ].';
          WriteLog(Format(nErr, [ItemId, Name, ItemPath]));
        end;
        {$ENDIF}

        j := GetItem(nF, nI, Browser.Items[i].Name, 2);
        if j < 0 then Continue;

        if not Assigned(nI) then
        begin
          nErr := 'Ŀ¼[ %s.%s ]��������ϵ���Ŀ[ %s ]����.';
          nErr := Format(nErr, [nF.FID, nF.FName, Browser.Items[i].ItemId]);

          WriteLog(nErr);
          Exit;
        end;

        if not Assigned(nI.FItem) then
          nI.FItem := TdOPCBrowseItem.Create;
        nI.FItem.Assign(Browser.Items[i]);

        with Browser.Items[i] do
        begin
          nErr := 'ѡ����Ŀ:[ ID: %s, Name: %s, Path: %s ]';
          WriteLog(Format(nErr, [ItemId, Name, ItemPath]));
        end;
      end;
    end;
  end;
  
  Result := True;
end;

//Date: 2016-09-06
//Parm: ����;������Ϣ
//Desc: ���nHost��������Ŀ����
function TProberOPCManager.BuildOPCGroup(const nHost: POPCProberHost;
  var nErr: string): Boolean;
var i,nIdx: Integer;
    nF: POPCFolder;
    nI: POPCItem;
    nGroup: TdOPCGroup;
begin
  with nHost.FServerObj do
  for nIdx:=FFolders.Count-1 downto 0 do
  begin
    nF := FFolders[nIdx];
    if not (Assigned(nF) and Assigned(nF.FFolder)) then Continue;

    nGroup := OPCGroups.GetOPCGroup(nF.FID);
    if not Assigned(nGroup) then
      nGroup := OPCGroups.Add(nF.FID);
    nGroup.OPCItems.RemoveAll;

    if not Assigned(nF.FItems) then Continue;
    //no item in folder

    for i:=nF.FItems.Count-1 downto 0 do
    begin
      nI := nF.FItems[i];
      if Assigned(nI) and Assigned(nI.FItem) then
        nI.FGItem := nGroup.OPCItems.AddItem(nI.FItem.ItemId)
      //xxxxx
    end;
  end;

  Result := True;
end;

//Date: 2016-09-05
//Parm: ������Ϣ
//Desc: �������ӷ�����
function TProberOPCManager.ConnectOPCServer(var nErr: string;
 const nHost: POPCProberHost): Boolean;
var nIdx,nLevel: Integer;
    nList: TStrings;
    nPHost: POPCProberHost;
begin
  Result := False;
  nErr := '����ʧ��.';
  DisconnectServer(nHost);
 
  nList := TStringList.Create;
  try
    GetOPCDAServers(nList);
    //enum all server

    for nIdx:=0 to FHosts.Count-1 do
    begin
      nPHost := FHosts[nIdx];
      if not (Assigned(nPHost) and nPHost.FEnable) then Continue;

      if nList.IndexOf(nPHost.FServerName) < 0 then
      begin
        nErr := '����[ %s.%s ]δ����[ %s ]����.';
        nErr := Format(nErr, [nPHost.FID, nPHost.FName, nPHost.FServerName]);
        
        WriteLog(nErr);
        Exit;
      end;
    end;
  finally
    nList.Free;
  end; 

  for nIdx:=0 to FHosts.Count-1 do
  begin
    nPHost := FHosts[nIdx];
    if not (Assigned(nPHost) and nPHost.FEnable) then Continue;
    if ((not Assigned(nHost)) and (nHost = nPHost)) then Continue;

    if not Assigned(nPHost.FServerObj) then
    begin
      nPHost.FServerObj := TdOPCServer.Create(nil);
      nPHost.FServerObj.ServerName := nPHost.FServerName;
    end;

    nPHost.FServerObj.Active := True;
    nLevel := 0;
    if not (LoadFolderItemList(nPHost, nErr, nLevel) and
            BuildOPCGroup(nPHost, nErr)) then Exit;
    //any error
  end;

  nErr := '';
  Result := True;
  FWriteTimer.Enabled := True;
end;

//Date: 2016-09-06
//Desc: �Ͽ�������
procedure TProberOPCManager.DisconnectServer(const nHost: POPCProberHost);
var i,j,nIdx: Integer;
    nF: POPCFolder;
    nI: POPCItem;
    nPHost: POPCProberHost;
begin
  FWriteTimer.Enabled := False;
  //close writer

  for nIdx:=0 to FHosts.Count-1 do
  begin
    nPHost := FHosts[nIdx];
    if not (Assigned(nPHost) and Assigned(nPHost.FServerObj)) then Continue;
    if ((not Assigned(nHost)) and (nHost = nPHost)) then Continue;

    for i:=FFolders.Count-1 downto 0 do
    begin
      nF := FFolders[i];
      if not (Assigned(nF) and (nF.FHost = nPHost)) then Continue;

      FreeAndNil(nF.FFolder);
      if not Assigned(nF.FItems) then Continue;

      for j:=nF.FItems.Count-1 downto 0 do
      begin
        nI := nF.FItems[j];
        if Assigned(nI) and Assigned(nI.FItem) then
          FreeAndNil(nI.FItem);
        nI.FGItem := nil;
      end;
    end;

    nPHost.FServerObj.Active := False;
  end;
end;

//------------------------------------------------------------------------------
//Date: 2016-09-06
//Parm: ͨ����ʶ;����
//Desc: ����nTunnel�Ĵ򿪹ر�
function TProberOPCManager.TunnelOC(const nTunnel: string; nOC: Boolean): string;
var nIdx,nVal: Integer;
    nW: POPCWriteItem;
    nF: POPCFolder;
    nI: POPCItem;
    nT: POPCProberTunnel;
begin
  Result := '';
  nIdx := GetTunnel(nTunnel);

  if nIdx < 0 then
  begin
    Result := Format('ͨ�����[ %s ]��Ч.', [nTunnel]);
    WriteLog(Result);
    Exit;
  end;

  nT := FTunnels[nIdx];
  if not nT.FEnable then Exit;

  if nOC then
       nVal := nT.FHost.FOutSignalOn
  else nVal := nT.FHost.FOutSignalOff;

  FSyncLock.Enter;
  try
    for nIdx:=Low(nT.FOut) to High(nT.FOut) do
    begin
      if nT.FOut[nIdx] = cProber_NullASCII then Continue;
      //invalid out address

      GetItem(nF, nI, nT.FOut[nIdx]);
      //get opc item

      if not (Assigned(nI) and Assigned(nI.FGItem)) then
      begin
        Result := 'ͨ��[ %s ]����ڵ�[ %s ]��OPC����Ч.';
        Result := Format(Result, [nTunnel, nT.FOut[nIdx]]);

        WriteLog(Result);
        Exit;
      end;

      {$IFDEF DEBUG}
      with nI.FGItem do
      begin
        WriteLog(Format('д��:[ T: %s, I: %s, V: %d ].', [nTunnel, ItemID, nVal]));
      end;
      {$ENDIF}

      nW := gMemDataManager.LockData(FIDWriteData);
      FWriteList.Add(nW);

      nW.FAction := waWrite;
      nW.FHost := nF.FHost.FID;
      nW.FFolder := nF.FID;

      nW.FItem := nI.FID;
      nW.FValue := nVal;
      nW.FEnable := True;

      //nI.FGItem.WriteSync(nVal);
      //write data
    end;
  finally
    FSyncLock.Leave;
  end;
end;

//Date: 2016-09-06
//Parm: ͨ����ʶ
//Desc: ��nTunnelͨ��
function TProberOPCManager.OpenTunnel(const nTunnel: string): Boolean;
begin
  Result := TunnelOC(nTunnel, True) = '';
end;

//Date: 2016-09-06
//Parm: ͨ����ʶ
//Desc: �ر�nTunnelͨ��
function TProberOPCManager.CloseTunnel(const nTunnel: string): Boolean;
begin
  Result := TunnelOC(nTunnel, False) = '';
end;

//Date: 2016-09-07
//Parm: ͨ����ʶ
//Desc: �ж�nTunnel�����������ź�
function TProberOPCManager.IsTunnelOK(const nTunnel: string): Boolean;
var nStr,nHost,nFolder: string;
    nIdx,nVal: Integer;
    nF: POPCFolder;
    nI: POPCItem;
    nT: POPCProberTunnel;
begin
  Result := False;
  nIdx := GetTunnel(nTunnel);

  if nIdx < 0 then
  begin
    nStr := Format('ͨ�����[ %s ]��Ч.', [nTunnel]);
    WriteLog(nStr);
    Exit;
  end;

  nT := FTunnels[nIdx];
  if not nT.FEnable then
  begin
    Result := True;
    Exit;
  end;

  nHost := '';
  nFolder := '';
  //init

  FSyncLock.Enter;
  try
    for nIdx:=Low(nT.FIn) to High(nT.FIn) do
    try
      if nT.FIn[nIdx] = cProber_NullASCII then Continue;
      //invalid out address

      GetItem(nF, nI, nT.FIn[nIdx]);
      //get opc item

      if not (Assigned(nI) and Assigned(nI.FGItem)) then
      begin
        nStr := 'ͨ��[ %s ]����ڵ�[ %s ]��OPC����Ч.';
        WriteLog(Format(nStr, [nTunnel, nT.FIn[nIdx]]));
        Exit;
      end;

      if nHost = '' then
        nHost := nF.FHost.FID;
      if nFolder = '' then
        nFolder := nF.FID;
      //xxxxx

      nStr := nI.FGItem.ValueStr;
      //get data

      if CompareText(nStr, 'True') = 0 then
      begin
        nVal := 1;
      end else

      if CompareText(nStr, 'False') = 0 then
      begin
        nVal := 0;
      end else
      begin
        if not IsNumber(nStr, False) then
        begin
          nStr := 'ͨ��[ %s ]�����[ %s ]������Ч.';
          WriteLog(Format(nStr, [nTunnel, nT.FIn[nIdx]]));
          Exit;
        end;

        nVal := StrToInt(nStr);
      end;

      {$IFDEF DEBUG}
      with nI.FGItem do
      begin
        nStr := '��ȡ:[ T: %s, I: %s, V: %d ].';
        WriteLog(Format(nStr, [nTunnel, ItemID, nVal]));
      end;
      {$ENDIF}

      if nVal <>  nT.FHost.FInSignalOn then Exit;
      //no single,check failure
    except
      on E: Exception do
      begin
        WriteLog('IsTunnelOK Error: ' + E.Message);
        ReConnectOPCServer(nHost, nFolder);
        Exit;
      end;
    end;
  finally
    FSyncLock.Leave;
  end;

  Result := True;
end;

//Date: 2016-09-08
//Parm: ������ʶ;Ŀ¼��ʶ
//Desc: �����߳�Ͷ������������ָ��
procedure TProberOPCManager.ReConnectOPCServer(const nHost,nFolder: string);
var nIdx: Integer;
    nW: POPCWriteItem;
begin
  FSyncLock.Enter;
  try
    for nIdx:=FWriteList.Count-1 downto 0 do
    begin
      nW := FWriteList[nIdx];
      if nW.FAction = waConnSrv then Exit;
      //command has exits
    end;

    nW := gMemDataManager.LockData(FIDWriteData);
    FWriteList.Insert(0, nW);
    nW.FAction := waConnSrv;

    nW.FHost := nHost;
    nW.FFolder := nFolder;
    nW.FEnable := True;
  finally
    FSyncLock.Leave;
  end;
end;

//------------------------------------------------------------------------------
//Date: 2016-09-08
//Desc: ���߳�ҵ��
procedure TProberOPCManager.OnWriteTimer(Sender: TObject);
var nIdx: Integer;
begin
  FSyncLock.Enter;
  try
    if FWriteList.Count < 1 then
      Exit;
    nIdx := 0;

    while True do
    try
      if WriteOPCData then
           nIdx := 2
      else Inc(nIdx);

      if nIdx > 1 then
      begin
        ClearWriteList(False);
        Break;
      end;
    except
      Inc(nIdx);
    end;
  finally
    FSyncLock.Leave;
  end;
end;

//Date: 2016-09-08
//Desc:
function TProberOPCManager.WriteOPCData: Boolean;
var nStr: string;
    nIdx: Integer;
    nF: POPCFolder;
    nI: POPCItem;
    nW: POPCWriteItem;
begin
  Result := False;
  //default val
  nW := nil;
  
  for nIdx:=0 to FWriteList.Count - 1 do
  try
    nW := FWriteList[nIdx];
    if not nW.FEnable then Continue;

    if nW.FAction = waConnSrv then
    begin
      nW.FEnable := False;
      ConnectOPCServer(nStr, GetHost(nW.FHost));
      Continue;
    end;

    GetItem(nF, nI, nW.FItem);
    //get opc item

    if not (Assigned(nI) and Assigned(nI.FGItem)) then
    begin
      nStr := '��Ŀ�ڵ�[ %s ]��OPC������Ч.';
      nStr := Format(nStr, [nW.FItem]);

      WriteLog(nStr);
      nW.FEnable := False;
      Continue;
    end;

    nI.FGItem.WriteSync(nW.FValue);
    //write data
    nW.FEnable := False;
  except
    on E: Exception do
    begin
      WriteLog('���̲߳���ʧ��,����: ' + E.Message);
      if Assigned(nW) then
        ConnectOPCServer(nStr, GetHost(nW.FHost));
      Exit;
    end;
  end;

  Result := True;
end;

initialization
  gProberOPCManager := nil;
finalization
  FreeAndNil(gProberOPCManager);
end.
