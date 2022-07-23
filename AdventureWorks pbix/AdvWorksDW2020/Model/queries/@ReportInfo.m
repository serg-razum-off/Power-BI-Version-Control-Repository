let
    Source = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("pY49C4NADIb/itxc1Lq4qrPQDwsdRCTU9Dy8GLmjFvvrm7ZLlw5SCOHhTXh461rN6LzhUW3UNoxlp1GcRkmcJMIynglbDzRZzJDA2PDC9Do1m1qdSqGcoMPgzPaqYdQrDUUuVGLHdz8sQx9U6LQxKyX7nVDVo7VLUOCoDawUdDij5QmdBEd43Ijn303eees+bxlOQN+qQ/6no3kC", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [Property = _t, Value = _t, StartDate = _t, EndDate = _t, Email = _t, Comment = _t]),
    #"Changed Type" = Table.TransformColumnTypes(Source,{{"StartDate", type date}}),
    #"Added Index" = Table.AddIndexColumn(#"Changed Type", "Index", 0, 1, Int64.Type)
in
    #"Added Index"