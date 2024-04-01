uses System,System.Io,System.Text;
const
  Comment_Len = 80;
  Author_len = 80;
  Copy_len = 80;


type
  POD3Directory = record
  public 
    path: string;
    
    offset: integer;
    length: integer;
    timestamp: cardinal;
    checksum: integer;
    
    constructor create(len, off, timest, chesum: integer);
    begin
      offset := off;
      length := len;
      timestamp := timest;
      checkSum := chesum;
      
    end;
  end;
  
  POD3Struct = record
  public 
    Header: string;
    CheckSum: integer;
    Comment: string;
    EntyCount: integer;
    AuditCount: integer;
    reversion: integer;
    prior: integer;
    Auther: string;
    Copyright: string;
    DirOffset: integer;
    Dirictoryes: array of POD3Directory;
  
  
  end;
  
  
  POD3Reader = class
    
    public class function Read(stream: System.IO.Stream): Pod3Struct;
    begin
      var res := new POD3Struct();
      var binr := new BinaryReader(stream);
      res.Header := new string(Encoding.ASCII.GetChars(binr.ReadBytes(4)));
      
      res.CheckSum := binr.ReadInt32();
      res.Comment := new string(Encoding.ASCII.GetChars(binr.ReadBytes(comment_len)));
      res.EntyCount := binr.ReadInt32();
      res.AuditCount := binr.ReadInt32();
      res.reversion := binr.ReadInt32();
      res.prior := binr.ReadInt32();
      res.Auther := new string(Encoding.ASCII.GetChars(binr.ReadBytes(author_len)));
      res.Copyright := new string(Encoding.ASCII.GetChars(binr.ReadBytes(copy_len)));
      res.DirOffset := binr.ReadInt32();
      
      stream.Seek(res.DirOffset, SeekOrigin.Begin);
      
      var lstoff: integer := -1;
      
      res.Dirictoryes := new POD3Directory[res.EntyCount];
      
      
      var pahthoff := new integer[res.EntyCount];
      
      for var i := 0 to res.Dirictoryes.Length - 1 do
      begin
        var off := binr.ReadInt32();
        pahthoff[i] := off;
        lstoff := off;
        res.Dirictoryes[i] := new Pod3Directory(binr.ReadInt32(), binr.ReadInt32(), binr.ReadUInt32(), binr.ReadInt32());       
      end;
      
      
      var chars := new list<byte>();
      
      for var i := 0 to res.EntyCount - 1 do
      begin
        for var j := 0 to 255 do
        begin
          var bt := binr.ReadByte();
          if bt = 0 then break;
          chars.Add(bt);
        end;
        res.Dirictoryes[i].path := Encoding.ASCII.GetString(chars.ToArray());
        chars.Clear();        
      end;
      result := res;
    end;
  
  
  end;
  
  POD3Exporter = class  
  public 
    class BufSize: integer := 4096;
    class procedure CreateFile(off, len: integer; ReadingStream, OutStream: stream);
    begin
      ReadingStream.Seek(off, seekorigin.Begin);
      var bts := new byte[BufSize];
      
      var curreaded := 0;
      while curreaded < len do
      begin
        var md := len - curreaded;
        var toread := BufSize;
        if md < bufsize then toread := md;        
        
        ReadingStream.Read(bts, 0, toread);
        OutStream.Write(bts, 0, toread);
        curreaded += toread;
      end;
    end;
    
    class function GetTime(seconds: cardinal): DateTime;
    begin
      //result:=UnixTime.AddSeconds(seconds);
      var unixtime:=new Datetime(1970, 1, 1);
      result :=unixtime.AddSeconds(seconds);
    end;
    
    class procedure CreateDirectoryes(StartDir: string; dirs: array of POD3Directory; Str: Stream);
    begin
      // if string.IsNullOrEmpty(StartDir) then startdir := nil; 
      for var i := 0 to dirs.Length - 1 do
      begin
        var p := startdir + System.IO.Path.GetDirectoryName(dirs[i].path);        
        Directory.CreateDirectory(p);
        
        var fl := new FileStream(startdir + dirs[i].path, FileMode.Create);
        CreateFile(dirs[i].offset, dirs[i].length, str, fl);
        fl.Flush();
        fl.Dispose();
           
           System.IO.File.SetCreationTime(fl.Name,GetTime(dirs[i].timestamp));
      end;
      
      
    end;
  
  
  
  end;

begin
    //var path := Path.GetFileName(fl) + System.IO.Path.DirectorySeparatorChar;
  
  
    //var str := new FileStream(fl, FileMode.Open);
  
    //var struct := POD3Reader.Read(str);
    //POD3Exporter.CreateDirectoryes(path, struct.Dirictoryes, str);
  //  writeln(POD3Exporter.UnixTime.AddSeconds(1094779636).Year);
    { var pod := new Pod3Reader(fl);
    var fls := pod.Read().Dirictoryes;
    var st := pod.FStream;
    st.Seek(0, SeekOrigin.Begin);
  
    var basedir:=Path.GetFileName(fl)+Path.DirectorySeparatorChar;
  
  
    for var i := 0 to fls.Length - 1 do
    begin
    //var p:=new System.IO.FileInfo(fls[i].path);
    var p := System.IO.Path.GetDirectoryName(fls[i].path);
    if not System.IO.Directory.Exists(p) then
    Directory.CreateDirectory(basedir+p);
    var nm := (fls[i].path);
    end;}
  
  var fls := System.IO.Directory.GetFiles('.\', '*.pod');
  for var i := 0 to fls.Length - 1 do
  begin
    var stream := new FileStream(fls[i], FileMode.Open);
    var res := Pod3Reader.Read(stream);
    Pod3Exporter.CreateDirectoryes(Path.GetFileNameWithoutExtension(fls[i]) + Path.DirectorySeparatorChar, res.Dirictoryes, stream);
    stream.Dispose();
  end;
  
  
end.