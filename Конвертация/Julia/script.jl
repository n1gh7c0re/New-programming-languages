using CommonMark

function md_to_html(md_file, html_file)

    md_text = read(md_file, String)
    

    parser = Parser()
    
    try
        enable!(parser, CommonMark.AdmonitionRule())
        enable!(parser, CommonMark.AttributeRule())
        enable!(parser, CommonMark.AutoIdentifierRule())
        enable!(parser, CommonMark.CitationRule())
        enable!(parser, CommonMark.FootnoteRule())
        enable!(parser, CommonMark.FrontMatterRule())
        enable!(parser, CommonMark.MathRule())
        enable!(parser, CommonMark.RawContentRule())
        enable!(parser, CommonMark.TableRule())
        enable!(parser, CommonMark.TypographyRule())
    catch e
        println("Error: $e")
    end
    

    ast = parser(md_text)
    

    html_content = html(ast)
    

    full_html = """
    <!doctype html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Document</title>
        <style>
            body { 
                font-family: Arial, sans-serif; 
                line-height: 1.6; 
                margin: 40px;
                max-width: 800px;
            }
            h1 { color: #333; border-bottom: 2px solid #333; }
            h2 { color: #555; }
            code { 
                background: #f4f4f4; 
                padding: 2px 5px; 
                border-radius: 3px;
            }
            pre { 
                background: #f4f4f4; 
                padding: 15px; 
                overflow: auto;
                border-radius: 5px;
            }
            blockquote {
                border-left: 4px solid #ddd;
                margin-left: 0;
                padding-left: 20px;
                color: #666;
            }
        </style>
    </head>
    <body>
    $html_content
    </body>
    </html>
    """

    open(html_file, "w") do f
        write(f, full_html)
    end
end

md_to_html("input.md", "output.html")
println("Ready! Result in output.html")