let
    Source =
        Csv.Document(
            Web.Contents(HttpSource & "Sales Order.csv"),
            [ Delimiter = ",", Columns = 4, Encoding = 65001, QuoteStyle = QuoteStyle.None ]
        ),
    #"Promoted Headers" =
        Table.PromoteHeaders( Source, [PromoteAllScalars = true] ),
    #"Changed Type" =
        Table.TransformColumnTypes(
            #"Promoted Headers",
            {
                { "SalesOrderLineKey", Int64.Type },
                { "Sales Order", type text },
                { "Sales Order Line", type text },
                { "Channel", type text }
            }
        ),
    #"🔑 Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"SalesOrderLineKey", "🔑 SalesOrderLineKey"}})
in
    #"🔑 Renamed Columns"