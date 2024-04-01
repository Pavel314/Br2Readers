{$reference System.Drawing.dll}
uses System,System.Drawing,System.IO,System.Runtime.InteropServices,System.Drawing.Imaging;
const
  tex = 'A1_MANSION_LX_1.TEX';

type
  TexFileType = (Indexed24=1, Indexed24Alpha=2, Raw32=3 );
  
  TexFileBase = abstract class
  protected 
    _TexType: TexFileType;
  public 
    Size: Size;
    function GetType()  := _TexType;
    function GetPixels(): array[,] of Color; abstract;
  
  end;
  
  TexFileIndexed24Base = class(TexFileBase)
  public 
    Indexs: List<byte> := new List<byte>();
    Table: List<Color> := new List<Color>();  
  end;
  
  
  TexFileIndexed24Alpha = class(TexFileIndexed24Base)
  public 
    AlphaData: List<byte> := new List<byte>();
    constructor create();
    begin
      self._TexType := TexFileType.Indexed24Alpha;
    end;
    
    function GetPixels(): array[,] of Color; override;
    begin
      SetLength(Result, Size.Width, Size.Height);
      var x := 0;
      var y := 0;
      for var i := 0 to Result.Length - 1 do
      begin
        var col := self.Table[self.Indexs[i]];
        Result[x, y] := Color.FromArgb(self.AlphaData[i], col.R, col.G, col.B);
        x += 1;
        if x >= Size.Width then
        begin
          x := 0;
          y += 1;
        end;
      end;
      
      
    end;
  
  end;
  TexFileIndexed24 = class(TexFileIndexed24Base)
  public 
    constructor create();
    begin
      self._TexType := TexFileType.Indexed24;
    end;
    
    function GetPixels(): array[,] of Color; override;
    begin
      SetLength(Result, Size.Width, Size.Height);
      var x := 0;
      var y := 0;
      for var i := 0 to Result.Length - 1 do
      begin
        Result[x, y] := self.Table[self.Indexs[i]];
        x += 1;
        if x >= Size.Width then
        begin
          x := 0;
          y += 1;
        end;
      end;
    end;
  end;
  TexFileRaw32 = class(TexFileBase)
  public 
    Colors: List<Color> := new List<Color>();
    constructor create();
    begin
      self._TexType := TexFileType.Raw32;
    end;
    
    function GetPixels(): array[,] of Color; override;
    begin
      SetLength(Result, Size.Width, Size.Height);
      var x := 0;
      var y := 0;
      for var i := 0 to Result.Length - 1 do
      begin
        Result[x, y] := self.Colors[i];
        x += 1;
        if x >= Size.Width then
        begin
          x := 0;
          y += 1;
        end;
      end;
    end;
  end;

function Stream.ReadTryByte:byte;
begin
var r:=self.ReadByte();
if r=-1 then r:=0;
result:=r;

end;


function Import(fs: Stream): TexFileBase;
begin
  var br := new BinaryReader(fs);
  var h := br.ReadInt32();
  
  var tp := TexFileType(fs.ReadByte());
  fs.Seek(8, SeekOrigin.Begin);
  var size := new Size(br.ReadInt32(), br.ReadInt32());
  
  var last :=  size.Width * size.Height - 1;
  
  
  
  fs.Seek(32, SeekOrigin.Begin);
  
  var res: TexFileBase;
  if (tp = TexFileType.Indexed24Alpha) or (tp = TexFileType.Indexed24) then
  begin
    var r: TexFileIndexed24Base;
    
    if tp = TexFileType.Indexed24Alpha then r := new TexFileIndexed24Alpha() else r := new TexFileIndexed24();
    r.Size := size; 
    
    
    for var i := 0 to 255 do
      r.Table.Add(Color.FromArgb(255, fs.ReadTryByte(), fs.ReadTryByte(), fs.ReadTryByte()));
    for var i := 0 to last do
      r.Indexs.Add(fs.ReadTryByte());
    
    if tp = TexFileType.Indexed24Alpha then
    begin
      var ar := TexFileIndexed24Alpha(r);
      for var i := 0 to last do
        ar.AlphaData.Add(fs.ReadTryByte());
    end;    
    Result := TexFileBase(r); 
  end else
  if (tp = TexFileType.Raw32) then
  begin
    var r := new TexFileRaw32();
    r.Size := size;
    for var i := 0 to last do
    begin
      var col := Color.FromArgb(fs.ReadTryByte(), fs.ReadTryByte(), fs.ReadTryByte(), fs.ReadTryByte());
      //r.Colors.Add(Color.FromArgb(col.A,col.B,col.G,col.R ));
      r.Colors.Add(Color.FromArgb(col.B, col.G, col.R, col.A ));
    end;
    Result := TexFileBase(r);
  end;
end;


begin
var imgformat:=ImageFormat.Tiff;


  var fls := System.IO.Directory.GetFiles('D:\Games\BloodRayne 2\tests\_04_ReaderBFM\All\texts\','*.tex');
  for var ii := 0 to fls.Length - 1 do
  begin
    
    var fs := new FileStream(fls[ii], Filemode.Open);
       Writeln(fls[ii]);
  //  Sleep(1000);
    
    var res := Import(fs);
    
    
    
    
    var pix := res.GetPixels();
    var bmp := new Bitmap(res.Size.Width, res.Size.Height, PixelFormat.Format32bppArgb);
    for var i := 0 to bmp.Width - 1 do
      for var j := 0 to bmp.Height - 1 do
        bmp.SetPixel(i, bmp.Height - 1 - j, pix[i, j]);
    
 //   var save := System.IO.Path.ChangeExtension(fs.Name, 'bmp');
    
     bmp.Save(Path.ChangeExtension(fs.Name,'.tif'),imgformat);    
     bmp.Dispose();
    fs.Dispose();
  end;
  

  
end.