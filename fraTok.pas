unit fraTok;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox,
  FireDAC.Comp.Client, uUserStore, uNavFrames;

type
  TfraTok = class(TFrame)
    Layout1: TLayout;
    Layout2: TLayout;
    rectHeader: TRectangle;
    lblBack: TLabel;
    lblTitle: TLabel;
    Layout3: TLayout;
    lblUkupnoTitle: TLabel;
    rectUkupnoUlaz: TRectangle;
    lblUkupnoUlazBroj: TLabel;
    lblUkupnoUlazTekst: TLabel;
    rectUkupnoArtikli: TRectangle;
    lblUkupnoArtikliBroj: TLabel;
    lblUkupnoArtikliTekst: TLabel;
    lblListaTitle: TLabel;
    lstTok: TListBox;
    Layout4: TLayout;
    rectNav: TRectangle;
    procedure lblBackClick(Sender: TObject);
    procedure Loaded; override;
  private
    procedure UcitajTok;
    procedure UcitajUkupno;
  public
  end;

implementation
{$R *.fmx}

procedure TfraTok.Loaded;
begin
  inherited;
  UcitajUkupno;
  UcitajTok;
end;

procedure TfraTok.lblBackClick(Sender: TObject);
begin
  TNavFrames.Back;
end;

procedure TfraTok.UcitajUkupno;
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;

    // Ukupan ulaz
    Q.SQL.Text := 'SELECT COALESCE(SUM(KolicinaNarucena), 0) FROM STAVKA_NARUDZBINE';
    Q.Open;
    lblUkupnoUlazBroj.Text := FormatFloat('0.#', Q.Fields[0].AsFloat);
    Q.Close;

    // Ukupan broj artikala
    Q.SQL.Text := 'SELECT COUNT(*) FROM RESURS';
    Q.Open;
    lblUkupnoArtikliBroj.Text := Q.Fields[0].AsString;
    Q.Close;

  finally
    Q.Free;
  end;
end;

procedure TfraTok.UcitajTok;
var
  Q: TFDQuery;
  Item: TListBoxItem;
  rectKartica, rectTraka, rectBarBG, rectBarFill: TRectangle;
  layKartica, layBar: TLayout;
  lblNaziv, lblUlaz, lblStanje, lblKategorija: TLabel;
  UkupanUlaz, TrenutnaKolicina, MaxUlaz: Double;
  Procenat: Double;
  Boja: TAlphaColor;
begin
  lstTok.BeginUpdate;
  try
    lstTok.Clear;

    // Prvo nadji max ulaz za normalizaciju bara
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := DB;
      Q.SQL.Text :=
        'SELECT MAX(UkupanUlaz) FROM (' +
        '  SELECT COALESCE(SUM(SN.KolicinaNarucena), 0) as UkupanUlaz ' +
        '  FROM RESURS R ' +
        '  LEFT JOIN STAVKA_NARUDZBINE SN ON SN.SifraResursa = R.SifraResursa ' +
        '  GROUP BY R.SifraResursa' +
        ')';
      Q.Open;
      MaxUlaz := Q.Fields[0].AsFloat;
      if MaxUlaz <= 0 then MaxUlaz := 1;
      Q.Close;

      // Ucitaj tok po artiklima
      Q.SQL.Text :=
        'SELECT R.Naziv, R.Kategorija, R.JedinicaMere, ' +
        '       R.TrenutnaKolicina, ' +
        '       COALESCE(SUM(SN.KolicinaNarucena), 0) as UkupanUlaz, ' +
        '       COUNT(SN.IDStavke) as BrojNabavki ' +
        'FROM RESURS R ' +
        'LEFT JOIN STAVKA_NARUDZBINE SN ON SN.SifraResursa = R.SifraResursa ' +
        'GROUP BY R.SifraResursa ' +
        'ORDER BY UkupanUlaz DESC';
      Q.Open;

      while not Q.Eof do
      begin
        UkupanUlaz      := Q.FieldByName('UkupanUlaz').AsFloat;
        TrenutnaKolicina := Q.FieldByName('TrenutnaKolicina').AsFloat;

        // Boja po kategoriji
        var Kat := LowerCase(Q.FieldByName('Kategorija').AsString);
        if Kat = 'hrana' then Boja := $FF22C55E
        else if Kat = 'lek' then Boja := $FFEF4444
        else if Kat = 'kozmetika' then Boja := $FF8B5CF6
        else Boja := $FF3B82F6;

        Item := TListBoxItem.Create(lstTok);
        Item.Height := 100;
        Item.StyleLookup := '';

        rectKartica := TRectangle.Create(Item);
        rectKartica.Parent := Item;
        rectKartica.Align := TAlignLayout.Client;
        rectKartica.Margins.Left   := 4;
        rectKartica.Margins.Right  := 4;
        rectKartica.Margins.Top    := 4;
        rectKartica.Margins.Bottom := 4;
        rectKartica.Fill.Color := TAlphaColors.White;
        rectKartica.Stroke.Color := $FFE5E7EB;
        rectKartica.Stroke.Thickness := 1;
        rectKartica.XRadius := 10;
        rectKartica.YRadius := 10;

        rectTraka := TRectangle.Create(rectKartica);
        rectTraka.Parent := rectKartica;
        rectTraka.Align := TAlignLayout.Left;
        rectTraka.Width := 6;
        rectTraka.Fill.Color := Boja;
        rectTraka.Stroke.Kind := TBrushKind.None;
        rectTraka.XRadius := 10;
        rectTraka.YRadius := 10;

        layKartica := TLayout.Create(rectKartica);
        layKartica.Parent := rectKartica;
        layKartica.Align := TAlignLayout.Client;
        layKartica.Padding.Left   := 12;
        layKartica.Padding.Right  := 12;
        layKartica.Padding.Top    := 8;
        layKartica.Padding.Bottom := 8;

        lblNaziv := TLabel.Create(layKartica);
        lblNaziv.Parent := layKartica;
        lblNaziv.Align := TAlignLayout.Top;
        lblNaziv.Height := 20;
        lblNaziv.Text := UpperCase(Q.FieldByName('Naziv').AsString);
        lblNaziv.StyledSettings := [];
        lblNaziv.TextSettings.Font.Size := 13;
        lblNaziv.TextSettings.Font.Style := [TFontStyle.fsBold];
        lblNaziv.TextSettings.FontColor := $FF111827;

        lblKategorija := TLabel.Create(layKartica);
        lblKategorija.Parent := layKartica;
        lblKategorija.Align := TAlignLayout.Top;
        lblKategorija.Height := 15;
        lblKategorija.Text := Q.FieldByName('Kategorija').AsString +
          '  |  ' + Q.FieldByName('BrojNabavki').AsString + ' nabavki';
        lblKategorija.StyledSettings := [];
        lblKategorija.TextSettings.Font.Size := 10;
        lblKategorija.TextSettings.FontColor := $FF9CA3AF;

        lblUlaz := TLabel.Create(layKartica);
        lblUlaz.Parent := layKartica;
        lblUlaz.Align := TAlignLayout.Top;
        lblUlaz.Height := 15;
        lblUlaz.Margins.Top := 2;
        lblUlaz.Text := 'Ukupan ulaz: ' + FormatFloat('0.#', UkupanUlaz) +
                        ' ' + Q.FieldByName('JedinicaMere').AsString +
                        '   Na stanju: ' + FormatFloat('0.#', TrenutnaKolicina) +
                        ' ' + Q.FieldByName('JedinicaMere').AsString;
        lblUlaz.StyledSettings := [];
        lblUlaz.TextSettings.Font.Size := 11;
        lblUlaz.TextSettings.Font.Style := [TFontStyle.fsBold];
        lblUlaz.TextSettings.FontColor := Boja;

        // Progress bar
        layBar := TLayout.Create(layKartica);
        layBar.Parent := layKartica;
        layBar.Align := TAlignLayout.Top;
        layBar.Height := 10;
        layBar.Margins.Top := 6;

        rectBarBG := TRectangle.Create(layBar);
        rectBarBG.Parent := layBar;
        rectBarBG.Align := TAlignLayout.Client;
        rectBarBG.Fill.Color := $FFE5E7EB;
        rectBarBG.Stroke.Kind := TBrushKind.None;
        rectBarBG.XRadius := 5;
        rectBarBG.YRadius := 5;

        Procenat := UkupanUlaz / MaxUlaz;

        rectBarFill := TRectangle.Create(layBar);
        rectBarFill.Parent := layBar;
        rectBarFill.Align := TAlignLayout.Left;
        rectBarFill.Width := 300 * Procenat;
        rectBarFill.Fill.Color := Boja;
        rectBarFill.Stroke.Kind := TBrushKind.None;
        rectBarFill.XRadius := 5;
        rectBarFill.YRadius := 5;

        lstTok.AddObject(Item);
        Q.Next;
      end;

      if lstTok.Count = 0 then
      begin
        Item := TListBoxItem.Create(lstTok);
        Item.Height := 60;
        Item.Text := 'Nema podataka o nabavkama.';
        lstTok.AddObject(Item);
      end;

    finally
      Q.Free;
    end;
  finally
    lstTok.EndUpdate;
  end;
end;

end.
