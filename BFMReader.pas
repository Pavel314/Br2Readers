{$reference PresentationCore.dll}
//^todo integer->dword
//^todo не экспортировать материал если не используется
uses System, System.IO, System.Globalization, System.Windows.Media.Media3D;

type
  
  Point3D = class(IEquatable<Point3D>)
  public 
    X, Y, Z: single;
    constructor create(X_, Y_, Z_: single);
    begin
      X := X_;
      Y := Y_;
      Z := Z_;
    end;
    
    function Equals(p: Point3D): boolean;
    begin
      Result := (X = p.X) and (Y = p.Y) and (Z = p.Z); 
    end;
  
  private 
    _culture := CultureInfo.InvariantCulture;
  public 
    function ToString(): string; override;
    begin
      Result := string.Format('{0} {1} {2}', Convert.ToString(x, _culture), Convert.ToString(y, _culture), Convert.ToString(z, _culture));  
    end;
  end;
  
  Point2DI = class(IEquatable<Point2DI>)
  public 
    X, Y: Int16;
    constructor create(X_, Y_: Int16);
    begin
      X := X_;
      Y := Y_;
    end;
    
    function Equals(p: Point2DI): boolean;
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
  
  Point2D = class(IEquatable<Point2D>)
  public 
    X, Y: single;
    constructor create(X_, Y_: single);
    begin
      X := X_;
      Y := Y_;
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
  
  
  
  BoundBox = record
  public 
    Start, Endd: Point3D;
    constructor create(Start_, Endd_: Point3d);
    begin
      Start := Start_;
      Endd := Endd_;
    end;
  end;
  
  TwoPoint3D = record
  public 
    Start, Endd: Point3D;
    constructor create(Start_, Endd_: Point3d);
    begin
      Start := Start_;
      Endd := Endd_;
    end;
  end;
  
  TriangleInd = record
  public 
    A, B, C: UInt16;
    constructor create(a_, b_, c_: Uint16);
    begin
      A := a_;
      B := b_;
      C := c_;
    end;
  end;
  
  BFMHeader = record
  public 
    Unkown1: integer;
    Unkown2: integer;
    Skeleton: string;
    Unkown3: integer;
    Meshes: integer;
    BonesCount: Integer;
    Textures: integer;
    Attached: integer;
    Unkown4: integer;
  end;
  
  BFMPart = record
  public 
    Name: string;//30 byte
    BoneIndex: integer;
    Box: BoundBox;
  end;
  
  BFMAttachedPart = record
  public 
    Name: string;//24 byte
    BoneIndex: integer;
    Unkown1, Unkown2: BoundBox;
  end;
  
  BFMMaterial = record
  public 
    TextureName: string;
    BumpmapName: string;
    GlossmapName: string;
  end;
  
  BFMBones = record
  public 
    Offset: array of Point3D;
    Unkown: array of TwoPoint3D;
    BoneType: array of integer;
    ChildCount: array of integer;
  end;
  
  BFMMeshDesc = record
  public 
    Unkown1: integer;
    MaterialIndex: integer;
    Unkown2: integer;
    PartIndex: int32;
    Unkown3: Int32;
    Unkown4: int32;
    BytesCount: int32;
    Unkown5: int32;
    PointsCount: int32;
    TrianglesCount: int32;
    Unkown6: int32;
  end;
  
  BFMPoint = record
    SubpointsCount: integer;
    SubPoints: array of Point3D;
    Weight: array of single;
    NormalVector: Point3D;
    BoneIndex: array of integer;
    UV: Point2D;
    BinormalVector: Point3D;
    TangentVector: Point3D;
  end;
  
  
  BFMMesh = record
  public 
    Points: array of BFMPoint;
    Triangles: array of TriangleInd;
  end;
  
  SKBBone = record
    Name: string;//24;
    Unkown1: single;
    ParentBoneIndex: integer;
    SiblingBoneIndex: integer;
    LocalMatrix: array of single;
    GlobalTransform: Matrix3D;
  end;
  
  SKBHeader = record
    Unkown1: integer;
    BonesCount: integer;
  
  end;
  
  SKBFile = record
    Head: SKbHeader;
    Bones: array of SKBBone;
  end;
  
  BFMFile = record
  public 
    Head: BFMHeader;
    Parts: array of BFMPart;
    AttParts: array of BFMAttachedPart;
    Materials: array of BFMMaterial;
    Bones: BFMBones;
    MeshDesc: array of BFMMeshDesc;
    Meshes: array of BFMMesh;
    SFile: SKBFile;
  end;


function Stream.ReadTryString(ReservedLen: integer): string;
begin
  var arr := new byte[ReservedLen];
  self.Read(arr, 0, arr.Length);  
  for var i := 0 to arr.Length - 1 do
  begin
    if arr[i] = 0 then
      break;
    result += char(arr[i]); //Encoding !!!
  end;
end;

function BinaryReader.ReadTryString(ReservedLen: integer): string;
begin
  result := self.BaseStream.ReadTryString(ReservedLen);
end;

function BinaryReader.ReadPoint3D(): Point3D;
begin
  result := new Point3D(self.ReadSingle(), self.ReadSingle(), self.ReadSingle());
end;

function BinaryReader.ReadPoint2D(): Point2D;
begin
  result := new Point2D(self.ReadSingle(), self.ReadSingle());
end;

procedure ReadHeader(var BFile: BFMFile; br: BinaryReader);
begin
  BFile.Head := new BFMHeader();
  with bfile.Head do
  begin
    Unkown1 := br.ReadInt32();//All is 6
    Unkown2 := br.ReadInt32();//All is 1
    Meshes := br.ReadInt32();
    BonesCount := br.ReadInt32();
    Textures := br.ReadInt32();
    Attached := br.ReadInt32();
    Unkown3 := br.ReadInt32();//All is 3
    Unkown4 := br.ReadInt32();//All is 0
    Skeleton := br.ReadTryString(80);
  end;
end;

procedure ReadParts(var BFile: BFMFile; br: BinaryReader);
begin
  BFile.Parts := new BFMPart[BFile.Head.Meshes];
  for var i := 0 to BFile.Parts.Length - 1 do
  begin
    var item := new BFMPart();
    item.Name := br.ReadTryString(30);    
    item.BoneIndex := br.ReadInt32();
    item.Box := new BoundBox(br.ReadPoint3D(), br.ReadPoint3D());
    BFile.Parts[i] := item;
  end; 
  
end;

procedure ReadAttachedParts(var BFile: BFMFile; br: BinaryReader);
begin
  BFile.AttParts := new BFMAttachedPart[BFile.Head.Attached];
  for var i := 0 to BFile.AttParts.Length - 1 do
  begin
    var item := new BFMAttachedPart();
    item.Name := br.ReadTryString(24);
    item.BoneIndex := br.ReadInt32();
    item.Unkown1 := new BoundBox(br.ReadPoint3D(), br.ReadPoint3D());
    item.Unkown2 := new BoundBox(br.ReadPoint3D(), br.ReadPoint3D());
    BFile.AttParts[i] := item;
  end; 
end;


procedure ReadMaterials(var BFile: BFMFile; br: BinaryReader);
begin
  BFile.Materials := new BFMMaterial[BFile.Head.Textures];
  var bstream := br.BaseStream;
  for var i := 0 to BFile.Materials.Length - 1 do
  begin
    var item := new BFMMaterial();
    bstream.Seek(16, SeekOrigin.Current);
    item.TextureName := br.ReadTryString(72);
    item.BumpmapName := br.ReadTryString(72);
    item.GlossmapName := br.ReadTryString(72);
    bstream.Seek(128, SeekOrigin.Current);
    BFile.Materials[i] := item;
  end;
end;

procedure ReadBones(var BFile: BFMFile; br: BinaryReader);
begin
  var bones := new BFMBones();
  var len := Bfile.Head.BonesCount;
  bones.Offset := new Point3D[len];
  bones.Unkown := new TwoPoint3D[len];
  bones.BoneType := new integer[len];
  bones.ChildCount := new integer[len];
  for var i := 0 to len - 1 do
    bones.Offset[i] := br.ReadPoint3D();
  for var i := 0 to len - 1 do
    bones.Unkown[i] := new TwoPoint3D(br.ReadPoint3D(), br.ReadPoint3D());  
  for var i := 0 to len - 1 do
    bones.BoneType[i] := br.ReadInt32();
  for var i := 0 to len - 1 do
    bones.ChildCount[i] := br.ReadInt32();
  BFile.Bones := bones;
end;

procedure ReadMeshDesc(var BFile: BFMFile; br: BinaryReader);
begin
  BFile.MeshDesc := new BFMMeshDesc[br.ReadInt32()];
  for var i := 0 to BFile.MeshDesc.Length - 1 do
  begin
    var item := new BFMMeshDesc();
    
    item.Unkown1 := br.ReadInt32();// All is 3

    item.MaterialIndex := br.ReadInt32(); 
    if ( item.MaterialIndex=-842150451 ) then 
    begin
    if (BFile.Head.Meshes<>1) then 
    raise new Exception('Materail index is default(-842150451) but meshes count not 1');
    item.MaterialIndex:=0;
    end;
    
    item.Unkown2 := br.ReadInt32();
    item.PartIndex := br.ReadInt16();    
    br.ReadBytes((item.Unkown2 - 1) * 2); 
    
    item.Unkown3 := br.ReadInt32(); 
    br.ReadBytes(item.Unkown3 * 2);
    
    item.Unkown4 := br.ReadInt32();//All is 2
    item.BytesCount := br.ReadInt32();
    item.Unkown5 := br.ReadInt32();// All is 4
    item.PointsCount := br.ReadInt32();
    item.TrianglesCount := br.ReadInt32();
    item.Unkown6 := br.ReadInt32();
       //marker offset 12 in file
    //   if item.Unkown6 <> bfile.Head.Unkown3 then    raise new Exception('marker!!!' + item.Unkown6.ToString()+' '+br.BaseStream.Position);
    BFile.MeshDesc[i] := item;
    
  end;
  br.BaseStream.Seek((br.BaseStream.Position + 15) and not 15, SeekOrigin.Begin);
  //br.BaseStream.Seek(16 - (br.BaseStream.Position mod 16) + br.BaseStream.Position, SeekOrigin.Begin);
  // br.BaseStream.Seek(8, SeekOrigin.Current);//TODO!!! May be 4 bytes
end;


procedure ReadMeshes(var BFile: BFMFile; br: BinaryReader);
begin
  BFile.Meshes := new BFMMesh[BFile.Head.Meshes];
  //BFile.Meshes := new BFMMesh[BFile.MeshDesc.Length];
  for var i := 0 to BFile.Meshes.Length - 1 do
  begin
    var md := BFile.MeshDesc[i];
    var name: string;
    name := BFile.Parts[md.PartIndex].Name;    
    var bmesh := new BFMMesh();
    bmesh.Points := new BFMPoint[md.PointsCount];
    bmesh.Triangles := new TriangleInd[md.TrianglesCount];
    for var j := 0 to bmesh.Points.Length - 1 do
    begin
      var bpt := new BFMPoint();
      with bpt do
      begin
        SubpointsCount := br.ReadInt32();      
        if SubpointsCount > 0 then
        begin
          SubPoints := new Point3D[4](br.ReadPoint3D(), br.ReadPoint3D(), br.ReadPoint3D(), br.ReadPoint3D());
        end;      
        Weight := new single[4](br.ReadSingle(), br.ReadSingle(), br.ReadSingle(), br.ReadSingle());
        NormalVector := br.ReadPoint3D();
        BoneIndex := new integer[4](br.ReadInt32(), br.ReadInt32(), br.ReadInt32(), br.ReadInt32());
        UV := br.ReadPoint2D();
        BinormalVector := br.ReadPoint3D();
        TangentVector := br.ReadPoint3D();
      end;    
      bmesh.Points[j] := bpt;
    end;
    for var j := 0 to bmesh.Triangles.Length - 1 do
      bmesh.Triangles[j] := new TriangleInd(br.ReadUInt16, br.ReadUInt16, br.ReadUInt16); 
    BFile.Meshes[i] := bmesh;
  end;  
end;


//SKB
procedure ReadSKBHeader(var SFile: SKBFile; br: BinaryReader);
begin
  var head := new SKBHeader();
  head.Unkown1 := br.ReadInt32();//All is 12
  head.BonesCount := br.ReadInt32();
  SFile.Head := head;
end;

procedure ReadSKBBones(var SFile: SKBFile; br: BinaryReader);
begin
  var bone := new SKBBone[SFile.Head.BonesCount];
  for var i := 0 to bone.Length - 1 do
  begin
    bone[i].Name := br.ReadTryString(24);
    bone[i].Unkown1 := br.ReadSingle();
    bone[i].ParentBoneIndex := br.ReadInt32();
    bone[i].SiblingBoneIndex := br.ReadInt32();
    var matr := new single[9];
    for var j := 0 to matr.Length - 1 do
      matr[j] := br.ReadSingle();
    bone[i].LocalMatrix := matr;
  end;
  SFile.Bones := bone;
end;

function GenMatr(matrix: array of single; pos: Point3D): Matrix3D;
begin
   {result:=new Matrix3D(
     matrix[8],matrix[5],matrix[2],0,
     matrix[7],matrix[4],matrix[1],0,
     matrix[6],matrix[3],matrix[0],0,
     pos.X,pos.Y,pos.Z,1);}
    { result:=new Matrix3D(
     matrix[8],matrix[7],matrix[6],0,
     matrix[5],matrix[4],matrix[3],0,
     matrix[2],matrix[1],matrix[0],0,
     pos.X,pos.Y,pos.Z,1);}  
   {  result:=new Matrix3D(
     matrix[0],matrix[3],matrix[6],0,
     matrix[1],matrix[4],matrix[7],0,
     matrix[2],matrix[5],matrix[8],0,
     pos.X,pos.Y,pos.Z,1);}
    { result:=new Matrix3D(
     matrix[0],matrix[1],matrix[2],0,
     matrix[3],matrix[4],matrix[5],0,
     matrix[6],matrix[7],matrix[8],0,
     pos.X,pos.Y,pos.Z,1);}
  
     {result:=new Matrix3D(
     matrix[2],matrix[1],matrix[0],0,
     matrix[5],matrix[4],matrix[3],0,
     matrix[8],matrix[7],matrix[6],0,
     pos.X,pos.Y,pos.Z,1);}
     {result:=new Matrix3D(
     matrix[6],matrix[3],matrix[0],0,
     matrix[7],matrix[4],matrix[1],0,
     matrix[8],matrix[5],matrix[2],0,
     pos.X,pos.Y,pos.Z,1);}
  
     {result:=new Matrix3D(
     matrix[6],matrix[7],matrix[8],0,
     matrix[3],matrix[4],matrix[5],0,
     matrix[0],matrix[1],matrix[2],0,
     pos.X,pos.Y,pos.Z,1);}
     {result:=new Matrix3D(
     matrix[2],matrix[3],matrix[6],0,
     matrix[1],matrix[4],matrix[7],0,
     matrix[0],matrix[5],matrix[8],0,
     pos.X,pos.Y,pos.Z,1);}
  
  { var mat := new Matrix3D(
   matrix[6], matrix[7], matrix[8], 0,
   matrix[3], matrix[4], matrix[5], 0,
   matrix[0], matrix[1], matrix[2], 0,
   pos.X, pos.Y, pos.Z, 1);}
  
  
  result := new Matrix3D(
1, 0, 0, 0,
0, 1, 0, 0,
0, 0, 1, 0,
  pos.X, pos.Y, pos.Z, 1);
  
end;

function ReadSKBFile(path: string): SKBFile;
begin
  var br := new BinaryReader(new FileStream(path, FileMode.Open));
  var SFile := new SKBFile();
  ReadSKBHeader(SFile, br);
  ReadSKBBones(SFile, br);
  br.Dispose();
  result := SFile;
end;
//-842150451
function ImportBFM(path: string): BFMFile;
begin
  var fs := new FileStream(path, FileMode.Open);
  var br := new BinaryReader(fs);
  Result := new BFMFile();
  ReadHeader(Result, br);
  ReadParts(Result, br);
  ReadAttachedParts(Result, br);
  ReadMaterials(Result, br);
  ReadBones(Result, br);
  ReadMeshDesc(Result, br);
  ReadMeshes(Result, br);
  br.Dispose();
  
  var skbName := Result.Head.Skeleton;
  Result.SFile := ReadSKBFile(System.IO.Path.Combine(System.IO.Path.GetDirectoryName(path), skbName.Remove(skbName.Length - 1, 1) + 'b'));
  if (Result.Head.BonesCount <> Result.SFile.Head.BonesCount) then raise new Exception('inncorect bones count');
  
end;



var
  texts := new HashSet<string>();

procedure ExportMaterial(path: string; mats: array of BFMMaterial);
begin
  var writer := new StreamWriter(path, false, System.Text.Encoding.ASCII);
  
  for var i := 0 to mats.Length - 1  do  
  begin
    writer.WriteLine('newmtl {0}', i);
    
    if not string.IsNullOrEmpty(mats[i].TextureName) then 
    begin
      writer.WriteLine('map_Kd .\{0}', mats[i].TextureName);
      {var text := System.IO.Directory.GetFiles('D:\Games\BloodRayne 2\tests\_01_ReaderPOD3\', System.IO.PAth.ChangeExtension(mats[i].TextureName, '.TEX'), SearchOption.AllDirectories);
      if (texts.Add(text[0])) then
      begin
        System.IO.File.Copy(text[0], System.IO.Path.Combine('D:\Games\BloodRayne 2\tests\_04_ReaderBFM\All\texts\', System.IO.Path.GetFileName(text[0])));
      end;}
      
      
    end;
    
    if not string.IsNullOrEmpty(mats[i].BumpmapName) then 
    begin
      writer.WriteLine('map_Kb .\{0}', mats[i].BumpmapName);
     { var bump := System.IO.Directory.GetFiles('D:\Games\BloodRayne 2\tests\_01_ReaderPOD3\', System.IO.PAth.ChangeExtension(mats[i].BumpmapName, '.tex'), SearchOption.AllDirectories);
          if (texts.Add(bump[0])) then
      begin
        System.IO.File.Copy(bump[0], System.IO.Path.Combine('D:\Games\BloodRayne 2\tests\_04_ReaderBFM\All\texts\', System.IO.Path.GetFileName(bump[0])));
      end;}
    end;
    
    if not string.IsNullOrEmpty(mats[i].GlossmapName) then
    begin
      writer.WriteLine('map_Kg .\{0}', mats[i].GlossmapName);
      {var gloss := System.IO.Directory.GetFiles('D:\Games\BloodRayne 2\tests\_01_ReaderPOD3\', System.IO.PAth.ChangeExtension(mats[i].GlossmapName, '.tex'), SearchOption.AllDirectories);
              if (texts.Add(gloss[0])) then
      begin
        System.IO.File.Copy(gloss[0], System.IO.Path.Combine('D:\Games\BloodRayne 2\tests\_04_ReaderBFM\All\texts\', System.IO.Path.GetFileName(gloss[0])));
      end;}
    end;
  end;
  writer.Flush();
  writer.Dispose();
end;





procedure Export(pathIN, pathOUT: string);
begin
  var bfile := ImportBFM(pathIN);
  
  var writer := new StreamWriter(pathout, false, System.Text.Encoding.ASCII);
  
  
  var boneList := bfile.SFile.Bones;
  var poss := bfile.Bones.Offset;
  
  
  boneList[0].GlobalTransform := GenMatr(boneList[0].LocalMatrix, poss[0]);
  
  for var i := 1 to poss.Length - 1 do
  begin
    var bone := boneList[i];
    var prev := Matrix3D.Identity;
    if (bone.ParentBoneIndex <> -1) then
      prev := boneList[bone.ParentBoneIndex].GlobalTransform;  
    boneList[i].GlobalTransform := GenMatr(boneList[i].LocalMatrix, poss[i]) * prev;
  end;
  var mtlName := Path.ChangeExtension(Path.GetFileName(pathout), '.MTL');
  
  writer.WriteLine('mtllib {0}', mtlName);
  
  for var i := 0 to bfile.Meshes.Length - 1 do
  begin
    var mesh := bfile.Meshes[i];
    for var j := 0 to mesh.Points.Length - 1 do
    begin
      var pt := mesh.Points[j];
      
      var boneIndexs := pt.BoneIndex;
      var weight := pt.Weight;
      
      var vertex := new  System.Windows.Media.Media3D.Point3D(0, 0, 0);
      for var n := 0 to pt.SubpointsCount - 1  do
      begin
        var p := new  System.Windows.Media.Media3D.Point3D( pt.SubPoints[n].X, pt.SubPoints[n].Y, pt.SubPoints[n].Z);
        p := p * bonelist[boneIndexs[n]].GlobalTransform;
        vertex.Offset(p.X * weight[n], p.Y * weight[n], p.z * weight[n]);
      end;
      
      writer.WriteLine('v {0}', (new Point3D(vertex.X, vertex.y, vertex.z)));
      writer.WriteLine('vn {0}', pt.NormalVector);
      writer.WriteLine('vt {0}', pt.UV);
    end;    
  end;
  
  
  
  
  
  
  var lenoff := 1;
  for var i := 0 to bfile.Meshes.Length - 1 do
  begin
    var mesh := bfile.Meshes[i];
    var name := bfile.Parts[bfile.MeshDesc[i].PartIndex].Name;
    writer.Writeline('g {0}', name);
    writer.WriteLine(string.Format('usemtl {0}', bfile.MeshDesc[i].MaterialIndex));
    writer.WriteLine(string.Format('s {0}', 1));
    for var j := 0 to mesh.Triangles.Length - 1 do
    begin
      var trin := mesh.Triangles[j];
      writer.Writeline('f {0}/{0}/{0} {1}/{1}/{1} {2}/{2}/{2}', trin.A + lenoff, trin.B + lenoff, trin.C + lenoff);
      //  writer.Writeline('f {0}//{0} {1}//{1} {2}//{2}', trin.A + lenoff, trin.B + lenoff, trin.C + lenoff);
    end;
    lenoff += mesh.Points.Length;
  end;
  writer.Flush();
  writer.Dispose();
  
  
  ExportMaterial(mtlname, BFile.Materials);
  
  
end;


begin
  {var fls := System.IO.Directory.GetFiles('.\input\', '*.bfm');
  foreach var fl in fls do
  begin
    Export(fl, '.\output\' + Path.GetFileNameWithoutExtension(fl) + '.obj');
  end;}
  Export('D:\Games\BloodRayne 2\tests\_04_ReaderBFM\All\input\ADZII.BFM','D:\Games\BloodRayne 2\tests\_04_ReaderBFM\All\output\ADZII.obj');
end.
