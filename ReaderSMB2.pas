uses System,System.IO,System.Globalization;
const
  smb = '~RAYNE.SMB';//TODO Impact Venchicle_camaro

type
  SmbHeader = record
  public 
    Objects: integer;
    MaterialCounts: integer;
    CollissionModels: integer;
    Unkown: integer;
    ImpactPoints: integer;
    AlphaByte: integer;
  end;
  
  
  
  SMBMaterial = record
  public 
    isAlpha: boolean;
    TextureName: string;
    BumpmapName: string;
    GlossmapName: string;
  end;
  
  Point3D = class(IEquatable<Point3D>)
  public 
    X, Y, Z: single;
    constructor create(X_, Y_, Z_: single);
    begin
      X := X_;
      Y :=Y_;
      Z :=Z_;
    end;
    
    function Equals(p: Point3D): boolean;
    begin
      Result := (X = p.X) and (Y = p.Y) and (Z = p.Z); 
    end;
    
    function R(value: single): single;
    begin
      Result := Math.Round(value, 4);
    end;
  
  private 
    _culture := CultureInfo.InvariantCulture;
  public 
    function ToString(): string; override;
    begin
      Result := string.Format('{0} {1} {2}', Convert.ToString(x, _culture), Convert.ToString(y, _culture), Convert.ToString(z, _culture));  
    end;
  end;
  
  
  Point2D = class(IEquatable<Point2D>)
  public 
    X, Y: single;
    constructor create(X_, Y_: single);
    begin
      X :=X_;
      Y :=Y_;
    end;
    
    function Equals(p: Point2D): boolean;
    begin
      Result := (X = p.X) and (Y = p.Y); 
    end;
  
  private 
    _culture := CultureInfo.InvariantCulture;
  public 
    function ToString(): string; override;
    begin
      Result := string.Format('{0} {1}', Convert.ToString(x, _culture), Convert.ToString(y, _culture));   
    end;
  end;
  
  
  VerInfo = class(IEquatable<VerInfo>)//record ABC.Net Crash Compile
  public 
    Vertex: Point3D;
    Normal: Point3D;
    TVertex: Point2D;
    
    function Equals(v: VerInfo): boolean;
    begin
      Result := (Vertex.Equals(v.Vertex) ) and (Normal.Equals(v.Normal)) and (TVertex.Equals(v.TVertex));
    end;
  
  end;
  SMBMeshInfo = record
  public 
    Name: string;
    Verts: cardinal;
    Trins: cardinal;
    MaterialIndex: word;
    Length: integer;
    Info: List<VerInfo> := new List<VerInfo>();
    Indexs: List<word> := new List<word>();
  
  end;



function Stream.ReadTryString(ReservedLen: integer): string;
begin
  var arr := new byte[ReservedLen];
  self.Read(arr, 0, arr.Length);
  
  for var i := 0 to arr.Length - 1 do
  begin
    if arr[i] = 0 then
      break;
    result += char(arr[i]); 
  end;
  arr := nil;
end;

function Stream.ReadTryString(): string;
begin
  for var i := 0 to self.Length - 1 do
  begin
    var b := self.ReadByte();
    if b = 0 then exit;
    result += char(b);
    
  end;
  
end;



procedure ReadMeshHeader(fs: Stream; var result: SMBMeshInfo);
begin
  var arr := new byte[86];
  fs.Read(arr, 0, arr.Length);
  
  for var ii := 0 to arr.Length - 1 do
  begin
    if (arr[ii] = 0) then
      break;
    Result.Name += char(arr[ii]);
  end;
  Result.Length := BitConverter.ToInt32(arr, 66);
  Result.Verts := BitConverter.ToInt32(arr, 74);
  Result.Trins := BitConverter.ToInt32(arr, 78);
  result.MaterialIndex := BitConverter.ToUInt16(arr, 32);
end;

procedure ReadVertexData(fs: Stream; var ver: VerInfo);
begin
  var block := new byte[80];
  fs.Read(block, 0, block.Length);
  ver.Vertex := new Point3D(BitConverter.ToSingle(block, 0), BitConverter.ToSingle(block, 4), BitConverter.ToSingle(block, 8));
  ver.Normal := new Point3D(BitConverter.ToSingle(block, 12), BitConverter.ToSingle(block, 16), BitConverter.ToSingle(block, 20));
  ver.TVertex := new Point2D(BitConverter.ToSingle(block, 24), BitConverter.ToSingle(block, 28));
end;

procedure ExportData(fn,matfn:string;data: array of SMBMeshInfo);
begin
  var expfs := new System.IO.StreamWriter(fn, false, Text.Encoding.ASCII);
  expfs.WriteLine(string.Format('mtllib {0}', matfn));
  
  
  var trinoff := 0;
  for var i := 0 to data.Length - 1  do  
  begin
    
    
    for var j := 0 to data[i].Info.Count - 1 do
    begin
      expfs.WriteLine('v ' + data[i].Info[j].Vertex.ToString());
      expfs.WriteLine('vt ' + data[i].Info[j].TVertex.ToString());
      expfs.WriteLine('vn ' + data[i].Info[j].Normal.ToString());
    end;
    
    expfs.WriteLine(string.Format('g {0}', data[i].Name));
    expfs.WriteLine(string.Format('usemtl {0}', data[i].MaterialIndex));
    expfs.WriteLine(string.Format('s {0}', 1));
    
    var ind := 0;
    while ind < data[i].Indexs.Count do
    begin
      expfs.WriteLine(string.Format('f {0}/{0}/{0} {1}/{1}/{1} {2}/{2}/{2}', data[i].Indexs[ind] + 1 + trinoff, data[i].Indexs[ind + 1] + 1 + trinoff, data[i].Indexs[ind + 2] + 1 + trinoff));
      ind += 3;
    end;
    
    trinoff += data[i].Verts;
  end;
  expfs.Flush();
  expfs.Dispose();
end;

procedure ExportMaterial(fn:string;mats: array of SMBMaterial);
begin
  var expfs := new StreamWriter(fn, false, Text.Encoding.ASCII);
  
  for var i := 0 to mats.Length - 1  do  
  begin
    expfs.WriteLine('newmtl {0}', i);
    if not string.IsNullOrEmpty(mats[i].TextureName) then
    expfs.WriteLine(string.Format('map_Kd .\{0}', mats[i].TextureName));
    if not string.IsNullOrEmpty(mats[i].BumpmapName) then
    expfs.WriteLine(string.Format('map_Kb .\{0}',mats[i].BumpmapName));
    if not string.IsNullOrEmpty(mats[i].GlossmapName) then
   expfs.WriteLine(string.Format('map_Kg .\{0}',mats[i].GlossmapName));
  end;
  expfs.Flush();
  expfs.Dispose();
end;
procedure Export(fn:string);
begin
  var fs := new FileStream(fn, FileMode.Open);
  var br := new BinaryReader(fs);
  br.ReadInt32();
  
  var h := new SmbHeader();
  
  h.Objects := br.ReadInt32();
  h.CollissionModels := br.ReadInt32();
  h.ImpactPoints := br.ReadInt32();
  h.MaterialCounts := br.ReadInt32();
  h.Unkown := br.ReadInt32();
  
  
  
  fs.Seek(8, SeekOrigin.Current);
  h.AlphaByte := br.ReadInt32();
  fs.Seek(8, SeekOrigin.Current);
  
  var mats := new SMBMaterial[h.MaterialCounts];
  
  for var i := 0 to mats.Length - 1 do
  begin
    mats[i].TextureName := fs.ReadTryString(72);
    mats[i].BumpmapName := fs.ReadTryString(72);
    mats[i].GlossmapName := fs.ReadTryString(72);
    mats[i].isAlpha := h.AlphaByte = 8;
    
    fs.Seek(144, SeekOrigin.Current);
  end;
  fs.Seek(8, SeekOrigin.Current);
  
  
  
  
  var mesh := new SMBMeshINFO[h.Objects];
  
  for var i := 0 to mesh.length - 1 do
    ReadMeshHeader(fs, mesh[i]);
  
  //=x+a-x mod a =(x div a+1)*a;
  if fs.Position Mod 16 <> 0 then
    fs.Seek(16 * (Trunc(fs.Position / 16) + 1), SeekOrigin.Begin);
  
  // Writeln(fs.Position);
  for var i := 0 to mesh.Length - 1 do
  begin
    for var j := 0 to mesh[i].Verts - 1 do
    begin
      var v := new VerInfo();
      ReadVertexData(fs, v);
      mesh[i].Info.Add(v);
    end;
    var trins := new byte[mesh[i].Trins * 6];
    fs.Read(trins, 0, trins.Length);
    var j := 0;
    while j < trins.Length do
    begin
      mesh[i].Indexs.Add(BitConverter.ToUInt16(trins, j));
      j += 2;
    end;
  end;
  var mn:=Path.ChangeExtension(fn,'.MTL');
  
  
  ExportData(Path.ChangeExtension(fn,'.OBJ'),mn,mesh);
  ExportMaterial(mn,mats);
  
  Println(fn,fs.Length - fs.Position);
  br.Dispose();
  

end;

begin
var fls:=IO.Directory.GetFiles('./','*.smb');
for var i:=0 to fls.Length-1 do
Export(fls[i]);



end.