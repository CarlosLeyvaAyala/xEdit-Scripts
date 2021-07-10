unit DM_SelectPlugin;
uses xEditApi;

procedure _DMSP_LimitChecked( AChkLb : TCheckListBox; AMaxCheck : Integer );
var
  LIdx : Integer;
  LCheckCount : Integer;
begin
  // counting
  LCheckCount := 0;
  for LIdx := 0 to AChkLb.Items.Count - 1 do
    if AChkLb.Checked[LIdx] then
      if LCheckCount = AMaxCheck then AChkLb.Checked[LIdx] := False
      else Inc( LCheckCount );
  // enable/disable
  for LIdx := 0 to AChkLb.Items.Count - 1 do
    AChkLb.ItemEnabled[LIdx] := AChkLb.Checked[LIdx] or ( LCheckCount < AMaxCheck );
end;

procedure _DMSP_OnClickCheckSingle(Sender: TObject);
begin
  _DMSP_LimitChecked(TCheckListBox(Sender), 1);
end;

function _DMSP_Init(aFrm: TForm; aCaption: string): TCheckListBox;
begin
    aFrm.Caption := aCaption;
    aFrm.Width := 800;
    Result := TCheckListBox(aFrm.FindComponent('CheckListBox1'));
end;

// aAll   Add all files?
procedure _DMSP_PopulateFiles(clb: TCheckListBox; aAll: Boolean);
var
  i: integer;
begin
  if aAll then
    for i := 0 to FileCount - 1 do
      clb.Items.AddObject(GetFileName(FileByIndex(i)), FileByIndex(i));
end;

function GetPlugin(aCaption: string): IInterface;
var
  frm: TForm;
  clb: TCheckListBox;
  i: integer;
  r: IInterface;
begin
  frm := frmFileSelect;
  try
    clb := _DMSP_Init(frm, aCaption);
    clb.OnClickCheck := _DMSP_OnClickCheckSingle;
    clb.AllowGrayed := false;
    _DMSP_PopulateFiles(clb, true);

    Result := nil;

    // get the first checked file
    if frm.ShowModal = mrOk then
      for i := 0 to clb.Items.Count - 1 do
        if clb.Checked[i] then
          Result := ObjectToElement(clb.Items.Objects[i]);

    //       if not SameText(MastersList(GetFile(e)), MastersList(fromPlugin)) then begin
    //         AddMessage('Masters do not match between plugins!');
    //         fromPlugin := nil;
    //       end;
    //       Break;
    //     end;
    // end;

  finally
    frm.Free;
  end;
end;

end.
