let
    Specification = [ 01_Object Name = "Product",
 	02_Type = "Table",
 	03_Link to Specification = "https://onedrive.live.com/view.aspx?resid=43FC8CA3B17868DD%21806&id=documents&wd=target%28VS%20Code.one%7C062DAB10-4A3E-4127-8D96-1AB4A4286FC7%2FDummyTask%3A%20Add%20Internet-Sales%7CC38A5B3B-DB39-4862-8800-09D041CB42B0%2F%29",
 	04_Developer = "Sergii_Razumov@epam.com",
 	05_Tasks = "JR-07",
 	06_Due Date = "08/30/2022 00:00:00",
 	07_Sprint = "3",
 	08_Status = "To Start",
 	09_Ready for pct = "",
 	10_Dev Comment  = "Waiting for specification",
 	11_PM Comment = "" ],
    Source =               Csv.Document(Web.Contents(HttpSource & "Product.csv"),[Delimiter=",", Columns=9, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",
        {
            {"ProductKey", Int64.Type}, 
            {"Product", type text}, 
            {"Standard Cost", Currency.Type}, 
            {"Color", type text}, 
            {"List Price", Currency.Type}, 
            {"Model", type text}, 
            {"Subcategory", type text}
        })
in
    #"Changed Type"
