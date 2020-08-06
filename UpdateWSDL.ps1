#replace this with path to BOS WSDL definitions:
$pathToFiles = 'C:\Users\luptondavis\Downloads\BOS definitions'

#regex to find types/elements without a fully qualified namespace (missing a ":")
$typeRegex = '((.*))(type="(((?!.*:).*)*))"'
$baseRegex = '((.*))(base="(((?!.*:).*)*))"'
$refRegex = '((.*))(ref="(((?!.*:).*)*))"'

#Loop through all files in definitions folder
Get-ChildItem $pathToFiles -Recurse  | Where-Object { -not $_.PSIsContainer } |
ForEach-Object {
    write-host "Looking in: $($_.FullName)"
    #Skip this powershell script
    if ($_.FullName.Contains("ps1")) {
        return
    }



    #Get the content of the document
    $text = (Get-Content $_.FullName -Raw)

    #replace schema
    if ($_.FullName.Contains("xsd")) {
        $XMLSchema = '<xs:schema xmlns:xdb="http://www.borland.com/schemas/delphi/10.0/XMLDataBinding" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tns="http://omniticket.network/ovw7" targetNamespace="http://omniticket.network/ovw7" elementFormDefault="qualified" attributeFormDefault="unqualified">'
        $text = [regex]::Replace($text, '<xs:schema.*', $XMLSchema);
    }

    #start replacing standard elements
    $text = $text -replace 'element="tns','type="tns'
    $text = $text -replace 'style="rpc"','style="document"'
    $text = $text -replace 'use="encoded"','use="literal"'

    #if a complex type does not contain "tns:" add it
    if ($text -match $typeRegex) {
        write-host "$($_.FullName) matches 'type' regex, replacing content"
        $text = [regex]::Replace($text, $typeRegex, '$1type="tns:$4"');
    }

    #if an extension does not contain "tns:" add it
    if ($text -match $baseRegex) {
        write-host "$($_.FullName) matches 'base' regex, replacing content"
        $text = [regex]::Replace($text, $baseRegex, '$1base="tns:$4"');
    }

    #if a reference does not contain "tns:" add it
    if ($text -match $refRegex) {
        write-host "$($_.FullName) matches 'ref' regex, replacing content"
        $text = [regex]::Replace($text, $refRegex, '$1ref="tns:$4"');
    }

    #write changes to disk or skip if no changes made.  inform user of both scenarios
    if ($text -ne (Get-Content $_.FullName -Raw)) {
        write-host -ForegroundColor Cyan  "$($_.FullName) updated.  Writing to disk"
        $text | Set-Content -path $_.FullName
    }
    else {
        write-host "$($_.FullName) no changes detected."
    }
}




