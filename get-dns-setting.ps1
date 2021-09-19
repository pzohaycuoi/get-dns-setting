# create a new file to contains the data
$dataFile = New-Item -Path $env:USERPROFILE -Name "serverDnsSeting-$(get-date -Format ddMMyyyy-hhmmss).csv" -Force

# get the domain name
$objDomain = New-Object System.DirectoryServices.DirectoryEntry

# searcher to search object in domain, set attribute in object
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.SearchScope = "Subtree" 
$objSearcher.PageSize = 1000 

# filter the computer object
$objSearcher.Filter = "(&(objectCategory=computer)(operatingsystem=*server*))"

$colResults = $objSearcher.FindAll()

# Loop through the result and get attribute inside each row
foreach ($row in $colResults) {
  $objComputer = $row.GetDirectoryEntry()
  $computer = New-Object PSObject -Property @{
    ComputerName    = $objComputer.Name[0]
    # DNSServer       = $networkAdapter.DNSServerSearchOrder
    OperatingSystem = $objComputer.operatingsystem[0]
  }
  # get network apdater configuration
  $networkAdapter = Get-WmiObject -Class Win32_NetworkAdapterConfiguration `
    -Property DNSServerSearchOrder -ComputerName $objComputer.Name -Filter "IPEnabled='True'"
  # get dns server
  $dnsServers = $networkAdapter.DNSServerSearchOrder
  # create new object and append into the computer object
  for ($i = 0; $i -lt $dnsServers.Count; $i++) {
    $keyName = "DNSServer$($i)"
    $computer | Add-Member NoteProperty $keyName $dnsServers[$i]
  }
  # output data to file and put some text on the console
  $computer | Export-Csv -Path ($dataFile).FullName -Force -Append -NoTypeInformation
  Write-Output $computer 
}