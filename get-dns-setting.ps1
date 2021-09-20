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

# Create form for object because "DNSServerSearchOrder" is an array 
# and may not exist in server dns setting which can affect the header of csv file
# Array to hold all of the object
$comInfoCollection = @()

# Loop through the result and get attribute inside each row
foreach ($row in $colResults) {
  $objComputer = $row.GetDirectoryEntry()
  # get network apdater configuration
  $networkAdapter = Get-WmiObject -Class Win32_NetworkAdapterConfiguration `
    -ComputerName $objComputer.Name -Filter "IPEnabled='True'"
  # object to hold computer info
  $computer = [PSCustomObject]@{
    ComputerName    = $objComputer.Name[0]
    OperatingSystem = $objComputer.operatingsystem[0]
    IPAddresses = $networkAdapter.IPAddress
    DnsServers = $networkAdapter.DNSServerSearchOrder
  }
  $comInfoCollection += $computer
}

# Array to hold count of Ips and dns servers
$arrCountIps = @()
$arrCountDnsServs = @()

# Loop through each object and append count into the array
foreach ($object in $comInfoCollection) {
  $countIp = $object.IPAddresses.Count
  $arrCountIps += [int]$countIp
  $countDnsServ = $object.dnsServers.Count
  $arrCountDnsServs += [int]$countDnsServ
}

# Get max value from array
$maxCountIp = [int]($arrCountIps | Measure -Maximum).Maximum
$maxCountDnsServ = [int]($arrCountDnsServs | Measure -Maximum).Maximum

# Loop through the result and get attribute inside each object
foreach ($computer in $comInfoCollection) {
  $objComputer = [PSCustomObject]@{
    ComputerName    = $computer.ComputerName
    OperatingSystem = $computer.OperatingSystem
  }
  # create new object and append IP into the computer object
  for ($i = 0; $i -lt $maxCountIp; $i++) {
    $keyName = "IPAddress$($i)"
    $objComputer | Add-Member NoteProperty $keyName $computer.IPAddresses[$i]
  }
  # create new object and append dns server into the computer object
  for ($i = 0; $i -lt $maxCountDnsServ; $i++) {
    $keyName = "DNSServer$($i)"
    $objComputer | Add-Member NoteProperty $keyName $computer.dnsServers[$i]
  }
  # output data to file and put some text on the console
  $objComputer | Export-Csv -Path $dataFile.FullName -Force -Append -NoTypeInformation
  Write-Output $objComputer 
}